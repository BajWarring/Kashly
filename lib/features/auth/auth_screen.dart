import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/features/auth/auth_provider.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/core/theme/app_theme.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: authState.isAuthenticated
                  ? _buildSignedIn(context, ref, authState)
                  : _buildSignedOut(context, ref, authState),
            ),
    );
  }

  Widget _buildSignedIn(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (authState.user?.displayName?.substring(0, 1) ?? 'G').toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.user?.displayName ?? 'Google User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        authState.user?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const ListTile(
          leading: Icon(Icons.drive_folder_upload_outlined),
          title: Text('Google Drive Connected'),
          subtitle: Text('Backups will sync to your Drive'),
          trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.switch_account_outlined),
          title: const Text('Switch Account'),
          onTap: () => ref.read(authProvider.notifier).switchAccount(),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Signing out will stop automatic Drive backup. Local data is preserved.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
            if (confirm == true) ref.read(authProvider.notifier).signOut();
          },
        ),
      ],
    );
  }

  Widget _buildSignedOut(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 24),
        Text('Connect Google Account', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Sign in to enable automatic Drive backups and sync across devices.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (authState.error != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.red.shade900.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(authState.error!, style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => ref.read(authProvider.notifier).signIn(),
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kashly will only access Drive to store your backups.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
