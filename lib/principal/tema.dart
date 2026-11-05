import 'package:flutter/material.dart';

abstract final class TemaHortasmart {
  static const verde = Color(0xFF087B4B);
  static const verdeEscuro = Color(0xFF075C39);
  static const verdeClaro = Color(0xFFE6F4E9);
  static const fundo = Color(0xFFF4F7F5);
  static const texto = Color(0xFF172A20);
  static const textoSecundario = Color(0xFF718078);
  static const amarelo = Color(0xFFE5A317);
  static const amareloClaro = Color(0xFFFFF4D9);
  static const vermelho = Color(0xFFE54855);
  static const vermelhoClaro = Color(0xFFFFE9E8);
  static const azul = Color(0xFF2583CA);

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: verde,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema.copyWith(primary: verde, secondary: const Color(0xFF62A66D)),
      scaffoldBackgroundColor: fundo,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: verdeEscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAF8),
        labelStyle: const TextStyle(color: textoSecundario, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE3EAE4))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: verde, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE4E9E5),
          disabledForegroundColor: const Color(0xFF9AA69D),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: verde,
          side: const BorderSide(color: Color(0xFFD9E4D9)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      sliderTheme: const SliderThemeData(activeTrackColor: verde, thumbColor: verde, overlayColor: Color(0x22236744)),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: verdeClaro,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 10,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? verdeEscuro : textoSecundario,
        )),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: verdeEscuro),
        unselectedIconTheme: IconThemeData(color: textoSecundario),
        selectedLabelTextStyle: TextStyle(color: verdeEscuro, fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: textoSecundario, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
