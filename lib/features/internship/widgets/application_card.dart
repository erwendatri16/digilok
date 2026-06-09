import 'package:flutter/material.dart';

class ApplicationCard extends StatelessWidget {
  final dynamic application;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading:
            const Icon(Icons.school),

        title: Text(
          application.namaLengkap ??
              '-',
        ),

        subtitle: Text(
          application.asalKampus ??
              '-',
        ),
      ),
    );
  }
}