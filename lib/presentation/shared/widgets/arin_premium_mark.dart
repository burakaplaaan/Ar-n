import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Ayarlar / ana sayfa Premium satırı — madalya yerine keskin pırlanta.
class ArinPremiumMark extends StatelessWidget {
  const ArinPremiumMark({
    super.key,
    this.size = 22,
    this.color = AppColors.goldAccent,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.diamond_rounded, size: size, color: color);
  }
}
