import 'package:flutter/material.dart';

/// Cores do sistema baseadas no design system da aplicação
class AppColors {
  // IDENTIDADE DA MARCA
  static const Color primary = Color(0xFF00A76F);
  static const Color primaryHover = Color(0xFF008558);
  
  // DESTAQUE COMPLEMENTAR
  static const Color accent = Color(0xFFFF7043);

  // FEEDBACK DO SISTEMA (Semânticas)
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF42A5F5);
  static const Color success = primary; // Reaproveita o verde da marca

  // NEUTROS (Fundo e Textos)
  static const Color bgMain = Color(0xFFF8FAFC);      // Fundo do app, cinza gelo
  static const Color bgSurface = Color(0xFFFFFFFF);   // Fundo dos cards branquinhos
  static const Color textTitle = Color(0xFF1E293B);   // Preto levemente azulado para títulos
  static const Color textBody = Color(0xFF64748B);    // Cinza médio para descrições
  static const Color borderLine = Color(0xFFE2E8F0);  // Bordas sutis
}
