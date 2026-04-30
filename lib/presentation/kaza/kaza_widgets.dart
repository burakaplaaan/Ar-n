// Kaza takibi — ortak yüzey ve animasyonlu kontroller.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class KazaPageBackdrop extends StatelessWidget {
  const KazaPageBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.anthraciteDark),
        Positioned(
          top: -120,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentNeonGreen.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class KazaSectionCard extends StatelessWidget {
  const KazaSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.anthraciteMid.withValues(alpha: 0.92),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class KazaPrimaryButton extends StatefulWidget {
  const KazaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<KazaPrimaryButton> createState() => _KazaPrimaryButtonState();
}

class _KazaPrimaryButtonState extends State<KazaPrimaryButton> {
  double _scale = 1;

  void _setDown(bool down) {
    if (widget.onPressed == null) return;
    setState(() => _scale = down ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: enabled
                  ? [
                      AppColors.accentNeonGreen.withValues(alpha: 0.95),
                      AppColors.accentGlowGreen.withValues(alpha: 0.88),
                    ]
                  : [
                      AppColors.anthraciteLight.withValues(alpha: 0.35),
                      AppColors.anthraciteLight.withValues(alpha: 0.25),
                    ],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.labelLarge.copyWith(
              color: enabled
                  ? const Color(0xFF052E16)
                  : AppColors.textOnDarkMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class KazaIconCircleButton extends StatefulWidget {
  const KazaIconCircleButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  State<KazaIconCircleButton> createState() => _KazaIconCircleButtonState();
}

class _KazaIconCircleButtonState extends State<KazaIconCircleButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: (_) {
        if (!enabled) return;
        setState(() => _scale = 0.88);
      },
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.anthraciteDark.withValues(alpha: 0.9),
            border: Border.all(
              color: widget.color.withValues(alpha: enabled ? 0.65 : 0.25),
              width: 1.6,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.color.withValues(alpha: enabled ? 1 : 0.35),
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Basit sayı alanı — koyu kapsül.
class KazaNumberField extends StatelessWidget {
  const KazaNumberField({
    super.key,
    required this.controller,
    this.hint = '0',
    this.textAlign = TextAlign.center,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextAlign textAlign;

  /// true: ortada dar pill (hesap formu — buluğ yaşı / kılınan gün).
  final bool compact;

  static const double _kCompactWidth = 148;

  @override
  Widget build(BuildContext context) {
    final field = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 14),
        color: Colors.black.withValues(alpha: compact ? 0.32 : 0.28),
        border: Border.all(
          color: compact
              ? AppColors.accentNeonGreen.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.08),
          width: compact ? 1.15 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: textAlign,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.creamBase,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 17 : null,
        ),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkMuted.withValues(alpha: 0.5),
            fontSize: compact ? 17 : null,
          ),
        ),
      ),
    );

    if (!compact) return field;

    return Center(
      child: SizedBox(
        width: _kCompactWidth,
        child: field,
      ),
    );
  }
}
