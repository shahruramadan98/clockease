import 'package:flutter/material.dart';

class InsightTextCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const InsightTextCard({
    super.key,
    required this.title,
    required this.content,
    this.icon = Icons.lightbulb_outline,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: color.withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(icon, color: color),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     title,
                     style: const TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     content,
                     style: const TextStyle(
                       color: Colors.grey,
                       fontSize: 14,
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
}
