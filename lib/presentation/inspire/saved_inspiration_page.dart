import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../data/models/inspiration_card_model.dart';
import 'inspiration_catalog_provider.dart';
import 'inspiration_engagement_provider.dart';
import 'inspiration_search.dart';
import 'inspire_viewer_session_provider.dart';
import 'widgets/inspiration_grid_tile.dart';

/// Ayarlar → Kaydedilenler: Keşfet’te kaydedilen kartlar (sıra: en yeni üstte).
class SavedInspirationPage extends ConsumerWidget {
  const SavedInspirationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final savedIds = ref.watch(inspirationSavedIdsProvider);
    final catalogAsync = ref.watch(inspirationCatalogProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.homeGradientTop, AppColors.homeGradientBottom],
            stops: [0.0, 0.65],
          ),
        ),
        child: catalogAsync.when(
          data: (catalog) {
            final byId = {for (final c in catalog) c.id: c};
            final cards = <InspirationCardModel>[];
            for (final id in savedIds) {
              final c = byId[id];
              if (c != null) cards.add(c);
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.grey.withValues(alpha: 0.42),
                  leading: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  title: Text(
                    l10n.savedInspirationTitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (cards.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _SavedEmptyState(
                      onExplore: () {
                        context.pop();
                        context.go(AppRoutes.inspire);
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.zero,
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 0,
                            crossAxisSpacing: 0,
                            childAspectRatio: 0.75,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final card = cards[index];
                        return InspirationGridTile(
                          card: card,
                          onTap: (originRect) {
                            final openNonce =
                                DateTime.now().microsecondsSinceEpoch;
                            final deck = InspireViewerDeckExtra(
                              cards: cards,
                              initialIndex: index,
                              originRect: originRect,
                            );
                            ref
                                    .read(
                                      inspireViewerDeckSessionProvider.notifier,
                                    )
                                    .state =
                                deck;
                            context.push(
                              AppRoutes.inspireView(
                                index,
                                openNonce: openNonce,
                              ),
                              extra: deck,
                            );
                          },
                        );
                      }, childCount: cards.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentNeonGreen),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${l10n.savedInspirationLoadFailedPrefix}: $e',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Zengin boş-durum: soluk Arapça "kalem" (قلم) motifi + parıltılı bookmark
/// halkası + Keşfet'e davet CTA'sı. Tek bir metin bloğu yerine kullanıcıya
/// "bu ekran yakında dolacak" hissi verir.
class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = AppColors.accentNeonGreen;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Arapça kaligrafi fısıltısı — arkada atmosfer oluşturur.
        Positioned(
          top: 80,
          child: Text(
            'ٱلْحِكْمَةُ',
            style: GoogleFonts.scheherazadeNew(
              fontSize: 74,
              color: Colors.white.withValues(alpha: 0.06),
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ).animate().fadeIn(duration: 900.ms),
        ),
        // Ana içerik — dikey merkezlenmiş kart.
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.38),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.bookmark_add_outlined,
                      size: 48,
                      color: accent.withValues(alpha: 0.92),
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 520.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 380.ms),
              const SizedBox(height: 28),
              Text(
                l10n.savedInspirationEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
              const SizedBox(height: 10),
              Text(
                l10n.savedInspirationEmptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                  height: 1.55,
                ),
              ).animate().fadeIn(delay: 220.ms, duration: 420.ms),
              const SizedBox(height: 26),
              FilledButton.icon(
                    onPressed: onExplore,
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: Text(l10n.savedInspirationGoExploreAction),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent.withValues(alpha: 0.92),
                      foregroundColor: AppColors.anthraciteDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 320.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.25,
                    end: 0,
                    duration: 420.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
