// Vista de Registro, realizada con las vistas del prototipo nativo del MS7

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../theme/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final picker = ImagePicker();
  File? selectedProfileImage;
  bool isSeller = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
  }

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
        profileImageFile: selectedProfileImage,
        isSeller: isSeller,
      ),
    );
  }

  Future<void> pickProfileImage(ImageSource source) async {
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (picked == null) return;

    setState(() {
      selectedProfileImage = File(picked.path);
    });
  }

  void showProfileImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a profile photo'),
              subtitle: const Text('Uses the phone camera sensor'),
              onTap: () {
                Navigator.pop(context);
                pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                pickProfileImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void removeProfileImage() {
    setState(() {
      selectedProfileImage = null;
    });
  }

  Widget buildProfilePhotoPicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: showProfileImageSourceSheet,
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.inputFill,
            backgroundImage: selectedProfileImage != null
                ? FileImage(selectedProfileImage!)
                : null,
            child: selectedProfileImage == null
                ? const Icon(
              Icons.camera_alt_outlined,
              size: 36,
              color: AppColors.primaryBlue,
            )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: showProfileImageSourceSheet,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            selectedProfileImage == null
                ? 'Add profile photo'
                : 'Change profile photo',
          ),
        ),
        if (selectedProfileImage != null)
          TextButton.icon(
            onPressed: removeProfileImage,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove photo'),
          ),
      ],
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
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.black,
                    duration: const Duration(seconds: 4),
                  )
              );
            } else if (state is AuthConnectionError) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 4),
                  )
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final canSubmit = !isLoading;

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

                    const SizedBox(height: 24),

                    fieldLabel('Profile photo (optional)'),
                    const SizedBox(height: 8),
                    buildProfilePhotoPicker(),

                    const SizedBox(height: 24),

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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final value = v.trim();
                        if (value.length < 2) return 'At least 2 characters';
                        if (value.length > 50) return 'Max 50 characters';
                        final validName = RegExp(r"^[A-Za-zÀ-ÿ' -]+$");
                        if (!validName.hasMatch(value)) {
                          return 'Only letters, spaces, apostrophes and hyphens';
                        }
                        return null;
                      },
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final value = v.trim();
                        if (value.length < 2) return 'At least 2 characters';
                        if (value.length > 50) return 'Max 50 characters';
                        final validName = RegExp(r"^[A-Za-zÀ-ÿ' -]+$");
                        if (!validName.hasMatch(value)) {
                          return 'Only letters, spaces, apostrophes and hyphens';
                        }
                        return null;
                      },
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
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final parts = v.trim().split('@');
                        if (parts.length != 2 ||
                            parts[0].isEmpty ||
                            !parts[1].contains('.')) {
                          return 'Enter a valid email address';
                        }
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null) return 'Enter a valid number';
                        if (n < 1 || n > 10) {
                          return 'Semester must be between 1 and 10';
                        }
                        return null;
                      },
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
                      onPressed: canSubmit ? submit : null,
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
