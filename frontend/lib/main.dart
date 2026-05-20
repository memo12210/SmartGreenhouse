import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/main_navigation_wrapper.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GreenhouseApp(),
    ),
  );
}

class GreenhouseApp extends ConsumerWidget {
  const GreenhouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Greenhouse',
      theme: AppTheme.darkTheme,
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState state) {
    if (state is Authenticated) {
      return const MainNavigationWrapper();
    }
    
    if (state is AuthInitial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const LoginPage();
  }
}
