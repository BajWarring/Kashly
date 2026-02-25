import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kashly/features/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: Center(
        child: authState.isAuthenticated
            ? Column(
                children: [
                  Text('Logged in as ${authState.user?.email}'),
                  ElevatedButton(
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                    child: const Text('Sign Out'),
                  ),
                  ElevatedButton(
                    onPressed: () => ref.read(authProvider.notifier).switchAccount(),
                    child: const Text('Switch Account'),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).signIn(),
                child: const Text('Sign in with Google'),
              ),
      ),
    );
  }
}
