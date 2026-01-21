import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

const String API_URL = "https://fabdrb-flutter-app.hf.space/predict";

void main() {
  runApp(const PlateRecognitionApp());
}

class PlateRecognitionApp extends StatelessWidget {
  const PlateRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Reconhecimento de Placas",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1020), // azul bem escuro
      ),
      home: const HomePage(),
    );
  }
}

class PlateResult {
  final String plate;
  final List<double>? bboxNorm; // [x1n,y1n,x2n,y2n] 0..1

  PlateResult({required this.plate, required this.bboxNorm});

  factory PlateResult.fromJson(Map<String, dynamic> json) {
    List<double>? bn;
    final raw = json["bbox_norm"];
    if (raw is List && raw.length == 4) {
      bn = raw.map((e) => (e as num).toDouble()).toList();
    }

    return PlateResult(plate: (json["plate"] ?? "").toString(), bboxNorm: bn);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();

  File? _uploadImageFile; // imagem enviada pra API (e exibida)
  bool _loading = false;

  PlateResult? _result;

  // tamanho real da imagem exibida (para desenhar bbox certinho)
  int? _imgW;
  int? _imgH;

  Future<File?> _compressForUpload(File input) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.path}/plate_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final out = await FlutterImageCompress.compressAndGetFile(
      input.absolute.path,
      targetPath,
      format: CompressFormat.jpeg,
      quality: 75,
      minWidth: 1280,
      minHeight: 720,
    );

    return out == null ? null : File(out.path);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (picked == null) return;

    final rawFile = File(picked.path);

    // comprime pro upload
    final compressed = await _compressForUpload(rawFile);
    final uploadFile = compressed ?? rawFile;

    // pega tamanho da imagem que vai ser exibida (a mesma enviada)
    final decoded = await decodeImageFromList(await uploadFile.readAsBytes());

    setState(() {
      _uploadImageFile = uploadFile;
      _result = null;
      _imgW = decoded.width;
      _imgH = decoded.height;
    });
  }

  Future<void> _sendToApi() async {
    if (_uploadImageFile == null) return;

    setState(() => _loading = true);

    try {
      final uri = Uri.parse(API_URL);
      final request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath("file", _uploadImageFile!.path),
      );

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      // Debug opcional:
      // debugPrint(resp.body);

      if (resp.statusCode != 200) {
        throw Exception("API ${resp.statusCode}: ${resp.body}");
      }

      final jsonData = json.decode(resp.body) as Map<String, dynamic>;
      final plateResult = PlateResult.fromJson(jsonData);

      setState(() => _result = plateResult);

      if (plateResult.plate.trim().isEmpty) {
        _toast("Placa não detectada 😕");
      }

      if (plateResult.bboxNorm == null) {
        _toast("Sem bbox retornada (YOLO pode ter falhado)");
      }
    } catch (e) {
      _toast("Erro: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF102A6B),
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _uploadImageFile != null;

    final plateText = (_result?.plate ?? "").trim();
    final plateDisplay = plateText.isEmpty ? "---" : plateText;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A6B).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blue.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Reconhecimento de Placas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        _loading ? "Processando..." : "Pronto",
                        style: TextStyle(
                          color: _loading
                              ? Colors.orangeAccent
                              : Colors.lightBlueAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E4ED8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _loading
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text(
                          "Câmera",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _loading
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text(
                          "Galeria",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Detect button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: (!hasImage || _loading) ? null : _sendToApi,
                  child: _loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Reconhecendo...",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        )
                      : const Text(
                          "Reconhecer Placa",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Preview + bbox vermelha
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A6B).withOpacity(0.35),
                    border: Border.all(color: Colors.blue.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    _uploadImageFile!,
                                    fit: BoxFit.contain,
                                  ),

                                  // ✅ retângulo vermelho (bbox_norm)
                                  if (_result?.bboxNorm != null &&
                                      _imgW != null &&
                                      _imgH != null)
                                    CustomPaint(
                                      painter: BBoxPainter(
                                        bboxNorm: _result!.bboxNorm!,
                                        imageW: _imgW!,
                                        imageH: _imgH!,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Text(
                            "Selecione uma imagem pra começar",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Resultado (só placa)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blue.withOpacity(0.25)),
                  color: const Color(0xFF102A6B).withOpacity(0.55),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.lightBlueAccent.withOpacity(0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.badge,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Placa detectada",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            plateDisplay,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BBoxPainter extends CustomPainter {
  final List<double> bboxNorm; // [x1n,y1n,x2n,y2n]
  final int imageW;
  final int imageH;

  BBoxPainter({
    required this.bboxNorm,
    required this.imageW,
    required this.imageH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors
          .redAccent // ✅ vermelho
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    final imgW = imageW.toDouble();
    final imgH = imageH.toDouble();

    final x1 = bboxNorm[0] * imgW;
    final y1 = bboxNorm[1] * imgH;
    final x2 = bboxNorm[2] * imgW;
    final y2 = bboxNorm[3] * imgH;

    final scaleX = size.width / imgW;
    final scaleY = size.height / imgH;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final scaledW = imgW * scale;
    final scaledH = imgH * scale;

    final dx = (size.width - scaledW) / 2;
    final dy = (size.height - scaledH) / 2;

    final rect = Rect.fromLTRB(
      dx + x1 * scale,
      dy + y1 * scale,
      dx + x2 * scale,
      dy + y2 * scale,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
