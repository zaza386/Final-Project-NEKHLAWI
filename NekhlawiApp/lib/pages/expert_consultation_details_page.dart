import 'package:flutter/material.dart';

class ExpertConsultationDetailsPage extends StatelessWidget {
  final String title;

  const ExpertConsultationDetailsPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل استشارة الخبير')),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}