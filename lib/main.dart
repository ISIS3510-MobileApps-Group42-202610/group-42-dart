import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme/app_theme.dart';
import 'auth/auth.dart';
import 'analytics/analytics.dart';
import 'products/data/listings_cache.dart';
import 'home/screens/home_screen.dart';


// extrae la ubicacion de codigo
String extractCodeLocation(StackTrace? stack) {
  if (stack == null) return 'unknown';
  final frames = stack.toString().split('\n');
  for (final frame in frames) {
    if (frame.contains('package:isis3510_group42_flutter_app')) {
      final match = RegExp(r'\(package:[^)]+/lib/([^)]+)\)').firstMatch(frame);
      if (match != null) return match.group(1) ?? 'unknown';
    }
  }
  return frames.isNotEmpty ? frames.first.trim() : 'unknown';
}

// extrae un nombre de feature legible a partir de la ubicacion de codigo
String extractFeatureName(String codeLocation) {
  final fileName = codeLocation.split('/').last.split(':').first;
  final base = fileName.replaceAll('.dart', '');
  return base
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join('');
}

AnalyticsBloc? analyticsBloc;

void reportCrash(Object error, StackTrace? stack, {String? context}) {
  try {
    final bloc = analyticsBloc;
    if (bloc == null || bloc.isClosed) return;

    final codeLocation = extractCodeLocation(stack);
    final featureName = extractFeatureName(codeLocation);
    final crashSignature = '${error.runtimeType}: ${error.toString().split('\n').first}';

    bloc.add(TrackCrashEvent(
      featureName: featureName.isEmpty ? (context ?? 'Unknown') : featureName,
      codeLocation: codeLocation,
      crashSignature: crashSignature,
      stackTrace: stack?.toString(),
      metadata: context != null ? {'context': context} : null,
    ));
  } catch (_) {
    // Never let crash reporting itself throw
  }
}

Future<void> main() async {
  // startup time
  final appStartTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();

  // capturar errores no atrapados en el framework de Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    reportCrash(details.exception, details.stack, context: details.library);
  };

  // capturar errores no atrapados en zonas de Dart (incluye async)
  PlatformDispatcher.instance.onError = (error, stack) {
    reportCrash(error, stack);
    return true;
  };

  runApp(
    AnalyticsProviders(
      analyticsBaseUrl: 'https://group-42-analytic-engine-back.vercel.app',
      child: AuthProviders(
        baseUrl: 'https://group-42-backend.vercel.app/api/v1',
        child: UniMarketApp(appStartTime: appStartTime),
      ),
    ),
  );
}

class UniMarketApp extends StatefulWidget {
  final DateTime appStartTime;

  const UniMarketApp({super.key, required this.appStartTime});

  @override
  State<UniMarketApp> createState() => UniMarketAppState();
}

class UniMarketAppState extends State<UniMarketApp> {
  // Cambio para que el tracking solo ocurra si el usuario esta autenticado de antess
  bool allowStartupTracking = true;

  @override
  Widget build(BuildContext context) {
    // sacar el bloc analitico para usarlo en el reporte de crashes
    analyticsBloc = context.read<AnalyticsBloc>();

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
      home: AuthGate(appStartTime: widget.appStartTime),

      routes: {
        '/register': (_) => const RegisterScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/delete-account': (_) => const DeleteAccountScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  final DateTime appStartTime;

  const AuthGate({
    super.key,
    required this.appStartTime,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool allowStartupTracking = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // No reconstruir para AuthLoading si ya estamos en una pantalla activa
        // Esto evita destruir el LoginScreen mientras procesa el login
        if (current is AuthLoading) return false;

        return current is AuthInitial ||
            current is AuthAuthenticated ||
            current is AuthUnauthenticated ||
            current is AuthError ||
            current is AuthConnectionError;
      },
      listener: (context, state) {
        if (state is AuthUnauthenticated && allowStartupTracking) {
          setState(() {
            allowStartupTracking = false;
          });
        }
      },
      builder: (context, state) {
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

        if (state is AuthAuthenticated) {
          if (allowStartupTracking) {
            return StartupTracker(
              appStartTime: widget.appStartTime,
              child: const HomeScreen(),
            );
          }

          return const HomeScreen();
        }

        return const LoginScreen();
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
        // sacar el bloc analitico para enviar el evento de startup
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
