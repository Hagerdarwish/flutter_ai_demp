import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Theme provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        children: [
          // Profile Card
          _buildProfileCard(context, user?.name ?? 'User', user?.email ?? ''),

          const Divider(height: 1),

          // Theme
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text(AppStrings.themeMode),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 16)),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 16)),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 16)),
              ],
              selected: {themeMode},
              onSelectionChanged: (modes) {
                ref.read(themeModeProvider.notifier).state = modes.first;
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text(AppStrings.aboutApp),
            subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall),
            onTap: () => _showAbout(context),
          ),

          const Divider(height: 1),

          // API info
          _buildApiInfoCard(context),

          const Divider(height: 1),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(AppStrings.logout,
                style: AppTextStyles.titleSmall(context).copyWith(color: AppColors.error)),
            onTap: () => _confirmLogout(context, ref),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: AppTextStyles.headlineSmall(context).copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.titleMedium(context).copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(email,
                    style: AppTextStyles.bodySmall(context).copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildApiInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(AppStrings.apiInfo,
                  style: AppTextStyles.titleSmall(context).copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(AppStrings.privacyNote,
              style: AppTextStyles.bodySmall(context)),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: '© 2025 MeetFlow AI\nPowered by Gemini & Firebase',
      children: [
        const SizedBox(height: 16),
        const Text(
          'MeetFlow AI converts your meeting recordings and transcripts into structured, actionable documentation using AI.',
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}
