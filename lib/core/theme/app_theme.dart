import 'package:flutter/material.dart';

import 'color_tokens.dart';

/// 清新可爱主题（本期交付浅色，深色 token 已预留随 P2）。
class AppTheme {
  AppTheme._();

  static const double borderRadius = 16;

  /// 分类图标 key → Material IconData 映射（Q 萌图标取色/圆底）。
  static const Map<String, IconData> iconMap = <String, IconData>{
    'restaurant': Icons.restaurant,
    'directions_bus': Icons.directions_bus,
    'shopping_bag': Icons.shopping_bag,
    'home': Icons.home,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'trending_up': Icons.trending_up,
    'emoji_events': Icons.emoji_events,
    'wallet': Icons.wallet,
    'fastfood': Icons.fastfood,
    'train': Icons.train,
    'flight': Icons.flight,
    'pet': Icons.pets,
    'fitness_center': Icons.fitness_center,
    'phone_iphone': Icons.phone_iphone,
    'card_giftcard': Icons.card_giftcard,
    'payments': Icons.payments,
  };

  static IconData iconFor(String? iconKey) =>
      iconMap[iconKey] ?? Icons.category;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorTokens.mintPrimary,
        primary: ColorTokens.mintPrimary,
        surface: ColorTokens.creamCard,
      ),
      scaffoldBackgroundColor: ColorTokens.creamBg,
      fontFamilyFallback: const <String>['PingFang SC', 'Microsoft YaHei'],
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorTokens.creamBg,
        foregroundColor: ColorTokens.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: ColorTokens.creamCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.mintPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.mintPrimary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
