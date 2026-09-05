import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';

/// 底部保存 + 「再记一笔」按钮。
class SaveBar extends StatelessWidget {
  const SaveBar({
    super.key,
    required this.onSave,
    this.onSaveAndNext,
    this.saving = false,
  });

  final VoidCallback onSave;
  final VoidCallback? onSaveAndNext;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: ColorTokens.creamCard,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onSaveAndNext != null)
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onSaveAndNext,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('再记一笔',
                    style: TextStyle(
                        fontSize: 15, color: ColorTokens.mintDark)),
              ),
            ),
          if (onSaveAndNext != null) const SizedBox(width: 12),
          Expanded(
            flex: onSaveAndNext == null ? 1 : 2,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(onSaveAndNext == null ? '保存' : '完成'),
            ),
          ),
        ],
      ),
    );
  }
}
