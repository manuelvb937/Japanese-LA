import 'package:flutter/material.dart';

class RecentScansScreen extends StatelessWidget {
  const RecentScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent scans')),
      body: const Center(child: Text('Recent scans coming soon.')),
    );
  }
}
