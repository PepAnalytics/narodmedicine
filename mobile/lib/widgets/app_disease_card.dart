import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';
import '../models/models.dart';
import 'app_evidence_badge.dart';

/// Карточка заболевания v2 (с градиентом и иконкой растения)
class AppDiseaseCard extends StatelessWidget {
  final Disease disease;
  final double? score;
  final VoidCallback? onTap;

  const AppDiseaseCard({
    super.key,
    required this.disease,
    this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLG),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppDesignTokens.gradientCard,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLG),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDesignTokens.spacingMD + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Иконка растения
                    Container(
                      padding: const EdgeInsets.all(AppDesignTokens.spacingSM),
                      decoration: BoxDecoration(
                        color: AppDesignTokens.lightGreen.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSM),
                      ),
                      child: const Text(
                        '🌿',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: AppDesignTokens.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.name,
                            style: const TextStyle(
                              fontSize: AppDesignTokens.fontSizeH3,
                              fontWeight: AppDesignTokens.fontWeightBold,
                              color: AppDesignTokens.textPrimary,
                            ),
                          ),
                          if (score != null) ...[
                            const SizedBox(height: AppDesignTokens.spacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDesignTokens.spacingSM,
                                vertical: AppDesignTokens.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesignTokens.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSM),
                              ),
                              child: Text(
                                'Совпадение: ${score!.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: AppDesignTokens.fontSizeCaption,
                                  fontWeight: AppDesignTokens.fontWeightBold,
                                  color: AppDesignTokens.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.spacingSM),
                Text(
                  disease.description,
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeBody,
                    color: AppDesignTokens.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (disease.symptoms.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.spacingSM),
                  Wrap(
                    spacing: AppDesignTokens.spacingXS,
                    runSpacing: AppDesignTokens.spacingXS,
                    children: disease.symptoms.take(3).map((symptom) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignTokens.spacingSM,
                          vertical: AppDesignTokens.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignTokens.bgMuted,
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusXL),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_outlined,
                              size: AppDesignTokens.iconSizeSmall,
                              color: AppDesignTokens.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              symptom.name,
                              style: const TextStyle(
                                fontSize: AppDesignTokens.fontSizeCaption,
                                color: AppDesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка метода лечения v2
class AppRemedyCard extends StatelessWidget {
  final RemedyBrief remedy;
  final VoidCallback? onTap;

  const AppRemedyCard({
    super.key,
    required this.remedy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLG),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppDesignTokens.gradientCard,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLG),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDesignTokens.spacingMD + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Иконка растения
                    const Text(
                      '🌿',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: AppDesignTokens.spacingSM),
                    Expanded(
                      child: Text(
                        remedy.name,
                        style: const TextStyle(
                          fontSize: AppDesignTokens.fontSizeH3,
                          fontWeight: AppDesignTokens.fontWeightBold,
                          color: AppDesignTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDesignTokens.spacingSM),
                    AppEvidenceBadge(code: remedy.evidenceLevel.code),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.spacingSM),
                Text(
                  remedy.shortDescription,
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeBody,
                    color: AppDesignTokens.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDesignTokens.spacingMD),
                Row(
                  children: [
                    _buildStatIcon(
                      Icons.thumb_up_outlined,
                      remedy.likesCount.toString(),
                      AppDesignTokens.success,
                    ),
                    const SizedBox(width: AppDesignTokens.spacingLG),
                    _buildStatIcon(
                      Icons.thumb_down_outlined,
                      remedy.dislikesCount.toString(),
                      AppDesignTokens.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDesignTokens.iconSizeSmall,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDesignTokens.fontSizeCaption,
            fontWeight: AppDesignTokens.fontWeightMedium,
            color: color,
          ),
        ),
      ],
    );
  }
}
