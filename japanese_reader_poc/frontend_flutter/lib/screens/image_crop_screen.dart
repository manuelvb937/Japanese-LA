import 'dart:async';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../services/ocr_api_service.dart';
import '../services/project_storage_service.dart';
import '../services/recent_scan_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_primary_button.dart';
import '../widgets/app_routes.dart';
import '../widgets/soft_card.dart';
import 'ocr_loading_screen.dart';
import 'reader_screen.dart';

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.filename,
    required this.mode,
    this.projectId,
    this.projectTitle,
    this.pageLabel,
  });

  final Uint8List imageBytes;
  final String filename;
  final String mode;
  final String? projectId;
  final String? projectTitle;
  final String? pageLabel;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _cropController = CropController();
  late final Future<Uint8List> _imageBytesFuture;
  Completer<Uint8List>? _cropCompleter;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _imageBytesFuture = Future.value(widget.imageBytes);
  }

  Future<Uint8List?> _cropCurrentImage() async {
    if (_isCropping) return null;

    setState(() => _isCropping = true);
    final completer = Completer<Uint8List>();
    _cropCompleter = completer;
    _cropController.crop();

    try {
      return await completer.future.timeout(const Duration(seconds: 25));
    } catch (error) {
      if (mounted) _showMessage('Could not crop the image: $error');
      return null;
    } finally {
      _cropCompleter = null;
      if (mounted) setState(() => _isCropping = false);
    }
  }

  Future<void> _runOcr() async {
    final croppedBytes = await _cropCurrentImage();
    if (croppedBytes == null || !mounted) return;

    Navigator.push(context, appRoute(const OCRLoadingScreen()));
    try {
      final result = await OCRApiService().processImageBytes(
        croppedBytes,
        filename: widget.filename,
        mode: widget.mode,
      );
      await RecentScanStorageService().saveResult(
        result,
        title: widget.filename,
        projectId: widget.projectId,
        projectTitle: widget.projectTitle,
        pageLabel: widget.pageLabel,
      );
      if (widget.projectId != null) {
        await ProjectStorageService().touchProject(widget.projectId!);
      }
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
          context, appRoute(ReaderScreen(result: result)));
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage(error.toString());
    }
  }

  void _handleCropResult(CropResult result) {
    final completer = _cropCompleter;
    if (completer == null || completer.isCompleted) return;

    switch (result) {
      case CropSuccess(:final croppedImage):
        completer.complete(croppedImage);
      case CropFailure(:final cause):
        completer.completeError(cause);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('画像を調整')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            children: [
              Expanded(
                child: SoftCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: FutureBuilder<Uint8List>(
                      future: _imageBytesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return const Center(
                              child: Text('Could not load image.'));
                        }

                        return Crop(
                          controller: _cropController,
                          image: snapshot.data!,
                          onCropped: _handleCropResult,
                          interactive: true,
                          radius: 14,
                          baseColor: AppColors.ink,
                          maskColor: Colors.black.withValues(alpha: 0.42),
                          cornerDotBuilder: (size, edgeAlignment) =>
                              const DotControl(color: Colors.white),
                          progressIndicator: const CircularProgressIndicator(),
                          initialRectBuilder: InitialRectBuilder.withBuilder(
                            (viewportRect, imageRect) {
                              final horizontal = viewportRect.width * 0.08;
                              final vertical = viewportRect.height * 0.08;
                              return Rect.fromLTRB(
                                viewportRect.left + horizontal,
                                viewportRect.top + vertical,
                                viewportRect.right - horizontal,
                                viewportRect.bottom - vertical,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const _ToolChip(icon: Icons.crop_free_rounded, label: '範囲'),
                  const _ToolChip(icon: Icons.tune_rounded, label: '調整'),
                  _ToolChip(
                      icon: Icons.text_fields_rounded,
                      label: widget.mode == 'sign' ? '看板' : '文書'),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedPrimaryButton(
                onPressed: _isCropping ? null : _runOcr,
                icon: Icons.auto_awesome_rounded,
                label: _isCropping ? '処理中...' : 'OCRを実行',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
