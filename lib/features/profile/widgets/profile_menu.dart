import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileMenu extends StatelessWidget {
  final VoidCallback onLogout;
  final Function(BuildContext, String) onComingSoon;

  const ProfileMenu({
    super.key,
    required this.onLogout,
    required this.onComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      ProfileMenuItem(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Gérer vos notifications',
        onTap: () => onComingSoon(context, 'Notifications'),
      ),
      ProfileMenuItem(
        icon: Icons.security_outlined,
        title: 'Sécurité',
        subtitle: 'Mot de passe et authentification',
        onTap: () => onComingSoon(context, 'Sécurité'),
      ),
      ProfileMenuItem(
        icon: Icons.language_outlined,
        title: 'Langue',
        subtitle: 'Français',
        onTap: () => onComingSoon(context, 'Langue'),
      ),
      ProfileMenuItem(
        icon: Icons.dark_mode_outlined,
        title: 'Thème',
        subtitle: 'Clair',
        onTap: () => onComingSoon(context, 'Thème'),
      ),
      ProfileMenuItem(
        icon: Icons.help_outline,
        title: 'Aide & Support',
        subtitle: 'FAQ et assistance',
        onTap: () => onComingSoon(context, 'Aide & Support'),
      ),
      ProfileMenuItem(
        icon: Icons.info_outline,
        title: 'À propos',
        subtitle: 'Version de l\'application',
        onTap: () => _showAboutDialog(context),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Menu items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: menuItems.length,
            separatorBuilder: (context, index) => Divider(
              color: AppColors.gray200,
              height: 1,
              indent: 60,
            ),
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.gray400,
                ),
                onTap: item.onTap,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              );
            },
          ),
          
          // Divider
          Divider(
            color: AppColors.gray200,
            height: 1,
          ),
          
          // Logout button
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
                color: AppColors.error,
                size: 20,
              ),
            ),
            title: Text(
              'Déconnexion',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Se déconnecter de l\'application',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            onTap: onLogout,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Agil Distribution Tunisia',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.local_gas_station,
          color: AppColors.secondary,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'Application de gestion pour les stations-service Agil en Tunisie.',
        ),
        const SizedBox(height: 16),
        Text(
          '© 2024 Agil Distribution Tunisia',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
