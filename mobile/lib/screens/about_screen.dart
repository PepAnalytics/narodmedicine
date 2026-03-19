import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';

/// Экран "О приложении"
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  String _buildNumber = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _version = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Заголовок с градиентом
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppDesignTokens.primaryGreen,
                      AppDesignTokens.secondaryGreen,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco, size: 64, color: Colors.white),
                      const SizedBox(height: AppDesignTokens.spacingSM),
                      const Text(
                        'Народная Медицина',
                        style: TextStyle(
                          fontSize: AppDesignTokens.fontSizeH2,
                          fontWeight: AppDesignTokens.fontWeightBold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Контент
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Предупреждение
                  const AppWarningBlock(
                    title: 'Важное предупреждение',
                    message:
                        'Данное приложение не ставит диагноз и не заменяет консультацию врача. Все материалы носят ознакомительный характер.',
                  ),
                  const SizedBox(height: AppDesignTokens.spacingLG),

                  // О приложении
                  _buildSection(
                    icon: Icons.info_outline,
                    title: 'О приложении',
                    children: [
                      const Text(
                        'Приложение «Народная Медицина» — это справочник народных методов лечения с научной оценкой их эффективности.',
                        style: TextStyle(
                          fontSize: AppDesignTokens.fontSizeBody,
                          color: AppDesignTokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingSM),
                      const Text(
                        'Мы собираем и систематизируем народные рецепты, указывая уровень их доказательности на основе доступных исследований и экспертных оценок.',
                        style: TextStyle(
                          fontSize: AppDesignTokens.fontSizeBody,
                          color: AppDesignTokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMD),
                      Row(
                        children: [
                          const Icon(
                            Icons.tag,
                            size: AppDesignTokens.iconSizeSmall,
                            color: AppDesignTokens.textMuted,
                          ),
                          const SizedBox(width: AppDesignTokens.spacingSM),
                          Text(
                            'Версия: $_version ($_buildNumber)',
                            style: const TextStyle(
                              fontSize: AppDesignTokens.fontSizeSmall,
                              color: AppDesignTokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMD),

                  // Возможности
                  _buildSection(
                    icon: Icons.featured_play_list,
                    title: 'Возможности',
                    children: [
                      _buildFeatureItem(Icons.search, 'Поиск по симптомам'),
                      _buildFeatureItem(
                        Icons.local_fire_department,
                        'Список заболеваний',
                      ),
                      _buildFeatureItem(
                        Icons.healing,
                        'Народные методы лечения',
                      ),
                      _buildFeatureItem(
                        Icons.star_rate,
                        'Уровень доказательности',
                      ),
                      _buildFeatureItem(
                        Icons.public_outlined,
                        'Региональные методы',
                      ),
                      _buildFeatureItem(Icons.volume_up, 'Озвучка рецептов'),
                      _buildFeatureItem(Icons.thumb_up, 'Оценка методов'),
                      _buildFeatureItem(Icons.favorite, 'Избранное'),
                      _buildFeatureItem(Icons.history, 'История просмотров'),
                      _buildFeatureItem(Icons.wifi_off, 'Офлайн-режим'),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMD),

                  // Контакты
                  _buildSection(
                    icon: Icons.email_outlined,
                    title: 'Контакты',
                    children: [
                      const Text(
                        'По вопросам и предложениям обращайтесь:',
                        style: TextStyle(
                          fontSize: AppDesignTokens.fontSizeBody,
                          color: AppDesignTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingSM),
                      InkWell(
                        onTap: () {
                          // TODO: Launch email
                        },
                        child: const Text(
                          'support@narodmedicine.com',
                          style: TextStyle(
                            fontSize: AppDesignTokens.fontSizeBody,
                            color: AppDesignTokens.primaryGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMD),
                      Row(
                        children: [
                          const Icon(
                            Icons.code,
                            size: AppDesignTokens.iconSizeSmall,
                            color: AppDesignTokens.primaryGreen,
                          ),
                          const SizedBox(width: AppDesignTokens.spacingSM),
                          const Text(
                            'GitHub: PepAnalytics/narodmedicine',
                            style: TextStyle(
                              fontSize: AppDesignTokens.fontSizeSmall,
                              color: AppDesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMD),

                  // Юридическая информация
                  _buildSection(
                    icon: Icons.gavel,
                    title: 'Юридическая информация',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.description, size: 20),
                        title: const Text('Пользовательское соглашение'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/terms');
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip, size: 20),
                        title: const Text('Политика конфиденциальности'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/privacy');
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXL),

                  // Копирайт
                  Center(
                    child: Text(
                      '© 2026 Народная Медицина',
                      style: const TextStyle(
                        fontSize: AppDesignTokens.fontSizeCaption,
                        color: AppDesignTokens.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppDesignTokens.primaryGreen,
                  size: AppDesignTokens.iconSizeMedium,
                ),
                const SizedBox(width: AppDesignTokens.spacingSM),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeH3,
                    fontWeight: AppDesignTokens.fontWeightBold,
                    color: AppDesignTokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingMD),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppDesignTokens.iconSizeSmall,
            color: AppDesignTokens.primaryGreen,
          ),
          const SizedBox(width: AppDesignTokens.spacingSM),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppDesignTokens.fontSizeBody,
                color: AppDesignTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
