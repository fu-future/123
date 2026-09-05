import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/category.dart';

/// 分类网格选择器（Q 萌图标 + 名称 + 选中态；可高亮 AI/规则建议分类）。
class CategoryGridSelector extends StatelessWidget {
  const CategoryGridSelector({
    super.key,
    required this.categories,
    required this.selectedId,
    this.suggestedId,
    this.onSelect,
  });

  final List<Category> categories;
  final String selectedId;
  final String? suggestedId;
  final ValueChanged<Category>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无可选分类',
            style: TextStyle(color: ColorTokens.textSecondary)),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final c = categories[index];
        final color = Color(c.colorValue);
        final isSelected = c.id == selectedId;
        final isSuggested = c.id == suggestedId && !isSelected;
        return InkWell(
          onTap: () => onSelect?.call(c),
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(isSelected ? 1 : 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: ColorTokens.mintPrimary, width: 2.5)
                      : null,
                ),
                child: Icon(
                  AppTheme.iconFor(c.iconKey),
                  color: isSelected ? Colors.white : color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                c.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSuggested
                      ? ColorTokens.mintDark
                      : (isSelected
                          ? ColorTokens.textPrimary
                          : ColorTokens.textSecondary),
                  fontWeight: isSuggested || isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
              if (isSuggested)
                const Text('推荐',
                    style: TextStyle(
                        fontSize: 9,
                        color: ColorTokens.sakuraAccent,
                        fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}
