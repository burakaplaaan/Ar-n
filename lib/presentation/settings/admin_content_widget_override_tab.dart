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
}) {
  final now = DateTime.now();
  final expiresAt = _adminDateFromValue(doc?['expiresAt']);
  final active =
      doc?['active'] == true &&
      (doc?['text']?.toString().trim().isNotEmpty ?? false) &&
      (expiresAt == null || expiresAt.isAfter(now));
  final updatedAt = _adminDateFromValue(doc?['updatedAt']);

  if (loading && doc == null) {
    return const Center(child: CircularProgressIndicator());
  }

  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      children: [
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
                        child: CircularProgressIndicator(strokeWidth: 2),
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
