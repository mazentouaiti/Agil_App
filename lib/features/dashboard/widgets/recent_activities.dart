import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      ActivityItem(
        icon: Icons.shopping_cart,
        title: 'Vente de carburant',
        subtitle: '150L Essence Super • 180 TND',
        time: 'Il y a 2h',
        color: AppColors.success,
      ),
      ActivityItem(
        icon: Icons.local_shipping,
        title: 'Livraison reçue',
        subtitle: 'Carburant Premium • 5000L',
        time: 'Il y a 4h',
        color: AppColors.info,
      ),
      ActivityItem(
        icon: Icons.person_add,
        title: 'Nouveau client',
        subtitle: 'Entreprise Transport Ltd.',
        time: 'Il y a 6h',
        color: AppColors.primary,
      ),
      ActivityItem(
        icon: Icons.warning,
        title: 'Stock faible',
        subtitle: 'Diesel niveau critique',
        time: 'Il y a 1j',
        color: AppColors.warning,
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activités récentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full activities list
                    _showComingSoon(context);
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
          ),
          
          // Activities list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => Divider(
              color: AppColors.gray200,
              height: 1,
              indent: 60,
            ),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activity.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity.icon,
                    color: activity.color,
                    size: 20,
                  ),
                ),
                title: Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  activity.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Text(
                  activity.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bientôt disponible'),
        content: const Text('La liste complète des activités sera bientôt disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}
