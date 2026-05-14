import 'package:flutter/material.dart';

class GForceBar extends StatelessWidget {
  final String label;
  final double value; // Valor em Gs (ex: -1.0 a 1.0)
  final double maxG;  // Limite visual do mostrador (ex: 1.5G)
  final Color positiveColor;
  final Color negativeColor;

  const GForceBar({
    super.key,
    required this.label,
    required this.value,
    this.maxG = 1.2,
    this.positiveColor = Colors.cyanAccent,
    this.negativeColor = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    // Normaliza o valor para uma percentagem (-1.0 a 1.0)
    final normalized = (value / maxG).clamp(-1.0, 1.0);
    final isPositive = normalized >= 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(2)} G', 
                 style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              // Linha do centro (Zero)
              Align(
                alignment: Alignment.center,
                child: Container(width: 2, color: Colors.white54),
              ),
              // A barra que enche
              LayoutBuilder(
                builder: (context, constraints) {
                  final halfWidth = constraints.maxWidth / 2;
                  final barWidth = halfWidth * normalized.abs();
                  return Positioned(
                    left: isPositive ? halfWidth : halfWidth - barWidth,
                    width: barWidth,
                    height: constraints.maxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPositive ? positiveColor : negativeColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: (isPositive ? positiveColor : negativeColor).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}