import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUserProfile();
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to edit profile
              _showComingSoon(context, 'Modifier le profil');
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ProfileProvider>(
        builder: (context, authProvider, profileProvider, child) {
          return RefreshIndicator(
            onRefresh: () => profileProvider.loadUserProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  ProfileHeader(
                    name: profileProvider.userProfile?['name'] ?? 
                          authProvider.currentUser?['name'] ?? 'Utilisateur',
                    position: profileProvider.userProfile?['position'] ?? 'Employee',
                    station: profileProvider.userProfile?['station'] ?? 'Agil Station',
                    avatar: profileProvider.userProfile?['avatar'],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Profile information
                  if (profileProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (profileProvider.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              profileProvider.errorMessage!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              profileProvider.clearError();
                              profileProvider.loadUserProfile();
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Personal information
                    Text(
                      'Informations personnelles',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ProfileInfoCard(
                      title: 'Contact',
                      items: [
                        ProfileInfoItem(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: profileProvider.userProfile?['email'] ?? 
                                 authProvider.userEmail ?? 'Non défini',
                        ),
                        ProfileInfoItem(
                          icon: Icons.phone_outlined,
                          label: 'Téléphone',
                          value: profileProvider.userProfile?['phone'] ?? 'Non défini',
                        ),
                        ProfileInfoItem(
                          icon: Icons.location_on_outlined,
                          label: 'Adresse',
                          value: profileProvider.userProfile?['address'] ?? 'Non défini',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ProfileInfoCard(
                      title: 'Professionnel',
                      items: [
                        ProfileInfoItem(
                          icon: Icons.badge_outlined,
                          label: 'ID Employé',
                          value: profileProvider.userProfile?['id'] ?? 'Non défini',
                        ),
                        ProfileInfoItem(
                          icon: Icons.business_outlined,
                          label: 'Station',
                          value: profileProvider.userProfile?['station'] ?? 'Non défini',
                        ),
                        ProfileInfoItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date d\'embauche',
                          value: profileProvider.userProfile?['joinDate'] ?? 'Non défini',
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Menu items
                  Text(
                    'Paramètres',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ProfileMenu(
                    onLogout: _handleLogout,
                    onComingSoon: _showComingSoon,
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bientôt disponible'),
        content: Text('La fonctionnalité "$feature" sera bientôt disponible.'),
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
