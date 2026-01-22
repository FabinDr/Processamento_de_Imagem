<a id="topo"></a>

<div>
  <h1>Aplicativo de Reconhecimento de Placas</h1>

  <p>
    Sistema completo de <b>Reconhecimento Automático de Placas Veiculares</b><br/>
    <b>Flutter</b> + <b>FastAPI</b> + <b>YOLOv8</b> + <b>PaddleOCR</b>.
  <br />
    <h3>- Instalação do Aplicativo</h3>
    <a href="https://github.com/FabinDr/Processamento_de_Imagem/releases/tag/v1.0.0"><strong>🔗 ACESSAR O APP</strong></a>
  </p>

</div>

---

## Identificação do Trabalho

> **Disciplina:** Processamento de Imagens<br />
> **Instituição:** Universidade Federal do Maranhão (UFMA)<br />
> **Docente:** Dr. HAROLDO GOMES BARROSO FILHO<br />

### 👤 Discentes
- **Dupla:**  
  - Fabio Duarte Ribeiro  
  - Eliaquim Santos 

---

## 📌 Sumário

- [📖 Sobre o Projeto](#sobre-o-projeto)
- [🧰 Tecnologias e Bibliotecas Utilizadas](#tecnologias)
- [📂 Estrutura do Repositório](#estrutura)
- [🔄 Diagrama do Funcionamento](#diagrama)
- [📸 Demonstração](#demonstracao)
- [✅ Instalação e Execução (Recomendado)](#instalacao)
  - [⚡ Método Único — Flutter + API Hugging Face](#metodo-1)
  - [📦 Baixar APK (sem rodar no PC)](#apk)
- [📱 Como Usar o App](#como-usar)
- [📚 Dataset](#dataset)

---

<a id="sobre-o-projeto"></a>
## 📖 Sobre o Projeto

<div align="justify">

Este projeto implementa uma solução completa de **Reconhecimento Automático de Placas** em imagens, com foco em **uso prático em celular**.  
O sistema é capaz de:

- detectar a placa na imagem (**YOLOv8**)  
- recortar a região correta com margem (**crop + padding**)  
- tratar problemas comuns de imagens de celular (**correção EXIF**)  
- melhorar contraste para OCR (**pré-processamento OpenCV / CLAHE**)  
- extrair o texto final da placa (**PaddleOCR**)  
- retornar JSON padronizado para o app desenhar a bbox (**bbox_norm**)
</div>

---

<a id="tecnologias"></a>

## 🧰 Tecnologias e Bibliotecas Utilizadas

### Backend (FastAPI)
- **Python 3.10+**
- **FastAPI** — criação da API REST
- **Uvicorn** — servidor ASGI
- **Ultralytics YOLOv8** — detecção da placa (bounding box)
- **PaddleOCR** — reconhecimento do texto (OCR)
- **OpenCV** — processamento de imagem (pré-processamento)
- **Pillow** — leitura da imagem e correção EXIF
- **python-dotenv** — variáveis de ambiente (.env)

### Frontend (Flutter)
- **Flutter / Dart**
- **image_picker** — câmera/galeria
- **http** — envio multipart para API
- **flutter_image_compress** — compressão para performance
- **CustomPaint** — desenho do retângulo (bbox)

---

<a id="estrutura"></a>

## 📂 Estrutura do Repositório

```txt
Processamento_de_Imagem/
├── backend_api/        # API FastAPI + pipeline (YOLO + OCR)
├── flutter_app/        # App Flutter (envia imagem e exibe bbox)
├── notebooks/          # testes/treino/validações
└── docs/               # imagens e assets do README (pipeline.png, prints, etc.)
````

---

<a id="diagrama"></a>

## Diagrama do Funcionamento do Projeto

<div align="center">
  <img src="docs/pipeline.png" width="220" alt="Pipeline"/>
</div>

---

### 🔎 Explicação do Fluxo (etapa por etapa)

1. **Flutter** captura/seleciona a imagem
2. **HTTP Multipart POST /predict** envia imagem ao backend
3. **FastAPI** recebe a imagem
4. **Correção EXIF** corrige rotação do celular (fotos rotacionadas)
5. **YOLOv8** detecta a placa (bbox)
6. **Crop + Padding** recorta a região da placa com margem extra
7. **Pré-processamento** (Cinza + CLAHE) melhora contraste
8. **PaddleOCR** realiza leitura do texto
9. **Resposta JSON** retorna `plate` + `bbox_norm`
10. **Flutter** exibe texto e bbox vermelha no app

---

<a id="demonstracao"></a>

## 📸 Demonstração (prints)

<div align="center">
  <img src="docs/print_app.png" width="100%" alt="Print do App"/>
</div>

---
<a id="instalacao"></a>

# ✅ Instalação e Execução

Este é o jeito mais rápido e prático de testar o projeto  
Você vai rodar **somente o App Flutter no celular**, consumindo a **API pronta no Hugging Face** (já configurada por nós).


---

<a id="metodo-1"></a>

# ⚡ Método Único — Flutter + API Hugging Face

## 🌐 API utilizada (Hugging Face)

Endpoint oficial (POST):

🔗 **https://fabdrb-flutter-app.hf.space/predict**

Repositório do Space:

🔗 https://huggingface.co/spaces/fabdRb/anpr_app/tree/main

> ℹ️ Observação: como a API está hospedada em Space, a **primeira requisição pode demorar alguns segundos** (cold start).

---

## O que você vai precisar

### Obrigatório
- **Git**
- **Flutter SDK**
- **Celular Android**
- **Cabo USB com transferência de dados** (não apenas carregamento)

### Opcional (recomendado para programar melhor)
- **VS Code** (Editor)
- Extensões:
  - **Flutter**
  - **Dart**

---

## 🔧 Pré-requisitos (instalar uma única vez)

### 1) Instalar o Git
🔗 https://git-scm.com/downloads

---

### 2) Instalar o Flutter SDK
🔗 https://docs.flutter.dev/get-started/install

Depois de instalar, confirme no terminal:

```bash
flutter --version
````

E rode:

```bash
flutter doctor
```

O ideal é aparecer **Android toolchain OK** (mesmo que falte algo do iOS, isso é normal no Windows).

---

## Passo a passo (rodar no celular)

### 1) Clonar o repositório

```bash
git clone https://github.com/FabinDr/Processamento_de_Imagem.git
cd Processamento_de_Imagem
```

---

### 2) Entrar na pasta do Flutter

```bash
cd flutter_app
```

---

### 3) Baixar dependências do Flutter

```bash
flutter pub get
```

---

### 4) Confirmar URL da API no App

Arquivo:

📌 `flutter_app/anpr_flutter/lib/main.dart`

Verifique se está assim:

```dart
const String apiUrl = "https://fabdrb-flutter-app.hf.space/predict";
```

Se estiver igual acima, **não precisa alterar nada**.

---

## 📱 Conectar o celular antes de rodar (IMPORTANTE)

### No celular (ativar modo desenvolvedor)

1. Vá em **Configurações → Sobre o telefone**
2. Toque **7 vezes** em **Número da versão**
3. Volte e abra **Opções do desenvolvedor**
4. Ative **Depuração USB**
5. Conecte o celular no PC via USB
6. Aceite o pop-up **“Permitir depuração USB”**

---

## Verificar se o celular foi reconhecido no PC

Antes de rodar o app, execute:

```bash
flutter devices
```

Se aparecer algo como:

```
SM-A... • android • Android 13
```

Então está pronto!!

---

## ▶️ Rodar o App no celular

Com o celular conectado:

```bash
flutter run
```

 O Flutter irá:

* detectar o celular
* instalar o app automaticamente
* abrir o aplicativo

---

<a id="apk"></a>

# 📦 Baixar APK (sem rodar no PC)

Se você só quiser baixar e instalar o aplicativo direto:

🔗 **Link oficial do APK (Releases):**
[https://github.com/FabinDr/Processamento_de_Imagem/releases/tag/v1.0.0](https://github.com/FabinDr/Processamento_de_Imagem/releases/tag/v1.0.0)

Baixe o `.apk` e instale no Android.

> ⚠️ Talvez o Android peça permissão de “Instalar apps desconhecidos”.
> É normal, basta permitir.

---

<a id="como-usar"></a>

# 📱 Como Usar o App

Após rodar o aplicativo no celular:

### Passo a passo do usuário

1. Abra o app
2. Escolha uma opção:

   * 📸 **Capturar imagem**
   * 🖼️ **Selecionar da galeria**
3. Aguarde o processamento
4. Veja na tela:
   - texto da placa detectada
   - retângulo vermelho (bbox) desenhado na placa

---

<a id="dataset"></a>

# 📚 Dataset

Dataset utilizado para treino:
🔗 [https://www.kaggle.com/datasets/barkataliarbab/license-plate-detection-dataset-10125-images](https://www.kaggle.com/datasets/barkataliarbab/license-plate-detection-dataset-10125-images)

---

- [🔝 Voltar ao topo](#topo)
