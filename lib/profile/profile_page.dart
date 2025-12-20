import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/profile_controller.dart';
import '../controllers/theme_controller.dart';
import '../admin/admin_home.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up your profile...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======================
                // HEADER
                // ======================
                _buildHeader(profile),
                const SizedBox(height: 24),

                // ======================
                // BASIC INFORMATION
                // ======================
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.email_outlined,
                        title: 'Email',
                        subtitle: profile.email,
                      ),
                      _buildDivider(),
                      _buildListTile(
                        context,
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        subtitle: profile.phoneNumber ?? 'Not set',
                      ),
                      _buildDivider(),
                      _buildListTile(
                        context,
                        icon: Icons.person_outline,
                        title: 'Gender',
                        subtitle: profile.gender ?? 'Not set',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ======================
                // 🔒 ADMIN PANEL (OPTION B)
                // ======================
                if (profile.isAdmin) ...[
                  _buildSectionTitle('Administration'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(
                        Icons.admin_panel_settings,
                        color: Color(0xFF3470D9),
                      ),
                      title: const Text(
                        'Admin Panel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                          'Manage staff & approve leave'),
                      trailing:
                          const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminHome(
                              companyId: profile.companyId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ======================
                // APP SETTINGS
                // ======================
                _buildSectionTitle('App Settings'),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Notifications'),
                        secondary: const Icon(
                            Icons.notifications_outlined),
                        value: true,
                        onChanged: (val) {
                          // TODO: Implement notification toggle
                        },
                      ),
                      _buildDivider(),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        secondary: const Icon(
                            Icons.dark_mode_outlined),
                        value: isDarkMode,
                        onChanged: (val) {
                          ref
                              .read(themeProvider.notifier)
                              .toggleTheme(val);
                        },
                      ),
                      _buildDivider(),
                      ListTile(
                        leading:
                            const Icon(Icons.lock_outline),
                        title:
                            const Text('Change Password'),
                        trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16),
                        onTap: () {
                          _showChangePasswordDialog(context);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE57373), Color(0xFFEF5350)], // Red gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======================
  // HELPER WIDGETS
  // ======================
  Widget _buildHeader(profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CBFDA), Color(0xFF3BAECC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: profile.profilePictureUrl != null
                ? NetworkImage(profile.profilePictureUrl!)
                : null,
            child: profile.profilePictureUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.designation,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Staff ID: ${profile.employeeId}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon,
          color:
              Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1,
        thickness: 0.5,
        indent: 16,
        endIndent: 16);
  }

  void _showChangePasswordDialog(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Text(
            'We will send a password reset link to:\n$email\n\nProceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(
                        email: email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Password reset email sent')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                        content:
                            Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }
}
