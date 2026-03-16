// Vista de Registro, realizada con las vistas del prototipo nativo del MS7

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordControllr = TextEditingController();
  final confirmControler = TextEditingController();
  final semesterController = TextEditingController();
  bool isSeller = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordControllr.dispose();
    confirmControler.dispose();
    semesterController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthRegisterRequest(
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordControllr.text,
        semester: semesterController.text.isNotEmpty
            ? int.tryParse(semesterController.text)
            : null,
        isSeller: isSeller,
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
            if (state is AuthAuthenticated) {
              Navigator.pushReplacementNamed(context, '/home');
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
                    const SizedBox(height: 48),

                    //Header
                    const UniMarketHeader(
                      subtitle: 'Create your marketplace account',
                    ),

                    const SizedBox(height: 36),

                    //First
                    fieldLabel('First Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: uniInputDecoration(
                        hint: 'Juan',
                        icon: Icons.person_outline,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    //last_name (dios mio esto me dio muchos problemas con dio xd)
                    fieldLabel('Last Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: uniInputDecoration(
                        hint: 'García',
                        icon: Icons.person_outline,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    // email (debe ser universitariooo)
                    fieldLabel('University Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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

                    const SizedBox(height: 16),

                    // contraseña
                    fieldLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordControllr,
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // confirmar contraseña
                    fieldLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: confirmControler,
                      obscureText: obscureConfirm,
                      textInputAction: TextInputAction.next,
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
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != passwordControllr.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // semestre
                    fieldLabel('Semester (optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: semesterController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: uniInputDecoration(
                        hint: 'e.g. 5',
                        icon: Icons.school_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // es vendedor?
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'I want to sell products',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.labelDark,
                          ),
                        ),
                        activeColor: AppColors.secondaryGreen,
                        value: isSeller,
                        onChanged: (v) => setState(() => isSeller = v),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // enviar el form al backend
                    ElevatedButton(
                      onPressed: isLoading ? null : submit,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Ya tengo una cuenta, es decir, vamos a login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
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
}
