<h2 align="center">🚗📸 - Aplicativo de Reconhecimento de Placas</h2>

  <p align="center">
    Sistema completo de <b>Reconhecimento Automático de Placas Veiculares (ANPR)</b><br/>
    <b>Flutter</b> + <b>FastAPI</b> + <b>YOLOv8</b> + <b>PaddleOCR</b>.
    <br />
    <br />
    <a href="https://github.com/FabinDr/Processamento_de_Imagem/releases/tag/v1.0.0"><strong>🔗 ACESSAR O APP</strong></a>
    <br />
  </p>
</div>

---

## ✅ Identificação do Trabalho 
> **Disciplina:** Processamento de Imagens<br />
> **Instituição:** Universidade Federal do Maranhão (UFMA)<br />
> **Docente:** Dr. HAROLDO GOMES BARROSO FILHO<br />

### 👤 Discentes
- **Dupla:**  
  - Fabio Duarte Ribeiro 
  - r
---

## Sobre o Projeto

<div align="justify">

Este projeto implementa uma solução completa de **Reconhecimento Automático de Placas** em imagens, com foco em **uso prático em celular**.

## Diagrama do Pipeline

<div align="center">
  <img src="docs/pipeline.png" width="250" alt="Pipeline ANPR"/>
</div>

---

### 🔎 Explicação do Fluxo (etapa por etapa)

1. **Flutter** captura/seleciona a imagem  
2. **HTTP Multipart POST /predict** envia imagem ao backend  
3. **FastAPI** recebe a imagem  
4. **Correção EXIF** corrige rotação do celular  
5. **YOLOv8** detecta a placa (bbox)  
6. **Crop + Padding** recorta a região da placa com margem  
7. **Pré-processamento** (Cinza + CLAHE) melhora contraste  
8. **PaddleOCR** realiza leitura do texto  
9. **Resposta JSON** retorna `plate` + `bbox_norm`  
10. **Flutter** exibe texto e bbox vermelha no app  
</div>

## 🧰 Tecnologias e Bibliotecas Utilizadas

### Backend (FastAPI)
- **Python 3.10+**
- **FastAPI** — criação da API REST
- **Uvicorn** — servidor ASGI
- **Ultralytics YOLOv8** — detecção da placa (bounding box)
- **PaddleOCR** — reconhecimento do texto (OCR)
- **OpenCV** — processamento de imagem
- **Pillow** — leitura da imagem e correção EXIF
- **python-dotenv** — variáveis de ambiente (.env)

### Frontend (Flutter)
- **Flutter / Dart**
- **image_picker** — câmera/galeria
- **http** — envio multipart para API
- **flutter_image_compress** — compressão para performance
- **CustomPaint** — desenho do retângulo (bbox)

---

## 📂 Estrutura do Repositório

```txt
Processamento_de_Imagem/
├── backend_api/        # API FastAPI + pipeline ANPR (YOLO + OCR)
├── flutter_app/        # App Flutter (envia imagem e exibe bbox)
├── notebooks/          # testes/treino/validações
└── docs/               # imagens e assets do README (pipeline.png, prints, etc.)
````
---
## 📸 Demonstração (prints)

<div align="center">
  <img src="docs/print_app.png" width="280" alt="Print do App"/>
</div>

---

# ✅ Instalação Local

<div align="justify">
Siga este guia passo a passo para configurar e rodar o projeto no seu computador.
Você pode rodar a API localmente e conectar o Flutter nela (recomendado para desenvolvimento).
</div>

---

## Pré-requisitos

Instale os seguintes itens:

* **Git**

  * [https://git-scm.com/downloads](https://git-scm.com/downloads)

* **Python 3.9+**

  * [https://www.python.org/downloads/](https://www.python.org/downloads/)

* **Flutter SDK**

  * [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

* **(Opcional) Docker**

  * [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

---

## Instalação

### ✅ 1º PASSO: Clonar o repositório

```bash
git clone https://github.com/FabinDr/Processamento_de_Imagem.git
cd Processamento_de_Imagem
```

---

## ✅ 2º PASSO: Rodar o BACKEND (FastAPI)

### 2.1 Acessar a pasta do backend

```bash
cd backend_api
```

### 2.2 Criar ambiente virtual

```bash
python -m venv .venv
```

### 2.3 Ativar o ambiente virtual

**Windows (PowerShell):**

```bash
.venv\Scripts\Activate.ps1
```

**Windows (CMD):**

```bash
.venv\Scripts\activate.bat
```

**Linux/Mac:**

```bash
source .venv/bin/activate
```

### 2.4 Instalar dependências

> Se existir `requirements.txt`:

```bash
pip install -r requirements.txt
```

> Caso não exista, instale manualmente os pacotes principais:

```bash
pip install fastapi uvicorn opencv-python ultralytics paddleocr numpy pillow
```

### 2.5 Executar a API

> O comando abaixo é o mais comum em projetos FastAPI:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

✅ API online em:

* `http://localhost:8000`

✅ Swagger automático:

* `http://localhost:8000/docs`

---

## ✅ 3º PASSO: Testar o endpoint sem Flutter (via CURL)

```bash
curl -X POST "http://localhost:8000/predict" \
  -H "accept: application/json" \
  -F "file=@./teste.jpg"
```

---

## ✅ 4º PASSO: Rodar o APP Flutter

### 4.1 Voltar para a pasta principal e entrar no app

```bash
cd ../flutter_app
```

### 4.2 Instalar dependências do Flutter

```bash
flutter pub get
```

### 4.3 Configurar a URL da API (IMPORTANTE)

✅ Se estiver usando backend local, configure a URL no código do Flutter:

* **Emulador Android:** `http://10.0.2.2:8000/predict`
* **Celular físico:** `http://SEU_IP:8000/predict`

> Procure no Flutter algo como:

```dart
const String apiUrl = "https://fabdrb-flutter-app.hf.space/predict";
```

E substitua pela sua URL local quando necessário.

### 4.4 Executar

```bash
flutter run
```

<p align="right">(<a href="#topo">voltar ao topo</a>)</p>

---

# ✅ Como Usar o Sistema

### Fluxo de uso (usuário final)

1. Abra o app Flutter
2. Clique em **Capturar** (câmera) ou **Selecionar** (galeria)
3. Aguarde o envio para a API e o processamento
4. O app exibirá:

   * ✅ texto final da placa (ex: `ABC1D23`)
   * ✅ bbox vermelha desenhada na imagem

---

# 📡 Contrato da API

## Endpoint: `POST /predict`

### ✅ Request

* Tipo: `multipart/form-data`
* Campo esperado: `file`

### ✅ Response (Exemplo)

```json
{
  "plate": "ABC1D23",
  "bbox_norm": [0.32, 0.41, 0.68, 0.56]
}
```

### 📌 Sobre `bbox_norm`

A bbox vem **normalizada** (0 até 1) no formato:

```txt
[x_min, y_min, x_max, y_max]
```

Isso facilita desenhar corretamente no Flutter em qualquer tamanho de tela.

<p align="right">(<a href="#topo">voltar ao topo</a>)</p>

---

# Dataset

O modelo foi treinado utilizando um dataset público do Kaggle:

🔗 [https://www.kaggle.com/datasets/barkataliarbab/license-plate-detection-dataset-10125-images](https://www.kaggle.com/datasets/barkataliarbab/license-plate-detection-dataset-10125-images)

