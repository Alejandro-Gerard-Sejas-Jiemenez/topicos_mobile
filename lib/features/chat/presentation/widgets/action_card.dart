import 'dart:convert';
import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final Map<String, dynamic> action;

  const ActionCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black38,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.api, size: 18, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${action['method']} ${action['endpoint']}",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Colors.white10),
            _buildInfoRow("Módulo", action['module']),
            _buildInfoRow("Operación", action['operation']),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Data: ${jsonEncode(action['data'])}",
                style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(fontSize: 12, color: Colors.white54),
          children: [
            TextSpan(
              text: "$value",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
