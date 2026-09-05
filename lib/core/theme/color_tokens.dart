import 'dart:ui';

/// 语义色 token：组件内禁止硬编码 Color(0x...)，统一引用此处。
class ColorTokens {
  ColorTokens._();

  // 主题色板（soft pastel）
  static const Color mintPrimary = Color(0xFF7FD1A4); // 薄荷绿（主色）
  static const Color mintDark = Color(0xFF4FA87C); // 深薄荷绿（文字/按压）
  static const Color creamBg = Color(0xFFFFF9EE); // 奶油黄（背景）
  static const Color creamCard = Color(0xFFFFFDF6); // 卡片底色
  static const Color sakuraAccent = Color(0xFFF7A8B8); // 樱花粉（强调）
  static const Color sakuraLight = Color(0xFFFCE4E9); // 浅樱花粉（预留，QA-F7）

  // 语义
  static const Color expenseRed = Color(0xFFE05C6E); // 支出红
  static const Color incomeGreen = Color(0xFF3FAE78); // 收入绿
  static const Color textPrimary = Color(0xFF3A3A3A);
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color divider = Color(0xFFF0ECE3);

  // 深色（预留 P2，本期仅浅色）
  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkText = Color(0xFFF2F2F2);
}
