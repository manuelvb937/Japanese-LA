import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../services/ocr_api_service.dart';
import 'ocr_loading_screen.dart';
import 'reader_screen.dart';

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({super.key, required this.imageFile, required this.mode});
  final File imageFile;
  final String mode;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  late File _image;

  @override
  void initState() {
    super.initState();
    _image = widget.imageFile;
  }

  Future<void> _crop() async {
    final cropped = await ImageCropper().cropImage(sourcePath: _image.path);
    if (cropped != null) setState(() => _image = File(cropped.path));
  }

  Future<void> _runOcr() async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OCRLoadingScreen()));
    final result = await OCRApiService().processImage(_image, mode: widget.mode);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReaderScreen(result: result)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Image')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_image, fit: BoxFit.contain))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _crop, child: const Text('Crop / Resize'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: _runOcr, child: const Text('Run OCR'))),
          ])
        ]),
      ),
    );
  }
}
