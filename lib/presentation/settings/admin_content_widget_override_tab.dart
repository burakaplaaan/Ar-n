part of 'admin_content_page.dart';

Widget _buildAdminWidgetOverrideTab({
  required BuildContext context,
  required double bottomInset,
  required bool loading,
  required bool saving,
  required String? error,
  required Map<String, dynamic>? doc,
  required TextEditingController textController,
  required TextEditingController sourceController,
  required TextEditingController hoursController,
  required Future<void> Function() onRefresh,
  required Future<void> Function() onActivate,
  required Future<void> Function() onDisable,
  required bool globalLockLoading,
  required bool globalLockSaving,
  required String? globalLockError,
  required Map<String, dynamic>? globalLockDoc,
  required TextEditingController globalLockNoteController,
  required TextEditingController widgetUnlockHoursController,
  required Future<void> Function() onGlobalLockRefresh,
  required Future<void> Function() onGlobalLock,
  required Future<void> Function() onGlobalUnlock,
  required Future<void> Function() onWidgetUnlockHoursSave,
}) {
  final now = DateTime.now();
  final expiresAt = _adminDateFromValue(doc?['expiresAt']);
  final active =
      doc?['active'] == true &&
      (doc?['text']?.toString().trim().isNotEmpty ?? false) &&
      (expiresAt == null || expiresAt.isAfter(now));
  final updatedAt = _adminDateFromValue(doc?['updatedAt']);

  if (loading && doc == null) {
    return const Center(child: ArinLoader());
  }

  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      children: [
        _globalLockSectionCard(
          loading: globalLockLoading,
          saving: globalLockSaving,
          error: globalLockError,
          doc: globalLockDoc,
          noteController: globalLockNoteController,
          unlockHoursController: widgetUnlockHoursController,
          onRefresh: onGlobalLockRefresh,
          onLock: onGlobalLock,
          onUnlock: onGlobalUnlock,
          onUnlockHoursSave: onWidgetUnlockHoursSave,
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Colors.white24),
        const SizedBox(height: 16),
        _widgetOverrideStatusCard(
          active: active,
          updatedAt: updatedAt,
          expiresAt: expiresAt,
        ),
        const SizedBox(height: 12),
        _widgetOverrideHowItWorksCard(),
        const SizedBox(height: 12),
        if (error != null) ...[
          Text(error, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: textController,
          minLines: 3,
          maxLines: 5,
          maxLength: 180,
          decoration: const InputDecoration(
            labelText: 'Geçici widget mesajı',
            hintText: 'Kilit ekranı widgetlarında görünecek kısa metin',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: sourceController,
          maxLength: 36,
          decoration: const InputDecoration(
            labelText: 'Kaynak / üst başlık',
            hintText: 'Arın',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: hoursController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Otomatik kapanma süresi (saat)',
            helperText:
                '1-720 saat arası. Süre dolarsa cihazlar normal havuza döner.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: saving ? null : onActivate,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: ArinLoader(strokeWidth: 2),
                      )
                    : const Icon(Icons.campaign_outlined),
                label: const Text('Geçici mesajı yayına al'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving || !active ? null : onDisable,
                icon: const Icon(Icons.restore_outlined),
                label: const Text('Normal akışa dön'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: loading || saving ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Sunucudan yenile'),
        ),
      ],
    ),
  );
}

Widget _widgetOverrideStatusCard({
  required bool active,
  required DateTime? updatedAt,
  required DateTime? expiresAt,
}) {
  final color = active ? AppColors.accentNeonGreen : Colors.white70;
  final title = active
      ? 'Geçici widget mesajı aktif'
      : 'Widget normal havuz akışında';
  final subtitle = active
      ? 'Kullanıcı cihazları bir sonraki düşük frekanslı kontrolde bu mesajı uygular.'
      : 'Widget sözleri mevcut widget_quote havuzundan belirli slotlarla devam eder.';
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.45)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(active ? Icons.campaign : Icons.schedule, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        if (updatedAt != null || expiresAt != null) ...[
          const SizedBox(height: 10),
          Text(
            [
              if (updatedAt != null) 'Güncelleme: ${_shortDateTime(updatedAt)}',
              if (expiresAt != null) 'Bitiş: ${_shortDateTime(expiresAt)}',
            ].join(' · '),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _globalLockSectionCard({
  required bool loading,
  required bool saving,
  required String? error,
  required Map<String, dynamic>? doc,
  required TextEditingController noteController,
  required TextEditingController unlockHoursController,
  required Future<void> Function() onRefresh,
  required Future<void> Function() onLock,
  required Future<void> Function() onUnlock,
  required Future<void> Function() onUnlockHoursSave,
}) {
  final locked = doc?['locked'] == true;
  final updatedAt = _adminDateFromValue(doc?['updatedAt']);
  final lockedColor = locked ? Colors.redAccent : AppColors.accentNeonGreen;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: lockedColor.withValues(alpha: locked ? 0.65 : 0.3),
        width: locked ? 1.5 : 1.0,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: lockedColor.withValues(alpha: locked ? 0.14 : 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
          ),
          child: Row(
            children: [
              Icon(
                locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: lockedColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locked
                          ? 'Global Widget Kilidi AÇIK'
                          : 'Global Widget Kilidi Kapalı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: lockedColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locked
                          ? 'Tüm kullanıcıların widgetları kilitli (premium hariç)'
                          : 'Widgetlar normal erişim kurallarıyla çalışıyor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: ArinLoader(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (updatedAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Son güncelleme: ${_shortDateTime(updatedAt)}'
              '${doc?['note']?.toString().trim().isNotEmpty == true ? ' · Not: ${doc!['note']}' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: noteController,
            maxLength: 120,
            maxLines: 1,
            decoration: const InputDecoration(
              labelText: 'Kilit notu (isteğe bağlı)',
              hintText: 'Örn: Bakım modu, Abonelik zorunlu…',
              border: OutlineInputBorder(),
              isDense: true,
              counterText: '',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: unlockHoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Reklam sonrası açık kalma süresi',
                    helperText: '1–72 saat arasında bir değer gir.',
                    suffixText: 'saat',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: saving ? null : onUnlockHoursSave,
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('Kaydet'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: locked
                        ? Colors.redAccent.withValues(alpha: 0.75)
                        : Colors.redAccent,
                  ),
                  onPressed: saving || locked ? null : onLock,
                  icon: saving && !locked
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: ArinLoader(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_rounded, size: 18),
                  label: const Text('Tüm Widget\'ları Kilitle'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentNeonGreen,
                    side: BorderSide(
                      color: AppColors.accentNeonGreen.withValues(
                        alpha: locked ? 0.9 : 0.35,
                      ),
                    ),
                  ),
                  onPressed: saving || !locked ? null : onUnlock,
                  icon: saving && locked
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: ArinLoader(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded, size: 18),
                  label: const Text('Kilidi Kaldır'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: InkWell(
            onTap: loading || saving ? null : onRefresh,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 4),
                Text(
                  'Durumu yenile',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _widgetOverrideHowItWorksCard() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.emeraldFaint.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.accentNeonGreen.withValues(alpha: 0.25),
      ),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Çalışma mantığı', style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text(
          'Bu panel tek bir Firestore dokümanı yazar: app_public/widget_override. '
          'Kullanıcı cihazları bunu sürekli dinlemez; uygulama açılışı/foreground '
          'bakımında düşük frekansla kontrol eder. Aktifse widget schedule geçici '
          'olarak temizlenir ve bu mesaj yazılır. Kapatınca veya süre dolunca cihaz '
          'bir sonraki kontrolde widget_quote havuzundaki normal akışa döner.',
          style: TextStyle(fontSize: 12, height: 1.35),
        ),
      ],
    ),
  );
}
