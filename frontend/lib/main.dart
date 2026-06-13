import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_navigation_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/main_navigation_wrapper.dart';
import 'features/notifications/presentation/notification_controller.dart';
import 'features/kvkk/data/kvkk_service.dart';
import 'features/kvkk/presentation/kvkk_consent_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('Background notification received: ${message.messageId}');
  debugPrint('Background notification data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _setupFirebaseMessaging();

  runApp(
    const ProviderScope(
      child: GreenhouseApp(),
    ),
  );
}

Future<void> _setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('Notification permission status: ${settings.authorizationStatus}');

  final token = await messaging.getToken();
  debugPrint('FCM TOKEN: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground notification received.');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification opened.');
    debugPrint('Data: ${message.data}');

    final type = message.data['type'];

    if (type == 'greenhouse_alert') {
      AppNavigationController.goToAlerts();
    }
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint('App opened from terminated notification.');
    debugPrint('Initial message data: ${initialMessage.data}');

    final type = initialMessage.data['type'];

    if (type == 'greenhouse_alert') {
      Future.delayed(const Duration(milliseconds: 500), () {
        AppNavigationController.goToAlerts();
      });
    }
  }
}

class GreenhouseApp extends ConsumerStatefulWidget {
  const GreenhouseApp({super.key});

  @override
  ConsumerState<GreenhouseApp> createState() => _GreenhouseAppState();
}

class _GreenhouseAppState extends ConsumerState<GreenhouseApp> {
  bool _hasRegisteredFcmToken = false;
  bool _isKvkkLoading = true;
  bool _isKvkkAccepted = false;

  final KvkkService _kvkkService = KvkkService();

  @override
  void initState() {
    super.initState();
    _loadKvkkState();
  }

  Future<void> _loadKvkkState() async {
    final accepted = await _kvkkService.isAccepted();

    if (!mounted) return;

    setState(() {
      _isKvkkAccepted = accepted;
      _isKvkkLoading = false;
    });
  }

  Future<void> _acceptKvkk() async {
    await _kvkkService.accept();

    if (!mounted) return;

    setState(() {
      _isKvkkAccepted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (authState is Authenticated && !_hasRegisteredFcmToken) {
      _hasRegisteredFcmToken = true;

      Future.microtask(() async {
        await ref
            .read(notificationControllerProvider)
            .registerCurrentDeviceToken();
      });
    }

    if (authState is! Authenticated && _hasRegisteredFcmToken) {
      _hasRegisteredFcmToken = false;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Greenhouse',
      theme: AppTheme.darkTheme,
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState state) {
    if (_isKvkkLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isKvkkAccepted) {
      return KvkkConsentPage(
        onAccepted: _acceptKvkk,
      );
    }

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