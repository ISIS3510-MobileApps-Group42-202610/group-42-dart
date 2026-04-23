// Vista de reset password, realizada con las vistas del prototipo nativo del MS7

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../services/auth_connectivity_helper.dart';
import '../../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin, AuthConnectivityHelper<ResetPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool tokenSent = false;
  late final AnimationController animationController;
  late final Animation<double> fadeSlide;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fadeSlide = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );
    startConnectivityMonitoring();
  }

  @override
  void dispose() {
    animationController.dispose();
    emailController.dispose();
    tokenController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // Acciones

  void submitEmail() {
    if (!hasConnectivityResult) return;

    if (!isConnected) {
      showOfflineSnackBar();
      return;
    }

    // Valida solo el campo de email cuando aún no se ha enviado el token
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }

    context.read<AuthBloc>().add(
      AuthForgotPasswordRequest(email: emailController.text.trim()),
    );
  }

  void submitReset() {
    if (!hasConnectivityResult) return;

    if (!isConnected) {
      showOfflineSnackBar();
      return;
    }

    if (!formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthResetPasswordRequest(
        token: tokenController.text.trim(),
        newPassword: passwordController.text,
      ),
    );
  }

  // Mostrar los campos solo cuando ya se envio el correo
  // pasar el fadeSlide de 0 a 1 en size y opacity y que se vea bonito
  void revealResetFields() {
    setState(() => tokenSent = true);
    animationController.forward(from: 0);
  }

  // ocultar los campos de lo contrario
  // pasar el fadeSlide de 1 a 0 en size y opacity
  void hideResetFields() {
    animationController.reverse().then((_) {
      setState(() => tokenSent = false);
    });
  }

  // Widget principal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthActionSuccess) {
              if (state.action == AuthAction.forgotPassword) {
                revealResetFields();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
              if (state.action == AuthAction.resetPassword) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
                Navigator.pushReplacementNamed(context, '/login');
              }
            }
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthConnectionError) {
              showOfflineSnackBar(state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final canSubmit = !isLoading && hasConnectivityResult && isConnected;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    const UniMarketHeader(subtitle: 'Reset your password'),

                    const SizedBox(height: 16),

                    // Banner principal de la page
                    // Cambia de acuerdo a si ya se envio el token o no
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: tokenSent
                          ? infoBanner(
                              key: const ValueKey('sent'),
                              text:
                                  'Check your email for the code we just sent.',
                              color: AppColors.secondaryGreen,
                            )
                          : infoBanner(
                              key: const ValueKey('enter'),
                              text:
                                  "Enter your email and we'll send you a reset code.",
                              color: AppColors.primaryBlue,
                            ),
                    ),

                    const SizedBox(height: 32),

                    // email
                    fieldLabel('University Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: tokenSent
                          ? TextInputAction.next
                          : TextInputAction.done,
                      enabled: !tokenSent,
                      // se bloquea después de enviar
                      onFieldSubmitted: (_) {
                        if (!tokenSent) submitEmail();
                      },
                      decoration: uniInputDecoration(
                        hint: 'you@university.edu',
                        icon: Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    // Campos de reseteo de contraseña
                    // Cambia con el fadeSlide
                    const SizedBox(height: 16),
                    SizeTransition(
                      sizeFactor: fadeSlide,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: fadeSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),

                            // Reset code
                            fieldLabel('Reset Code'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: tokenController,
                              textInputAction: TextInputAction.next,
                              decoration: uniInputDecoration(
                                hint: 'Paste your code',
                                icon: Icons.confirmation_number_outlined,
                              ),
                              validator: tokenSent
                                  ? (v) => (v == null || v.isEmpty)
                                        ? 'Enter the code from your email'
                                        : null
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // New password
                            fieldLabel('New Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: uniInputDecoration(
                                hint: 'Min. 6 characters',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => obscurePassword = !obscurePassword,
                                  ),
                                ),
                              ),
                              validator: tokenSent
                                  ? (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Required';
                                      if (v.length < 6) {
                                        return 'At least 6 characters';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Confirm password
                            fieldLabel('Confirm New Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: confirmController,
                              obscureText: obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => submitReset(),
                              decoration: uniInputDecoration(
                                hint: 'Repeat your password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => obscureConfirm = !obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: tokenSent
                                  ? (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Required';
                                      if (v != passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Boton principal
                    ElevatedButton(
                      onPressed: canSubmit
                          ? (tokenSent ? submitReset : submitEmail)
                          : null,
                      style: primaryButtonStyle(),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          // El boton cambia tambien con el tokenSent
                          // Si no se ha enviado o si ya se envio
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                tokenSent
                                    ? 'Reset Password'
                                    : 'Send Reset Code',
                                key: ValueKey(tokenSent),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Links de la parte de abajo
                    if (tokenSent)
                      Center(
                        child: TextButton(
                          onPressed: hideResetFields,
                          child: const Text(
                            "Didn't get a code? Go back",
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password?',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // helpers generales

  Widget infoBanner({
    required Key key,
    required String text,
    required Color color,
  }) {
    return Center(
      key: key,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
