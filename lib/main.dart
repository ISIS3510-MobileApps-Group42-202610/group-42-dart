import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme/app_theme.dart';
import 'auth/auth.dart';
import 'home/screens/home_screen.dart';

void main() {
  runApp(
    AuthProviders(
      baseUrl: 'https://group-42-backend.vercel.app/api/v1/',
      child: const UniMarketApp(),
    ),
  );
}

class UniMarketApp extends StatelessWidget {
  const UniMarketApp({super.key});

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
