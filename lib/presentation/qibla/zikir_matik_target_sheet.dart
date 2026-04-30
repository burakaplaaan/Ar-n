part of 'zikir_matik_page.dart';

class _ZikirMatikTargetPickerSheet extends StatefulWidget {
  const _ZikirMatikTargetPickerSheet({
    required this.initialTarget,
    required this.onCommitted,
  });

  final int initialTarget;
  final void Function(int) onCommitted;

  @override
  State<_ZikirMatikTargetPickerSheet> createState() =>
      _ZikirMatikTargetPickerSheetState();
}

class _ZikirMatikTargetPickerSheetState extends State<_ZikirMatikTargetPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTarget.toString());
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int step) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        (step * 0.1).clamp(0.0, 0.5),
        (0.52 + step * 0.1).clamp(0.52, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _enter(int step, Widget child) {
    final t = _stagger(step);
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) {
        return Opacity(
          opacity: t.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t.value)),
            child: child,
          ),
        );
      },
    );
  }

  void _commit(int value) {
    Navigator.pop(context);
    widget.onCommitted(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sel33 = widget.initialTarget == 33;
    final sel99 = widget.initialTarget == 99;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: _ZikirmatikColors.pageBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _enter(
                    0,
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _ZikirmatikColors.outer
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                _enter(
                  1,
                  Text(
                    _ztr(
                      context,
                      tr: 'Hedef',
                      en: 'Target',
                      ar: 'الهدف',
                    ),
                    style: TextStyle(
                      color: _ZikirmatikColors.labelMuted,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _enter(
                  2,
                  Row(
                    children: [
                      Expanded(
                        child: _TargetPresetPill(
                          label: _ztr(context, tr: '33', en: '33', ar: '٣٣'),
                          selected: sel33,
                          onTap: () => _commit(33),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TargetPresetPill(
                          label: _ztr(context, tr: '99', en: '99', ar: '٩٩'),
                          selected: sel99,
                          onTap: () => _commit(99),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _enter(
                  3,
                  Center(
                    child: SizedBox(
                      width: 148,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: _ZikirmatikColors.labelMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: _ZikirmatikColors.lcdBg,
                        decoration: InputDecoration(
                          labelText: _ztr(
                            context,
                            tr: 'Özel…',
                            en: 'Custom…',
                            ar: 'مخصص…',
                          ),
                          labelStyle: TextStyle(
                            color: _ZikirmatikColors.outer
                                .withValues(alpha: 0.95),
                            fontSize: 12,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: _ZikirmatikColors.lcdBg,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: _ZikirmatikColors.smallBtn
                              .withValues(alpha: 0.42),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _ZikirmatikColors.outer,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _ZikirmatikColors.outer
                                  .withValues(alpha: 0.85),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _ZikirmatikColors.lcdBg,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _enter(
                  4,
                  Center(
                    child: FilledButton(
                      onPressed: () {
                        final parsed = int.tryParse(_controller.text.trim());
                        final v = parsed ?? widget.initialTarget;
                        _commit(v);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _ZikirmatikColors.outer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 11,
                        ),
                        minimumSize: const Size(116, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _ztr(
                          context,
                          tr: 'Tamam',
                          en: 'OK',
                          ar: 'حسنًا',
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetPresetPill extends StatelessWidget {
  const _TargetPresetPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: 56,
      decoration: BoxDecoration(
        color: selected
            ? _ZikirmatikColors.outer
            : _ZikirmatikColors.smallBtn.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: selected
              ? _ZikirmatikColors.lcdBg.withValues(alpha: 0.45)
              : _ZikirmatikColors.outer,
          width: selected ? 2 : 1.3,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _ZikirmatikColors.outer.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          splashColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.28),
          highlightColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.14),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color:
                    selected ? Colors.white : _ZikirmatikColors.labelMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZikirMatikCircleIconButton extends StatelessWidget {
  const _ZikirMatikCircleIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _ZikirmatikColors.smallBtn,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
