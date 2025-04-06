import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/landing_page.dart';
import 'screens/community_page.dart';
import 'providers/user_provider.dart';
import 'services/community_services.dart';
import 'services/moneyMind_service.dart';

// Define the base URL as a constant
const String API_BASE_URL = 'https://moneymind-dlnl.onrender.com';

void main() {
  // This preserves the splash screen until the app is fully loaded
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..initialize()),
        Provider<CommunityService>(
          create: (_) => CommunityService(
            baseUrl: API_BASE_URL,
          ),
        ),
        // Add MoneyMindService provider
        Provider<MoneyMindService>(
          create: (context) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            return MoneyMindService(
              baseUrl: API_BASE_URL,
              userId: userProvider.currentUser?.id?.toString() ?? '1',
            );
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Remove the splash screen when the app is ready
    _removeSplashScreen();
  }

  // This method handles any initialization and then removes the splash screen
  Future<void> _removeSplashScreen() async {
    // You can add any initialization logic here
    // For example, loading initial data, checking authentication status, etc.

    // Add a small delay to ensure providers are initialized (optional)
    await Future.delayed(const Duration(milliseconds: 500));

    // Remove the splash screen when initialization is complete
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoneyMind',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: {
        '/': (context) => const LandingPage(),
        '/community': (context) => const CommunityPage(),
      },
      initialRoute: '/',
    );
  }
}