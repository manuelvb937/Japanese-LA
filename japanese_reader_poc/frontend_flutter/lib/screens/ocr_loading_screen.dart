import 'package:flutter/material.dart';

class OCRLoadingScreen extends StatelessWidget {
  const OCRLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Reading Japanese text...'),
        ]),
      ),
    );
  }
}
