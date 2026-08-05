import 'package:flutter/material.dart';

class ProgressWidget extends StatelessWidget {
  final bool isProcessing;
  final double progress;
  final String statusMessage;

  const ProgressWidget({
    super.key,
    required this.isProcessing,
    required this.progress,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          if (isProcessing)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              progress == 1.0 ? Icons.check_circle : Icons.info,
              color: progress == 1.0 ? Colors.green : Colors.blue,
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isProcessing ? Colors.blue : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}