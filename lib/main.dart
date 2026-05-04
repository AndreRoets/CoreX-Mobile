import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/property_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_hub_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/messaging_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force normal (non-immersive) system UI so the Android home pill /
  // gesture bar always responds — without this, any screen that ever
  // entered immersive mode can leave the gesture bar in a stuck state.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
  await dotenv.load(fileName: '.env');
  try {
    await Firebase.initializeApp();
    await MessagingService.instance.init(navigatorKey: rootNavigatorKey);
  } catch (e) {
    debugPrint('[firebase] init failed: $e');
  }
  await _requestInitialPermissions();
  runApp(const CoreXApp());
}

Future<void> _requestInitialPermissions() async {
  final cameraStatus = await Permission.camera.status;
  if (!cameraStatus.isGranted && !cameraStatus.isPermanentlyDenied) {
    await Permission.camera.request();
  }

  final notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted && !notificationStatus.isPermanentlyDenied) {
    await Permission.notification.request();
  }
}

class CoreXApp extends StatelessWidget {
  const CoreXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'CoreX OS',
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AppBootstrap(),
          );
        },
      ),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!_splashDone || auth.isChecking) {
      return SplashScreen(
        onFinished: () => setState(() => _splashDone = true),
      );
    }
    return const AuthGate();
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      return const HomeHubScreen();
    }
    return const LoginScreen();
  }
}
