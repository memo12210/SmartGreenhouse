import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onFix;

  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Tasarımdaki pembe/kırmızı gradyan
        gradient: LinearGradient(
          colors: [Colors.pink.withOpacity(0.2), Colors.red.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.pinkAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(message, 
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (onFix != null)
            TextButton(
              onPressed: onFix,
              child: const Text("FIX", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }
}