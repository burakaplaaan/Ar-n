// lib/core/theme/app_theme.dart
// Uygulamanın tam ThemeData tanımları ve Glassmorphism extension'ları.
// Hem açık (light) hem koyu (dark) mod desteklenir.

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radii.dart';
import '../constants/app_text_styles.dart';
import 'arin_backdrop_blur.dart';

// ─── Glassmorphism Yardımcı Sınıfı ─────────────────────────────────────────

/// Cam efektli kart görünümü için gerekli tüm stil parametrelerini tutar.
class GlassStyle {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double blurSigma;
  final List<BoxShadow> shadows;

  const GlassStyle({
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 20.0,
    this.blurSigma = 12.0,
    this.shadows = const [],
  });

  BoxDecoration toDecoration() => BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      );
}

// ─── Glassmorphism Preset'leri ───────────────────────────────────────────────

abstract final class GlassPresets {
  /// Standart cam kart (açık mod)
  static const GlassStyle card = GlassStyle(
    backgroundColor: Color(0x1AFFFFFF),
    borderColor: Color(0x33FFFFFF),
    borderWidth: 1.0,
    borderRadius: 20.0,
    blurSigma: 12.0,
    shadows: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );

  /// Namaz vakti kartı — koyu zümrüt arka plan üzerinde cam
  static const GlassStyle prayerCard = GlassStyle(
    backgroundColor: Color(0x33FFFFFF),
    borderColor: Color(0x4DFFFFFF),
    borderWidth: 1.2,
    borderRadius: 24.0,
    blurSigma: 16.0,
    shadows: [
      BoxShadow(
        color: Color(0x261B4D3E),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );

  /// Ayetler/hadisler kartı — ince kenarlıklı
  static const GlassStyle contentCard = GlassStyle(
    backgroundColor: Color(0x0DFFFFFF),
    borderColor: Color(0x1AFFFFFF),
    borderWidth: 0.8,
    borderRadius: 18.0,
    blurSigma: 8.0,
    shadows: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  /// Dark mode cam kart
  static const GlassStyle cardDark = GlassStyle(
    backgroundColor: Color(0x1AFFFFFF),
    borderColor: Color(0x26FFFFFF),
    borderWidth: 1.0,
    borderRadius: 20.0,
    blurSigma: 14.0,
    shadows: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );
}

// ─── Glassmorphism Widget ────────────────────────────────────────────────────

/// Herhangi bir widget'ı cam efektiyle sarar.
/// [style] ile farklı preset'ler uygulanabilir.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final GlassStyle style;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.style = GlassPresets.card,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ArinBackdropBlur(
        sigma: style.blurSigma,
        borderRadius: BorderRadius.circular(style.borderRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: style.toDecoration(),
          child: child,
        ),
      ),
    );
  }
}

// ─── ThemeData Fabrikası ────────────────────────────────────────────────────

/// ARIN uygulamasının açık ve koyu tema tanımları.
abstract final class AppTheme {
  // ────────────────────────────────────────────────────────────────────
  // AÇIK MOD TEMA
  // ────────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, isLight: true);

    return withoutMaterialRipple(base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.emeraldDark,
        primaryContainer: AppColors.emeraldMid,
        secondary: AppColors.emeraldLight,
        secondaryContainer: AppColors.emeraldFaint,
        surface: AppColors.creamSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
        outline: AppColors.creamDark,
        shadow: AppColors.glassShadow,
      ),
      scaffoldBackgroundColor: AppColors.creamMist,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentGreenOnLight,
        circularTrackColor: AppColors.emeraldFaint,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.creamSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.creamDark, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emeraldDark,
          side: const BorderSide(color: AppColors.emeraldDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emeraldDark,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.creamSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.creamDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.creamDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.emeraldMid, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTextStyles.muted,
        labelStyle: AppTextStyles.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.creamSurface,
        selectedColor: AppColors.emeraldDark,
        labelStyle: AppTextStyles.labelMedium,
        side: const BorderSide(color: AppColors.creamDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.emeraldDark,
        inactiveTrackColor: AppColors.emeraldFaint,
        thumbColor: AppColors.emeraldDark,
        overlayColor: Color(0x1A1B4D3E),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.emeraldDark
              : AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.emeraldFaint
              : AppColors.creamDark;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.creamDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.creamSurface,
        selectedItemColor: AppColors.emeraldDark,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.anthraciteDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.creamSurface,
        surfaceTintColor: Colors.transparent,
        shape: AppRadii.lgShape,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    ));
  }

  // ────────────────────────────────────────────────────────────────────
  // KOYU MOD TEMA
  // ────────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, isLight: false);

    return withoutMaterialRipple(base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emeraldLight,
        primaryContainer: AppColors.emeraldMid,
        secondary: AppColors.emeraldFaint,
        secondaryContainer: AppColors.anthraciteLight,
        surface: AppColors.anthraciteMid,
        error: AppColors.error,
        onPrimary: AppColors.anthraciteDark,
        onSecondary: AppColors.anthraciteDark,
        onSurface: AppColors.textOnDark,
        onError: Colors.white,
        outline: AppColors.anthraciteLight,
        shadow: Color(0x40000000),
      ),
      scaffoldBackgroundColor: AppColors.anthraciteDark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle:
            AppTextStyles.headlineMedium.copyWith(color: AppColors.textOnDark),
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.anthraciteMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.anthraciteLight, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldLight,
          foregroundColor: AppColors.anthraciteDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.anthraciteMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.anthraciteLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.anthraciteLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.emeraldLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTextStyles.muted
            .copyWith(color: AppColors.textOnDarkMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.anthraciteLight,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.anthraciteMid,
        selectedItemColor: AppColors.emeraldLight,
        unselectedItemColor: AppColors.textOnDarkMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.homeCardSurface,
        surfaceTintColor: Colors.transparent,
        shape: AppRadii.lgShape,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDarkMuted,
          height: 1.5,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    ));
  }

  /// InkWell / IconButton / Material butonlardaki "içine dolma" ripple'ı kapatır.
  /// Basma hissi [ArinPressable] ölçek/göçük animasyonuyla verilir.
  static ThemeData withoutMaterialRipple(ThemeData theme) {
    const transparentOverlay = WidgetStatePropertyAll<Color>(Colors.transparent);
    ButtonStyle withoutOverlay(ButtonStyle? style) {
      return (style ?? const ButtonStyle()).copyWith(
        overlayColor: transparentOverlay,
        splashFactory: NoSplash.splashFactory,
      );
    }

    return theme.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      iconButtonTheme: IconButtonThemeData(
        style: withoutOverlay(theme.iconButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: withoutOverlay(theme.elevatedButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: withoutOverlay(theme.outlinedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: withoutOverlay(theme.textButtonTheme.style),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: withoutOverlay(theme.filledButtonTheme.style),
      ),
      floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
    );
  }

  // ─── Yardımcı: TextTheme Oluşturucu ─────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base, {required bool isLight}) {
    final color = isLight ? AppColors.textPrimary : AppColors.textOnDark;
    return base.apply(
      fontFamily: AppTextStyles.primaryFontFamily,
      bodyColor: color,
      displayColor: color,
    );
  }
}
