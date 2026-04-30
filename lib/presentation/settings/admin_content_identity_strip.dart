part of 'admin_content_page.dart';

/// Panelin üstünde ince bir şerit — hangi admin, hangi Firebase projesine
/// bağlı olduğunu hızlıca bildirir. Yanlış projeye yazım yapma riskini azaltır
/// (prod vs staging). Görsel: koyu yeşil strip + ADMIN rozeti + email + proje.
class _AdminIdentityStrip extends StatelessWidget {
  const _AdminIdentityStrip({required this.email, required this.projectId});

  final String? email;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.emeraldDark.withValues(alpha: 0.4),
            AppColors.emeraldDark.withValues(alpha: 0.15),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentNeonGreen.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.55),
                width: 0.8,
              ),
            ),
            child: Text(
              l10n.adminIdentityBadge,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppColors.accentNeonGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              email ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.dns_outlined,
            size: 13,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 4),
          Text(
            projectId,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.55),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
