import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/color_tokens.dart';

/// 大号金额输入（分段标签 + 金额文本 + 底部数字键盘）。
/// 值由父级持有 [valueCents]（int 分）；通过 [generation] 强制重建以清空。
class AmountInput extends StatefulWidget {
  const AmountInput({
    super.key,
    required this.valueCents,
    this.generation = 0,
    this.onChanged,
  });

  final int valueCents;
  final int generation;
  final ValueChanged<int>? onChanged;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late String _display;

  @override
  void initState() {
    super.initState();
    _display = _centsToString(widget.valueCents);
  }

  @override
  void didUpdateWidget(AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.generation != oldWidget.generation) {
      _display = '';
    } else if (widget.valueCents != oldWidget.valueCents) {
      _display = _centsToString(widget.valueCents);
    }
  }

  String _centsToString(int cents) =>
      cents <= 0 ? '' : (cents / 100).toStringAsFixed(2);

  int _parseCents() {
    final text = _display.replaceAll(',', '').trim();
    if (text.isEmpty) return 0;
    final value = double.tryParse(text);
    return value == null ? 0 : (value * 100).round();
  }

  void _handleDigit(String d) {
    final current = _display.replaceAll(',', '').replaceAll('.', '');
    // 限制两位小数：仅在末位允许 "."，最多一位。
    final hasDot = _display.contains('.');
    if (hasDot) {
      final decimal = _display.split('.').last;
      if (decimal.length >= 2) return; // 小数位已满
    }
    var next = _display;
    if (next == '0') next = '';
    next += d;
    if (next.length > 9) return;
    setState(() {
      _display = next;
      widget.onChanged?.call(_parseCents());
    });
  }

  void _handleDot() {
    if (_display.contains('.')) return;
    setState(() {
      _display = _display.isEmpty ? '0.' : '$_display.';
      widget.onChanged?.call(_parseCents());
    });
  }

  void _handleDelete() {
    if (_display.isEmpty) return;
    setState(() {
      _display = _display.substring(0, _display.length - 1);
      widget.onChanged?.call(_parseCents());
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _display.isEmpty ? '0.00' : _display;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('¥',
                  style: TextStyle(
                      fontSize: 26, color: ColorTokens.mintDark)),
              const SizedBox(width: 4),
              Text(
                shown,
                style: TextStyle(
                  fontSize: _display.length > 8 ? 30 : 44,
                  fontWeight: FontWeight.w800,
                  color: ColorTokens.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildKeypad(),
      ],
    );
  }

  Widget _buildKeypad() {
    const rows = <List<String>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'del'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: _Key(
                    key,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (key == 'del') {
                        _handleDelete();
                      } else if (key == '.') {
                        _handleDot();
                      } else {
                        _handleDigit(key);
                      }
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        child: Center(
          child: label == 'del'
              ? const Icon(Icons.backspace_outlined,
                  size: 26, color: ColorTokens.textSecondary)
              : Text(
                  label,
                  style: const TextStyle(
                      fontSize: 22, color: ColorTokens.textPrimary),
                ),
        ),
      ),
    );
  }
}
