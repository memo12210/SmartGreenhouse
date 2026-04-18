import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key});

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Alert: Water Tank Low", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Refill required soon to maintain optimal growth.", 
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("FIX", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}