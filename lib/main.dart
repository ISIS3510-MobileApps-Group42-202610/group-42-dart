import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme/app_theme.dart';
import 'auth/auth.dart';
import 'analytics/analytics.dart';
import 'products/data/listings_cache.dart';
import 'home/screens/home_screen.dart';

// Extracts the first app-specific frame from a stack trace string.
// Returns e.g. "product_detail_screen.dart:99" or falls back to "unknown".
String _extractCodeLocation(StackTrace? stack) {
  if (stack == null) return 'unknown';
  final frames = stack.toString().split('\n');
  for (final frame in frames) {
    if (frame.contains('package:isis3510_group42_flutter_app')) {
      // Frame looks like: #0  ClassName.method (package:...lib/path/file.dart:42:10)
      final match = RegExp(r'\(package:[^)]+/lib/([^)]+)\)').firstMatch(frame);
      if (match != null) return match.group(1) ?? 'unknown';
    }
  }
  return frames.isNotEmpty ? frames.first.trim() : 'unknown';
}

// Derives a human-readable feature name from the code location path.
// e.g. "products/screens/product_detail_screen.dart:99" → "ProductDetailScreen"
String _extractFeatureName(String codeLocation) {
  final fileName = codeLocation.split('/').last.split(':').first;
  final base = fileName.replaceAll('.dart', '');
  return base
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join('');
}

AnalyticsBloc? _analyticsBloc;

void _reportCrash(Object error, StackTrace? stack, {String? context}) {
  try {
    final bloc = _analyticsBloc;
    if (bloc == null || bloc.isClosed) return;

    final codeLocation = _extractCodeLocation(stack);
    final featureName = _extractFeatureName(codeLocation);
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
  // await ListingsCache().clearSessionCache();

  // Capture Flutter framework errors (widget build failures, rendering errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportCrash(details.exception, details.stack, context: details.library);
  };

  // Capture uncaught async/platform errors outside the Flutter widget tree
  PlatformDispatcher.instance.onError = (error, stack) {
    _reportCrash(error, stack);
    return true;
  };

  runApp(
    AnalyticsProviders(
      analyticsBaseUrl: 'https://group-42-analytic-engine-back.vercel.app',
      child: AuthProviders(
        baseUrl: 'https://group-42-backend.vercel.app/api/v1/',
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
    // Wire the global crash reporter to this bloc instance as early as possible.
    _analyticsBloc = context.read<AnalyticsBloc>();

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
      home: BlocConsumer<AuthBloc, AuthState>(
        // Only rebuild the root widget for stable auth states.
        // Transient states (AuthError, AuthConnectionError, AuthActionSuccess)
        // are handled by each screen's own listener — rebuilding the root for
        // them would replace the home widget with LoginScreen mid-flow, which
        // breaks the Delete Account back-navigation.
        buildWhen: (previous, current) =>
            current is AuthInitial ||
            current is AuthAuthenticated ||
            current is AuthUnauthenticated ||
            (current is AuthLoading && previous is AuthInitial),
        listener: (context, state) {
          if (state is AuthUnauthenticated && allowStartupTracking) {
            setState(() => allowStartupTracking = false);
          }
        },
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
            // si etsaba autenticado pre-startup, hacer el startup tracker
            if (allowStartupTracking) {
              return StartupTracker(
                appStartTime: widget.appStartTime,
                child: const HomeScreen(),
              );
            }
            return const HomeScreen();
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
