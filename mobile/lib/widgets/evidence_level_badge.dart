import 'package:flutter/material.dart';
import '../models/evidence_level.dart';

/// Виджет отображения уровня доказательности
class EvidenceLevelBadge extends StatelessWidget {
  final EvidenceLevel level;

  const EvidenceLevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(level.colorValue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(level.colorValue), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForLevel(level),
            color: Color(level.colorValue),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            level.name,
            style: TextStyle(
              color: Color(level.colorValue),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLevel(EvidenceLevel level) {
    switch (level.code) {
      case 'HIGH':
        return Icons.star;
      case 'MEDIUM':
        return Icons.star_half;
      case 'LOW':
        return Icons.star_outline;
      default:
        return Icons.help_outline;
    }
  }
}
