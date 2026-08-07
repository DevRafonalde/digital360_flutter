import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Wordmark oficial do app: "digital" + "360" em destaque. Usado no lugar de
/// "Digital 360" em texto puro na splash, login e cabecalhos.
class Wordmark extends StatelessWidget {
  final double fontSize;
  final Color? corTexto;
  final Color? corDestaque;

  const Wordmark({
    super.key,
    this.fontSize = 28,
    this.corTexto,
    this.corDestaque,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(
            text: 'digital',
            style: TextStyle(color: corTexto ?? AppColors.onBackground),
          ),
          TextSpan(
            text: '360',
            style: TextStyle(color: corDestaque ?? AppColors.primary),
          ),
        ],
      ),
    );
  }
}
