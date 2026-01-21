import os
import re
from io import BytesIO
from typing import Optional, List, Tuple

import cv2
import numpy as np
from PIL import Image, ImageOps

from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from ultralytics import YOLO
from paddleocr import PaddleOCR

load_dotenv()

YOLO_MODEL_PATH = os.getenv("YOLO_MODEL_PATH", "plate.pt")
OCR_LANG = os.getenv("OCR_LANG", "en")
OCR_USE_ANGLE_CLS = os.getenv("OCR_USE_ANGLE_CLS", "true").lower() == "true"

# Regex Brasil:
# - Antiga: ABC1234
# - Mercosul: ABC1D23 (o 5º pode ser letra ou número dependendo do OCR)
BR_OLD = re.compile(r"^[A-Z]{3}[0-9]{4}$")
BR_MERCOSUL = re.compile(r"^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$")

app = FastAPI(title="ANPR - YOLO + PaddleOCR")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

yolo_model: Optional[YOLO] = None
ocr_engine: Optional[PaddleOCR] = None


@app.on_event("startup")
def startup():
    global yolo_model, ocr_engine

    # YOLO
    if not os.path.exists(YOLO_MODEL_PATH):
        print("📂 Arquivos na raiz:", os.listdir("."))
        raise RuntimeError(f"❌ Modelo YOLO não encontrado: {YOLO_MODEL_PATH}")

    yolo_model = YOLO(YOLO_MODEL_PATH)
    print(f"✅ YOLO carregado: {YOLO_MODEL_PATH}")

    # PaddleOCR
    ocr_engine = PaddleOCR(
        use_angle_cls=OCR_USE_ANGLE_CLS,
        lang=OCR_LANG,
        show_log=False,
    )
    print(f"✅ PaddleOCR carregado | lang={OCR_LANG} | angle_cls={OCR_USE_ANGLE_CLS}")


def _read_image_bytes(file_bytes: bytes) -> np.ndarray:
    """
    ✅ Lê imagem aplicando EXIF transpose (câmera do celular)
    Retorna em BGR (OpenCV).
    """
    pil = Image.open(BytesIO(file_bytes))
    pil = ImageOps.exif_transpose(pil)  # ✅ corrige rotação EXIF
    rgb = np.array(pil.convert("RGB"))
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    return bgr


def _pick_best_plate_bbox(yolo_result) -> Optional[Tuple[int, int, int, int, float]]:
    """
    Retorna bbox (x1,y1,x2,y2,conf) da melhor detecção.
    """
    if yolo_result is None or yolo_result.boxes is None:
        return None

    boxes = yolo_result.boxes
    if len(boxes) == 0:
        return None

    best = None
    best_score = -1.0

    for b in boxes:
        conf = float(b.conf.item()) if b.conf is not None else 0.0
        x1, y1, x2, y2 = b.xyxy[0].tolist()
        x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)

        area = max(0, x2 - x1) * max(0, y2 - y1)
        score = conf * (1.0 + area / 200000.0)  # conf + leve bônus por área

        if score > best_score:
            best_score = score
            best = (x1, y1, x2, y2, conf)

    return best


def _crop_with_padding(img_bgr: np.ndarray, bbox: List[int], pad: int = 10) -> np.ndarray:
    h, w = img_bgr.shape[:2]
    x1, y1, x2, y2 = bbox
    x1 = max(0, x1 - pad)
    y1 = max(0, y1 - pad)
    x2 = min(w, x2 + pad)
    y2 = min(h, y2 + pad)
    return img_bgr[y1:y2, x1:x2].copy()


def _preprocess_plate_for_ocr(plate_bgr: np.ndarray) -> np.ndarray:
    """
    Pré-processamento leve pra melhorar OCR de placa:
    - cinza
    - resize
    - contraste
    """
    gray = cv2.cvtColor(plate_bgr, cv2.COLOR_BGR2GRAY)

    # aumenta tamanho se estiver pequeno
    h, w = gray.shape[:2]
    if w < 300:
        scale = 2.0
        gray = cv2.resize(gray, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_CUBIC)

    # melhora contraste (CLAHE)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(gray)

    return gray


def _clean_plate_text(text: str) -> str:
    text = text.upper()
    text = re.sub(r"[^A-Z0-9]", "", text)
    return text


def _best_plate_candidate(candidates: List[Tuple[str, float]]) -> Tuple[str, float]:
    if not candidates:
        return "", 0.0

    valid = []
    for t, s in candidates:
        if BR_OLD.match(t) or BR_MERCOSUL.match(t):
            valid.append((t, s))

    if valid:
        valid.sort(key=lambda x: x[1], reverse=True)
        return valid[0]

    candidates.sort(key=lambda x: x[1], reverse=True)
    return candidates[0]


def _run_paddleocr(plate_img_gray: np.ndarray) -> Tuple[str, float]:
    if ocr_engine is None:
        return "", 0.0

    result = ocr_engine.ocr(plate_img_gray, cls=True)

    candidates = []
    try:
        for line in result:
            for item in line:
                txt = item[1][0]
                score = float(item[1][1])
                cleaned = _clean_plate_text(txt)
                if cleaned:
                    candidates.append((cleaned, score))
    except Exception:
        pass

    candidates_sorted = sorted(candidates, key=lambda x: x[1], reverse=True)

    merged = []
    if len(candidates_sorted) >= 2:
        t1, s1 = candidates_sorted[0]
        t2, s2 = candidates_sorted[1]
        merged.append((t1 + t2, min(s1, s2)))

    all_candidates = candidates_sorted + merged

    best_text, best_conf = _best_plate_candidate(all_candidates)
    return best_text, float(best_conf)


def _bbox_to_norm(bbox: List[int], w: int, h: int) -> List[float]:
    """
    ✅ Converte bbox pixel -> bbox normalizada (0..1)
    """
    x1, y1, x2, y2 = bbox
    return [
        x1 / w,
        y1 / h,
        x2 / w,
        y2 / h,
    ]


@app.get("/")
def root():
    return {"status": "ok", "message": "ANPR API online", "docs": "/docs"}


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Endpoint pro Flutter: envia 'file' multipart.
    Retorna bbox em pixels + bbox_norm (0..1)
    """
    if yolo_model is None:
        raise HTTPException(status_code=500, detail="YOLO não carregou.")
    if ocr_engine is None:
        raise HTTPException(status_code=500, detail="PaddleOCR não carregou.")

    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Arquivo vazio.")

    try:
        img_bgr = _read_image_bytes(file_bytes)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erro ao ler imagem: {e}")

    h, w = img_bgr.shape[:2]

    # YOLO detect
    yres = yolo_model.predict(img_bgr, conf=0.25, verbose=False)
    yres0 = yres[0] if len(yres) > 0 else None

    best = _pick_best_plate_bbox(yres0)
    if best is None:
        return {
            "plate": "",
            "confidence": 0.0,
            "plate_model_conf": 0.0,
            "bbox": None,
            "bbox_norm": None,
            "image_w": w,       
            "image_h": h,        
            "view_used": "paddleocr",
        }

    x1, y1, x2, y2, det_conf = best
    bbox = [int(x1), int(y1), int(x2), int(y2)]

    # ✅ bbox normalizada (0..1)
    bbox_norm = _bbox_to_norm(bbox, w=w, h=h)

    # Crop placa (só pra OCR)
    crop = _crop_with_padding(img_bgr, bbox, pad=12)

    # Preprocess OCR
    crop_gray = _preprocess_plate_for_ocr(crop)

    # OCR
    plate_text, ocr_conf = _run_paddleocr(crop_gray)

    return {
        "plate": plate_text,
        "confidence": float(ocr_conf),
        "plate_model_conf": float(det_conf),
        "bbox": bbox,
        "bbox_norm": bbox_norm,
        "image_w": w,            
        "image_h": h,           
        "view_used": "paddleocr",
    }
