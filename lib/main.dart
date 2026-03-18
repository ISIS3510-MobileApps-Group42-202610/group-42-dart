import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme/app_theme.dart';
import 'auth/auth.dart';
import 'analytics/analytics.dart';
import 'home/screens/home_screen.dart';

void main() {
  final appStartTime = DateTime.now();

  runApp(
    AnalyticsProviders(
      analyticsBaseUrl: 'https://group-42-analytic-engine-back.vercel.app/',
      child: AuthProviders(
        baseUrl: 'https://group-42-backend.vercel.app/api/v1/',
        child: UniMarketApp(appStartTime: appStartTime),
      ),
    ),
  );
}

class UniMarketApp extends StatelessWidget {
  final DateTime appStartTime;

  const UniMarketApp({super.key, required this.appStartTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniMarket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primaryBlue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.labelDark,
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // Cambio de estados con el bloc
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {

          // Caregando
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UniMarketHeader(subtitle: 'Loading...'),
                    SizedBox(height: 32),
                    CircularProgressIndicator(color: AppColors.primaryBlue),
                  ],
                ),
              ),
            );
          }

          // Autenticado, lleva al home
          if (state is AuthAuthenticated) {
            return StartupTracker(
              appStartTime: appStartTime,
              child: const HomeScreen(),
            );
          }

          // No autenticado, lleva al login
          return const LoginScreen();
        },
      ),

      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/delete-account': (_) => const DeleteAccountScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

//Widget que trackea el startup time una sola vez cuando se muestra el home
class StartupTracker extends StatefulWidget {
  final DateTime appStartTime;
  final Widget child;

  const StartupTracker({required this.appStartTime, required this.child});

  @override
  State<StartupTracker> createState() => StartupTrackerState();
}

class StartupTrackerState extends State<StartupTracker> {
  bool tracked = false;

  @override
  void initState() {
    super.initState();
    if (!tracked) {
      tracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final bloc = context.read<AnalyticsBloc>();
        // Inicializar device info antes de enviar el evento
        await bloc.deviceInfo.init();
        final durationMs = DateTime.now()
            .difference(widget.appStartTime)
            .inMilliseconds
            .toDouble();
        bloc.add(TrackAppStartup(durationMs: durationMs));
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
