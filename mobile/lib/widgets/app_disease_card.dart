import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';
import '../models/models.dart';
import 'app_evidence_badge.dart';

/// Карточка заболевания
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
        child: Padding(
          padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      disease.name,
                      style: const TextStyle(
                        fontSize: AppDesignTokens.fontSizeH3,
                        fontWeight: AppDesignTokens.fontWeightBold,
                        color: AppDesignTokens.textPrimary,
                      ),
                    ),
                  ),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignTokens.spacingSM,
                        vertical: AppDesignTokens.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesignTokens.lightGreen,
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSM),
                      ),
                      child: Text(
                        '${score!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: AppDesignTokens.fontSizeCaption,
                          fontWeight: AppDesignTokens.fontWeightBold,
                          color: AppDesignTokens.success,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDesignTokens.spacingXS),
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
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusXL),
                      ),
                      child: Text(
                        symptom.name,
                        style: const TextStyle(
                          fontSize: AppDesignTokens.fontSizeCaption,
                          color: AppDesignTokens.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка метода лечения
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
        child: Padding(
          padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
              const SizedBox(height: AppDesignTokens.spacingXS),
              Text(
                remedy.shortDescription,
                style: const TextStyle(
                  fontSize: AppDesignTokens.fontSizeSmall,
                  color: AppDesignTokens.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDesignTokens.spacingSM),
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
