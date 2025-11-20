import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/auth_provider.dart';
import 'services/notification_service.dart';
import 'services/notification_manager.dart';
import 'services/navigation_service.dart';
import 'providers/ride_request_provider.dart';
import 'models/user_model.dart';
import 'models/ride_request_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/rider/rider_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/new_driver_home_screen.dart';
import 'screens/rider/new_ride_booking_screen.dart';
import 'screens/rider/new_ride_tracking_screen.dart';
import 'screens/driver/new_driver_ride_screen.dart';
import 'screens/rider/ride_tracking_screen_simple.dart';
import 'screens/driver/driver_ride_screen_simple.dart';
import 'screens/rider/carpool_discovery_screen.dart';
import 'screens/driver/carpool_requests_screen.dart';
import 'screens/driver/create_carpool_screen.dart';
import 'screens/test_ride_flow_screen.dart';
import 'widgets/carpool_request_flow_demo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }

  // Initialize notification services
  try {
    final notificationService = NotificationService();
    final notificationManager = NotificationManager();
    await notificationService.initialize();
    await notificationManager.initialize();
  } catch (e) {
    debugPrint('Notification services initialization failed: $e');
    // Continue without notifications for now
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RideRequestProvider()),
      ],
      child: MaterialApp(
        title: 'GoCab',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1976D2),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/rider-home': (context) => const RiderHomeScreen(),
          '/new-driver-home': (context) => const NewDriverHomeScreen(),
          '/new-ride-booking': (context) => const NewRideBookingScreen(),
          '/new-ride-tracking': (context) {
            final rideRequest =
                ModalRoute.of(context)?.settings.arguments as RideRequestModel;
            return NewRideTrackingScreen(rideRequest: rideRequest);
          },
          '/new-driver-ride': (context) {
            final rideRequest =
                ModalRoute.of(context)?.settings.arguments as RideRequestModel;
            return NewDriverRideScreen(rideRequest: rideRequest);
          },
          '/carpool-discovery': (context) => const CarpoolDiscoveryScreen(),
          '/carpool-requests': (context) => const CarpoolRequestsScreen(),
          '/create-carpool': (context) => const CreateCarpoolScreen(),
          '/test-flow': (context) => const TestRideFlowScreen(),
          '/carpool-demo': (context) => const CarpoolRequestFlowDemo(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint(
          '🔄 AuthWrapper: isAuthenticated=${authProvider.isAuthenticated}, userModel=${authProvider.userModel?.uid}, isLoading=${authProvider.isLoading}',
        );

        if (authProvider.isLoading) {
          debugPrint('🔄 AuthWrapper: Showing loading screen');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated && authProvider.userModel != null) {
          debugPrint(
            '🔄 AuthWrapper: User authenticated, routing to ${authProvider.userModel!.role.name} screen',
          );
          // Route based on user role
          switch (authProvider.userModel!.role) {
            case UserRole.rider:
              return const RiderHomeScreen();
            case UserRole.driver:
              return const NewDriverHomeScreen();
          }
        }

        // Show login screen if not authenticated
        debugPrint(
          '🔄 AuthWrapper: User not authenticated, showing login screen',
        );
        return const LoginScreen();
      },
    );
  }
}
