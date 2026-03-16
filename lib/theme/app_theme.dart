import 'package:flutter/material.dart';

// Paleta de colores de UniMarket
class AppColors {
  AppColors._();

  static const primaryBlue = Color(0xFF1565C0);
  static const secondaryGreen = Color(0xFF2E7D32);
  static const inputFill = Color(0xFFF5F5F5);
  static const labelDark = Color(0xFF333333);
  static const dangerRed = Color(0xFFC62828);
}

// Input decoration para UniMarket
InputDecoration uniInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    prefixIcon: Icon(icon, color: Colors.grey, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.5),
    ),
  );
}

// Texto para los labels
Widget fieldLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.labelDark,
    ),
  );
}

// Boton de color primario
ButtonStyle primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );
}

// Boton rojo
ButtonStyle dangerButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.dangerRed,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );
}

// Logo y heading de UniMarket
class UniMarketHeader extends StatelessWidget {
  final String? subtitle;

  const UniMarketHeader({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'UniMarket',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              subtitle!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}