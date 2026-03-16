// Vista de reset password, realizada con las vistas del prototipo nativo del MS7

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Primer paso es lo del correo
  final emailFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  // Segundo paso es lo del token y la contraseña
  final resetFormKey = GlobalKey<FormState>();
  final tokenControler = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureComfirm = true;

  bool tokenSent = false;

  @override
  void dispose() {
    emailController.dispose();
    tokenControler.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void submitEmail() {
    if (!emailFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthForgotPasswordRequest(email: emailController.text.trim()),
    );
  }

  void submitReset() {
    if (!resetFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthResetPasswordRequest(
        token: tokenControler.text.trim(),
        newPassword: passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthActionSuccess) {
              if (state.action == 'forgot_password') {
                setState(() => tokenSent = true);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
              if (state.action == 'reset_password') {
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
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: tokenSent
                  ? buildResetForm(isLoading)
                  : buildEmailForm(isLoading),
            );
          },
        ),
      ),
    );
  }

  // Poner correo

  Widget buildEmailForm(bool isLoading) {
    return Form(
      key: emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),

          const UniMarketHeader(subtitle: 'Reset your password'),

          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Enter your email and we'll send you a reset code.",
                style: TextStyle(fontSize: 14, color: AppColors.primaryBlue),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 32),

          fieldLabel('University Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => submitEmail(),
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

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: isLoading ? null : submitEmail,
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
                : const Text(
                    'Send Reset Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),

          const SizedBox(height: 24),

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
    );
  }

  // PASO 2: usar el token para resetear

  Widget buildResetForm(bool isLoading) {
    return Form(
      key: resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),

          const UniMarketHeader(subtitle: 'Enter your reset code'),

          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Check your email for the code we just sent.',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryGreen),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Codigo de reseteo
          fieldLabel('Reset Code'),
          const SizedBox(height: 8),
          TextFormField(
            controller: tokenControler,
            textInputAction: TextInputAction.next,
            decoration: uniInputDecoration(
              hint: 'Paste your code',
              icon: Icons.confirmation_number_outlined,
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Enter the code from your email'
                : null,
          ),

          const SizedBox(height: 16),

          // Nueva contraseña
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
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Confirmar contraseña
          fieldLabel('Confirm New Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: confirmController,
            obscureText: obscureComfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => submitReset(),
            decoration: uniInputDecoration(
              hint: 'Repeat your password',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  obscureComfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => obscureComfirm = !obscureComfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v != passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: isLoading ? null : submitReset,
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
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () => setState(() => tokenSent = false),
              child: const Text(
                "Didn't get a code? Go back",
                style: TextStyle(color: AppColors.primaryBlue, fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
