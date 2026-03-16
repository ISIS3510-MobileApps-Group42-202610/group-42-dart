// Vista de delete, realizada con las vistas del prototipo nativo del MS7

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../theme/app_theme.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final formKey = GlobalKey<FormState>();
  final passwerdController = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    passwerdController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.dangerRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.dangerRed,
            size: 32,
          ),
        ),
        title: const Text(
          'Delete your account?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'All your data, listings, and purchase history will be erased.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: dangerButtonStyle().copyWith(
              padding: WidgetStatePropertyAll(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<AuthBloc>().add(
      AuthDeleteAccountRequest(password: passwerdController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthActionSuccess &&
                state.action == 'delete_account') {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
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
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // ── Header (red-tinted) ───────────────────────
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.person_off_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        "We're sorry to see you go",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dangerRed,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Enter your password to confirm. '
                          'This action is irreversible.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dangerRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Danger zone card ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.dangerRed.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: AppColors.dangerRed.withOpacity(0.7),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Danger Zone',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dangerRed,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          fieldLabel('Current Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwerdController,
                            obscureText: obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => submit(),
                            decoration: uniInputDecoration(
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            onPressed: isLoading ? null : submit,
                            style: dangerButtonStyle(),
                            icon: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.delete_forever),
                            label: const Text(
                              'Delete My Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Never mind, take me back',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
}
