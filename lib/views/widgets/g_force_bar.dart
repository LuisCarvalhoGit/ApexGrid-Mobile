import 'package:flutter/material.dart';

class GForceBar extends StatelessWidget {
  final double angle;
  final bool isLeft;
  final bool isExpanded;

  const GForceBar({
    super.key,
    required this.angle,
    required this.isLeft,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    const double maxLean = 50.0;
    final double percentage = (angle / maxLean).clamp(0.0, 1.0);

    return Container(
      height: isExpanded ? 10 : 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.amberAccent,
            boxShadow: [
              BoxShadow(color: Colors.amberAccent.withValues(alpha:0.3), blurRadius: 8)
            ],
          ),
        ),
      ),
    );
  }
}