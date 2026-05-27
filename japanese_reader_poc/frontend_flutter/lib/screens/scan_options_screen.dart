import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_api_service.dart';
import '../services/project_storage_service.dart';
import '../services/recent_scan_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_routes.dart';
import '../widgets/scan_option_card.dart';
import 'image_crop_screen.dart';
import 'ocr_loading_screen.dart';
import 'reader_screen.dart';

class ScanOptionsScreen extends StatelessWidget {
  const ScanOptionsScreen({
    super.key,
    this.projectId,
    this.projectTitle,
    this.pageLabel,
  });

  final String? projectId;
  final String? projectTitle;
  final String? pageLabel;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  bool get _usesFilePickerForImages => kIsWeb || _isDesktop;

  Future<void> _pickImage(
      BuildContext context, ImageSource source, String mode) async {
    final imageFile = await _pickImageFile(context, source);
    if (imageFile == null || !context.mounted) return;

    Navigator.push(
      context,
      appRoute(
        ImageCropScreen(
          imageBytes: imageFile.bytes,
          filename: imageFile.filename,
          mode: mode,
          projectId: projectId,
          projectTitle: projectTitle,
          pageLabel: pageLabel,
        ),
      ),
    );
  }

  Future<_PickedImage?> _pickImageFile(
      BuildContext context, ImageSource source) async {
    if (_usesFilePickerForImages) {
      if (source == ImageSource.camera) {
        _showMessage(
            context,
            kIsWeb
                ? 'Camera capture is not available in web mode yet. Choose an image file instead.'
                : 'Camera capture is not available on desktop yet. Choose an image file instead.');
        return null;
      }

      final picked = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: kIsWeb);
      final file = picked?.files.single;
      if (file == null) return null;

      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) return null;
      return _PickedImage(bytes: bytes, filename: file.name);
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 95);
    if (picked == null) return null;
    return _PickedImage(
        bytes: await picked.readAsBytes(),
        filename: _fileName(picked.name.isEmpty ? picked.path : picked.name));
  }

  Future<void> _pickPdf(BuildContext context, {required String mode}) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    final file = picked?.files.single;
    if (file == null || !context.mounted) return;

    Navigator.push(context, appRoute(const OCRLoadingScreen()));
    try {
      final result = file.bytes != null
          ? await OCRApiService()
              .processPdfBytes(file.bytes!, filename: file.name, mode: mode)
          : await OCRApiService().processPdf(File(file.path!), mode: mode);

      await RecentScanStorageService().saveResult(
        result,
        title:
            file.name.isEmpty ? _fileName(file.path ?? 'PDF scan') : file.name,
        projectId: projectId,
        projectTitle: projectTitle,
        pageLabel: pageLabel,
      );
      if (projectId != null) {
        await ProjectStorageService().touchProject(projectId!);
      }
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
          context, appRoute(ReaderScreen(result: result)));
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showMessage(context, error.toString());
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? 'scan' : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final cameraSubtitle =
        _usesFilePickerForImages ? 'Mobile camera only' : 'Take Photo';

    return Scaffold(
      appBar: AppBar(title: const Text('スキャン方法を選択')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (projectTitle != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lilac),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${pageLabel ?? 'New page'} for $projectTitle',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '日本語のテキストをどこから読み取りますか？',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
            children: [
              ScanOptionCard(
                title: '今すぐ撮影',
                subtitle: cameraSubtitle,
                icon: Icons.camera_alt_rounded,
                onTap: () => _pickImage(context, ImageSource.camera, 'auto'),
              ),
              ScanOptionCard(
                title: '画像を選択',
                subtitle: 'Choose Image',
                icon: Icons.image_rounded,
                onTap: () => _pickImage(context, ImageSource.gallery, 'auto'),
              ),
              ScanOptionCard(
                title: 'PDFファイル',
                subtitle: 'PDF File',
                icon: Icons.picture_as_pdf_rounded,
                onTap: () => _pickPdf(context, mode: 'document'),
              ),
              ScanOptionCard(
                title: 'スキャンPDF',
                subtitle: 'Scanned PDF',
                icon: Icons.document_scanner_rounded,
                onTap: () => _pickPdf(context, mode: 'scanned'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ScanOptionCard(
            title: '看板・メニューなど',
            subtitle: 'Sign / Menu / Real World',
            icon: Icons.storefront_rounded,
            wide: true,
            onTap: () => _pickImage(context, ImageSource.gallery, 'sign'),
          ),
        ],
      ),
    );
  }
}

class _PickedImage {
  const _PickedImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
