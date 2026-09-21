import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../providers/movie_providers.dart';
import '../providers/reminder_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: CustomScrollView(
        slivers: [
          SliverSafeArea(
            top: true,
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branding Section
                    Center(
                      child: Column(
                        children: [
                          // App icon
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/images/appicon.png',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // App name
                          const Text(
                            'Cineby',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtitle
                          Text(
                            'AI RECOMMENDATION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Support & Legal Section
                    _buildSectionHeader('Support & Legal'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSettingRow(
                            icon: CupertinoIcons.share,
                            title: 'Share App',
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              // ignore: deprecated_member_use
                              Share.share(
                                'Check out Cineby: Movies & Series! https://apps.apple.com/app/id6811085988',
                              );
                            },
                          ),
                          _buildDivider(),

                          _buildSettingRow(
                            icon: CupertinoIcons.mail,
                            title: 'Contact Us',
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _launchUrl('mailto:zaykarda@yahoo.com');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Storage Section
                    _buildSectionHeader('Storage'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Consumer(
                        builder: (context, ref, child) {
                          return _buildSettingRow(
                            icon: CupertinoIcons.delete,
                            title: 'Clean Collection',
                            trailing: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _showCleanCollectionDialog(ref);
                              },
                              child: const Text(
                                'Clean',
                                style: TextStyle(
                                  color: AppTheme.neonRed,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // About Section
                    _buildSectionHeader('About'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSettingRow(
                            icon: CupertinoIcons.info_circle,
                            title: 'Version',
                            trailing: Text(
                              '1.0.0',
                              style: TextStyle(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingRow(
                            icon: CupertinoIcons.lock_shield,
                            title: 'Privacy Policy',
                            trailing: Icon(
                              CupertinoIcons.chevron_right,
                              color: CupertinoColors.white.withValues(
                                alpha: 0.5,
                              ),
                              size: 20,
                            ),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _launchUrl(
                                'https://cine24242.blogspot.com/2026/09/blog-post.html',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: CupertinoColors.white.withValues(alpha: 0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.neonRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: CupertinoColors.white.withValues(alpha: 0.1),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        // Show error if needed, or silently fail
        debugPrint('Could not launch $url');
      }
    }
  }

  void _showCleanCollectionDialog(WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clean Collection'),
        content: const Text(
          'Are you sure you want to remove all items from your collection? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              HapticFeedback.mediumImpact();
              // Clear Watchlist and Reminders
              ref.read(watchlistProvider.notifier).clearWatchlist();
              await ref.read(reminderProvider.notifier).clearReminders();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Clean'),
          ),
        ],
      ),
    );
  }
}
