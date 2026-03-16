// pagina de login

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>(); // validar formulario
  final emailController = TextEditingController(); // controlador de email
  final passwordController = TextEditingController(); // controlador de contraseña
  bool obscure = true; // ocultar contraseña por defecto

  @override
  void dispose() { // limpiar los controladores
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() { // validar formulario y enviar peticion
    if (!formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginRequest(
        email: emailController.text,
        password: passwordController.text,
      ),
    );
  }

  // El view como tal xd
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    );
  }
}