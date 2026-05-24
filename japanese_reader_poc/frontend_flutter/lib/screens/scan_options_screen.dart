import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_api_service.dart';
import '../widgets/scan_option_card.dart';
import 'image_crop_screen.dart';
import 'ocr_loading_screen.dart';
import 'reader_screen.dart';

class ScanOptionsScreen extends StatelessWidget {
  const ScanOptionsScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source, String mode) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 95);
    if (picked == null || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ImageCropScreen(imageFile: File(picked.path), mode: mode)));
  }

  Future<void> _pickPdf(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (picked == null || picked.files.single.path == null || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OCRLoadingScreen()));
    final result = await OCRApiService().processPdf(File(picked.files.single.path!));
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReaderScreen(result: result)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScanOptionCard(title: 'Take Photo', subtitle: 'Capture Japanese text now', icon: Icons.camera_alt_rounded, onTap: () => _pickImage(context, ImageSource.camera, 'auto')),
          ScanOptionCard(title: 'Choose Image', subtitle: 'Pick from your photo library', icon: Icons.photo_library_rounded, onTap: () => _pickImage(context, ImageSource.gallery, 'auto')),
          ScanOptionCard(title: 'Choose PDF', subtitle: 'Process a digital PDF document', icon: Icons.picture_as_pdf_rounded, onTap: () => _pickPdf(context)),
          ScanOptionCard(title: 'Scanned PDF', subtitle: 'For scanned pages and dense text', icon: Icons.document_scanner_rounded, onTap: () => _pickPdf(context)),
          ScanOptionCard(title: 'Sign / Menu', subtitle: 'Fast mode for short real-world text', icon: Icons.storefront_rounded, onTap: () => _pickImage(context, ImageSource.gallery, 'sign')),
        ],
      ),
    );
  }
}
