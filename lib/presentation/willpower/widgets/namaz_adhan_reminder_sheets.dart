part of 'namaz_adhan_reminder_card.dart';

class _PrayerNotificationSoundSheet extends StatefulWidget {
  const _PrayerNotificationSoundSheet({
    required this.prefs,
    this.onAfterSoundChange,
  });

  final SharedPreferences prefs;
  final Future<void> Function()? onAfterSoundChange;

  @override
  State<_PrayerNotificationSoundSheet> createState() =>
      _PrayerNotificationSoundSheetState();
}

class _PrayerNotificationSoundSheetState
    extends State<_PrayerNotificationSoundSheet> {
  static const int _groupUserFile = -1;
  static const int _systemSoundPreviewId = 9999001;
  static const Duration _previewDuration = Duration(seconds: 10);

  late List<int> _catalogPerPrayer;
  late int _allPrayerCatalogIndex;
  int? _expandedPrayerIndex;
  bool _showArinSoundList = false;
  bool _showAdvancedSoundSettings = false;
  AudioPlayer? _player;
  Timer? _previewStopTimer;
  bool _needsReschedule = false;

  int get _maxIdx => PrayerNotificationSounds.options.length - 1;

  String _soundOptionTitle(PrayerNtfSoundOption opt) {
    return PrayerNotificationSounds.localizedChannelName(
      opt,
      Localizations.localeOf(context).languageCode,
    );
  }

  @override
  void initState() {
    super.initState();
    _catalogPerPrayer = List.generate(
      PrayerReminderPrefs.slotCount,
      (i) => PrayerReminderPrefs.notificationSoundIndexForPrayer(
        widget.prefs,
        i,
      ).clamp(0, _maxIdx),
    );
    _allPrayerCatalogIndex = _inferAllPrayerCatalogIndex();
  }

  int _inferAllPrayerCatalogIndex() {
    if (_catalogPerPrayer.isEmpty) {
      return PrayerNotificationSounds.defaultCatalogSoundIndex.clamp(
        0,
        _maxIdx,
      );
    }
    final first = _catalogPerPrayer.first.clamp(0, _maxIdx);
    final allSame = _catalogPerPrayer.every((v) => v == first);
    return allSame
        ? first
        : PrayerNotificationSounds.defaultCatalogSoundIndex.clamp(0, _maxIdx);
  }

  @override
  void dispose() {
    unawaited(_commitRescheduleIfNeeded());
    _previewStopTimer?.cancel();
    _previewStopTimer = null;
    final pl = _player;
    _player = null;
    if (pl != null) {
      unawaited(
        Future<void>(() async {
          await pl.stop();
          await pl.dispose();
        }),
      );
    }
    unawaited(
      Future<void>(() async {
        try {
          await arinLocalNotificationsPlugin.cancel(_systemSoundPreviewId);
        } catch (_) {}
      }),
    );
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    _previewStopTimer?.cancel();
    _previewStopTimer = null;
    await _player?.stop();
    await _player?.dispose();
    _player = null;
  }

  void _markNeedsReschedule() {
    _needsReschedule = true;
  }

  Future<void> _commitRescheduleIfNeeded() async {
    if (!_needsReschedule) return;
    if (!PrayerReminderPrefs.isEnabled(widget.prefs)) return;
    await widget.onAfterSoundChange?.call();
    _needsReschedule = false;
  }

  void _armPreviewStopTimer({required bool alsoStopPlayer}) {
    _previewStopTimer?.cancel();
    _previewStopTimer = Timer(_previewDuration, () async {
      if (alsoStopPlayer) {
        try {
          await _player?.stop();
          await _player?.dispose();
        } catch (_) {}
        _player = null;
      }
      try {
        await arinLocalNotificationsPlugin.cancel(_systemSoundPreviewId);
      } catch (_) {}
    });
  }

  Future<void> _preview(PrayerNtfSoundOption opt) async {
    try {
      await _disposePlayer();

      if (opt.previewAssetRelativePath != null) {
        _player = AudioPlayer();
        await _player!.play(AssetSource(opt.previewAssetRelativePath!));
        _armPreviewStopTimer(alsoStopPlayer: true);
        return;
      }

      String? uri;
      if (Platform.isAndroid) {
        final played =
            await PrayerNotificationAndroidUri.playDefaultNotificationSound();
        if (played) return;
        uri = await PrayerNotificationAndroidUri.defaultNotificationSoundUri();
      }

      if (uri == null || uri.isEmpty) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.prayerSoundPreviewSystem,
              style: TextStyle(
                color: AppColors.creamBase.withValues(alpha: 0.92),
              ),
            ),
            backgroundColor: AppColors.anthraciteMid,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      _player = AudioPlayer();
      await _player!.play(UrlSource(uri));
      _armPreviewStopTimer(alsoStopPlayer: true);
    } catch (e, st) {
      debugPrint('Prayer sound preview failed: $e');
      debugPrint('$st');
      await _disposePlayer();
    }
  }

  Future<void> _previewUserFile(Future<String?> Function() pathOf) async {
    try {
      await _disposePlayer();
      final path = await pathOf();
      if (path == null || !mounted) return;
      _player = AudioPlayer();
      await _player!.play(DeviceFileSource(path));
      _armPreviewStopTimer(alsoStopPlayer: true);
    } catch (e, st) {
      debugPrint('Prayer user sound preview failed: $e');
      debugPrint('$st');
      await _disposePlayer();
    }
  }

  void _snackImportFailed() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.prayerSoundImportFailed,
          style: TextStyle(color: AppColors.creamBase.withValues(alpha: 0.92)),
        ),
        backgroundColor: AppColors.anthraciteMid,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickForSlot(int slot) async {
    final ok = await PrayerUserNotificationSoundStore.importForSlot(
      widget.prefs,
      slot,
    );
    if (!mounted) return;
    if (!ok) {
      _snackImportFailed();
      return;
    }
    _markNeedsReschedule();
    setState(() {});
  }

  Future<void> _clearForSlot(int slot) async {
    await PrayerUserNotificationSoundStore.clearForSlot(widget.prefs, slot);
    if (!mounted) return;
    _markNeedsReschedule();
    setState(() {});
  }

  bool _allSlotsHaveUserFile() {
    for (var i = 0; i < PrayerReminderPrefs.slotCount; i++) {
      if (!PrayerReminderPrefs.hasUserSoundForSlot(widget.prefs, i)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _pickForAllSlots() async {
    final ok = await PrayerUserNotificationSoundStore.importForAllSlots(
      widget.prefs,
    );
    if (!mounted) return;
    if (!ok) {
      _snackImportFailed();
      return;
    }
    _markNeedsReschedule();
    setState(() {});
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.prayerSoundAppliedAllSuccess,
          style: TextStyle(color: AppColors.creamBase.withValues(alpha: 0.92)),
        ),
        backgroundColor: AppColors.anthraciteMid,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearForAllSlots() async {
    for (var i = 0; i < PrayerReminderPrefs.slotCount; i++) {
      await PrayerUserNotificationSoundStore.clearForSlot(widget.prefs, i);
    }
    if (!mounted) return;
    _markNeedsReschedule();
    setState(() {});
  }

  Future<void> _applyCatalogSoundToAllPrayers(
    int selected, {
    bool showSuccessSnack = true,
    bool previewAfterApply = true,
  }) async {
    selected = selected.clamp(0, _maxIdx);
    await PrayerReminderPrefs.setNotificationSoundIndex(widget.prefs, selected);
    for (var i = 0; i < PrayerReminderPrefs.slotCount; i++) {
      await PrayerUserNotificationSoundStore.clearForSlot(widget.prefs, i);
    }
    if (!mounted) return;
    setState(() {
      _catalogPerPrayer = List<int>.filled(
        PrayerReminderPrefs.slotCount,
        selected,
      );
      _allPrayerCatalogIndex = selected;
    });
    if (previewAfterApply) {
      await _preview(PrayerNotificationSounds.optionForIndex(selected));
    }
    _markNeedsReschedule();
    if (!showSuccessSnack || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.prayerSoundAppliedAllSuccess,
          style: TextStyle(color: AppColors.creamBase.withValues(alpha: 0.92)),
        ),
        backgroundColor: AppColors.anthraciteMid,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _applySelectedSoundToAllPrayers() async {
    await _applyCatalogSoundToAllPrayers(_allPrayerCatalogIndex);
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.accentNeonGreen.withValues(alpha: 0.92),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _toneTile({
    required int value,
    required int groupValue,
    required PrayerNtfSoundOption opt,
  }) {
    final on = groupValue == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.white.withValues(alpha: on ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(12),
        child: RadioListTile<int>(
          value: value,
          activeColor: AppColors.accentNeonGreen,
          title: Text(
            _soundOptionTitle(opt),
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.creamBase,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneSoundCard({
    required bool hasFile,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required VoidCallback onPreview,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: hasFile ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasFile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                  child: Text(
                    AppLocalizations.of(context)!.prayerSoundUserFromPhone,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPick,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.creamBase,
                        side: BorderSide(
                          color: AppColors.accentNeonGreen.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.prayerSoundPickFromPhone,
                      ),
                    ),
                  ),
                  if (hasFile) ...[
                    IconButton(
                      onPressed: onPreview,
                      tooltip: AppLocalizations.of(context)!.commonPreview,
                      icon: Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
                      ),
                    ),
                    TextButton(
                      onPressed: onClear,
                      child: Text(
                        AppLocalizations.of(context)!.prayerSoundClearUserFile,
                        style: TextStyle(
                          color: AppColors.creamBase.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _allSlotsUseCatalogIndex(int index) {
    if (_allSlotsHaveUserFile()) return false;
    return _catalogPerPrayer.every((v) => v == index);
  }

  String _currentAllSoundSummary() {
    final l10n = AppLocalizations.of(context)!;
    if (_allSlotsHaveUserFile()) return l10n.prayerSoundUserFromPhone;
    final first = _catalogPerPrayer.first.clamp(0, _maxIdx);
    if (_catalogPerPrayer.every((v) => v == first)) {
      return _soundOptionTitle(PrayerNotificationSounds.optionForIndex(first));
    }
    return l10n.reminderPerPrayerDifferentSounds;
  }

  Widget _soundChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: selected ? 0.08 : 0.045),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.accentNeonGreen.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentNeonGreen.withValues(
                      alpha: selected ? 0.18 : 0.09,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.92),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.creamBase,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textOnDarkMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected
                      ? AppColors.accentNeonGreen.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _arinSoundList() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 8),
        child: RadioGroup<int>(
          groupValue: _allPrayerCatalogIndex,
          onChanged: (v) async {
            if (v == null) return;
            await _applyCatalogSoundToAllPrayers(v, showSuccessSnack: false);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 1; i < PrayerNotificationSounds.options.length; i++)
                _toneTile(
                  value: i,
                  groupValue: _allPrayerCatalogIndex,
                  opt: PrayerNotificationSounds.options[i],
                ),
              FilledButton.tonalIcon(
                onPressed: _applySelectedSoundToAllPrayers,
                icon: const Icon(Icons.done_all_rounded),
                label: Text(
                  AppLocalizations.of(context)!.prayerSoundApplyAllButton,
                ),
              ),
            ],
          ),
        ),
      ),
      crossFadeState: _showArinSoundList
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
      sizeCurve: Curves.easeOutCubic,
    );
  }

  Widget _simpleSoundPicker({required bool hasUserFile}) {
    final l10n = AppLocalizations.of(context)!;
    final systemSelected =
        !_showArinSoundList &&
        !hasUserFile &&
        _allSlotsUseCatalogIndex(PrayerNotificationSounds.systemSoundIndex);
    final arinSelected =
        _showArinSoundList ||
        (!hasUserFile &&
            !_allSlotsUseCatalogIndex(
              PrayerNotificationSounds.systemSoundIndex,
            ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.accentNeonGreen.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            l10n.reminderCurrentSound(_currentAllSoundSummary()),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.creamBase.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _soundChoiceCard(
          icon: Icons.notifications_none_rounded,
          title: l10n.prayerSoundSystem,
          subtitle: l10n.reminderUsePhoneDefaultSubtitle,
          selected: systemSelected,
          onTap: () async {
            setState(() {
              _showArinSoundList = false;
              _allPrayerCatalogIndex =
                  PrayerNotificationSounds.systemSoundIndex;
            });
            await _applySelectedSoundToAllPrayers();
          },
        ),
        _soundChoiceCard(
          icon: Icons.graphic_eq_rounded,
          title: l10n.reminderChooseArinSoundsTitle,
          subtitle: l10n.reminderChooseArinSoundsSubtitle,
          selected: arinSelected,
          onTap: () {
            setState(() {
              _showArinSoundList = !_showArinSoundList;
              if (_allPrayerCatalogIndex ==
                  PrayerNotificationSounds.systemSoundIndex) {
                _allPrayerCatalogIndex = 1.clamp(0, _maxIdx);
              }
            });
          },
        ),
        _arinSoundList(),
        _soundChoiceCard(
          icon: Icons.folder_open_rounded,
          title: l10n.prayerSoundPickFromPhone,
          subtitle: hasUserFile
              ? l10n.reminderPhoneSoundActiveAllPrayers
              : l10n.reminderApplyOwnSoundAllPrayers,
          selected: hasUserFile,
          onTap: () async {
            setState(() => _showArinSoundList = false);
            await _pickForAllSlots();
          },
        ),
        if (hasUserFile)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _previewUserFile(
                    () => PrayerUserNotificationSoundStore.absolutePathForSlot(
                      widget.prefs,
                      0,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.commonPreview),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearForAllSlots,
                  child: Text(l10n.prayerSoundClearUserFile),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _showAdvancedSoundSettings = true),
          icon: const Icon(Icons.tune_rounded),
          label: Text(l10n.reminderSetPerPrayerDifferentSound),
        ),
      ],
    );
  }

  Widget _prayerSoundBlock(int prayerIndex, {bool showSectionHeader = true}) {
    const opts = PrayerNotificationSounds.options;
    final hasFile = PrayerReminderPrefs.hasUserSoundForSlot(
      widget.prefs,
      prayerIndex,
    );
    final groupValue = hasFile
        ? _groupUserFile
        : _catalogPerPrayer[prayerIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSectionHeader)
          _sectionHeader(
            _prayerSlotLabel(AppLocalizations.of(context)!, prayerIndex),
          ),
        if (hasFile)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.prayerSoundUserFileActiveHint,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
                height: 1.3,
              ),
            ),
          ),
        RadioGroup<int>(
          groupValue: groupValue,
          onChanged: (v) async {
            if (v == null) return;
            await PrayerUserNotificationSoundStore.clearForSlot(
              widget.prefs,
              prayerIndex,
            );
            if (!mounted) return;
            await PrayerReminderPrefs.setNotificationSoundIndexForPrayer(
              widget.prefs,
              prayerIndex,
              v,
            );
            setState(() {
              _catalogPerPrayer[prayerIndex] = v;
              _allPrayerCatalogIndex = _inferAllPrayerCatalogIndex();
            });
            await _preview(opts[v]);
            _markNeedsReschedule();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < opts.length; i++)
                _toneTile(value: i, groupValue: groupValue, opt: opts[i]),
            ],
          ),
        ),
        _phoneSoundCard(
          hasFile: hasFile,
          onPick: () => _pickForSlot(prayerIndex),
          onClear: () => _clearForSlot(prayerIndex),
          onPreview: () => _previewUserFile(
            () => PrayerUserNotificationSoundStore.absolutePathForSlot(
              widget.prefs,
              prayerIndex,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _activeSoundLabelForPrayer(int prayerIndex) {
    final l10n = AppLocalizations.of(context)!;
    final hasFile = PrayerReminderPrefs.hasUserSoundForSlot(
      widget.prefs,
      prayerIndex,
    );
    if (hasFile) return l10n.prayerSoundUserFromPhone;
    final idx = _catalogPerPrayer[prayerIndex].clamp(0, _maxIdx);
    return _soundOptionTitle(PrayerNotificationSounds.optionForIndex(idx));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final quickAllHasUserFile = _allSlotsHaveUserFile();

    return SafeArea(
      child: SizedBox(
        height: maxH,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentNeonGreen,
                      foregroundColor: const Color(0xFF0A0F0C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      await _commitRescheduleIfNeeded();
                      if (!mounted) return;
                      nav.pop(true);
                    },
                    child: Text(l10n.commonClose),
                  ),
                ],
              ),
              Text(
                l10n.prayerSoundPickerTitle,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.creamBase,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.prayerSoundQuickAllSubtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnDarkMuted,
                  height: 1.35,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8),
                  children: [
                    if (!_showAdvancedSoundSettings) ...[
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.045),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.reminderAllPrayersSoundTitle,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.creamBase,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.reminderAllPrayersSoundSubtitle,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textOnDarkMuted,
                                height: 1.32,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _simpleSoundPicker(
                              hasUserFile: quickAllHasUserFile,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(
                            () => _showAdvancedSoundSettings = false,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(l10n.reminderBackToSingleSoundSelection),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.045),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: AppColors.accentNeonGreen.withValues(
                                    alpha: 0.86,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.prayerSoundAdvancedToggle,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.creamBase,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.prayerSoundSubtitlePerPrayer,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textOnDarkMuted,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.reminderPerPrayerSavedInstantly,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accentNeonGreen.withValues(
                                  alpha: 0.8,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (
                              var p = 0;
                              p < PrayerReminderPrefs.slotCount;
                              p++
                            )
                              Column(
                                children: [
                                  Material(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        setState(() {
                                          _expandedPrayerIndex =
                                              _expandedPrayerIndex == p
                                              ? null
                                              : p;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _prayerSlotLabel(l10n, p),
                                                    style: AppTextStyles
                                                        .labelLarge
                                                        .copyWith(
                                                          color: AppColors
                                                              .creamBase,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _activeSoundLabelForPrayer(
                                                      p,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTextStyles
                                                        .labelSmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .textOnDarkMuted,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              _expandedPrayerIndex == p
                                                  ? Icons.expand_less_rounded
                                                  : Icons.expand_more_rounded,
                                              color: Colors.white.withValues(
                                                alpha: 0.55,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 2,
                                      ),
                                      child: _prayerSoundBlock(
                                        p,
                                        showSectionHeader: false,
                                      ),
                                    ),
                                    crossFadeState: _expandedPrayerIndex == p
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 220),
                                    sizeCurve: Curves.easeOutCubic,
                                  ),
                                  if (p != PrayerReminderPrefs.slotCount - 1)
                                    const SizedBox(height: 8),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerPrayerReminderListSheet extends StatefulWidget {
  const _PerPrayerReminderListSheet({
    required this.prefs,
    required this.isEnablingFlow,
    required this.onReschedule,
    required this.onBildirimSesi,
    required this.onSecondReminderGate,
  });

  final SharedPreferences prefs;
  final bool isEnablingFlow;
  final Future<void> Function() onReschedule;
  final Future<void> Function() onBildirimSesi;
  final Future<bool> Function(int secondValue) onSecondReminderGate;

  @override
  State<_PerPrayerReminderListSheet> createState() =>
      _PerPrayerReminderListSheetState();
}

class _PerPrayerReminderListSheetState
    extends State<_PerPrayerReminderListSheet> {
  Future<void> _applyDurationsToAllPrayers() async {
    await PrayerReminderPrefs.ensurePerPrayerPrefsReady(widget.prefs);
    if (!mounted || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final chosen = await _openDualReminderSheet(
      context,
      prayerTitle: l10n.reminderAllPrayersDurationTarget,
      initialEarly: PrayerReminderPrefs.minutesBeforeForPrayer(widget.prefs, 0),
      initialSecond: PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(
        widget.prefs,
        0,
      ),
    );
    if (chosen == null || !mounted) return;
    final canUseSecond = await widget.onSecondReminderGate(chosen.second);
    if (!canUseSecond || !mounted) return;
    await PrayerReminderPrefs.setMinutesBefore(widget.prefs, chosen.early);
    await PrayerReminderPrefs.setMinutesBeforeSecondary(
      widget.prefs,
      chosen.second,
    );
    await widget.onReschedule();
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.reminderDurationsAppliedAllSuccess,
          style: TextStyle(color: AppColors.creamBase.withValues(alpha: 0.92)),
        ),
        backgroundColor: AppColors.anthraciteMid,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openEditor(int i) async {
    await PrayerReminderPrefs.ensurePerPrayerPrefsReady(widget.prefs);
    if (!mounted || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final chosen = await _openDualReminderSheet(
      context,
      prayerTitle: _prayerSlotLabel(l10n, i),
      initialEarly: PrayerReminderPrefs.minutesBeforeForPrayer(widget.prefs, i),
      initialSecond: PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(
        widget.prefs,
        i,
      ),
    );
    if (chosen == null || !mounted) return;
    final canUseSecond = await widget.onSecondReminderGate(chosen.second);
    if (!canUseSecond || !mounted) return;
    await PrayerReminderPrefs.setMinutesBeforeForPrayer(
      widget.prefs,
      i,
      chosen.early,
    );
    await PrayerReminderPrefs.setMinutesBeforeSecondaryForPrayer(
      widget.prefs,
      i,
      chosen.second,
    );
    await widget.onReschedule();
    setState(() {});
  }

  static const _bronze = Color(0xFFC9A074);
  static const _bronzeDeep = Color(0xFF8A6645);
  static const _panelInk = Color(0xFFF3EDE4);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.74;

    return SafeArea(
      child: SizedBox(
        height: maxH,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _bronzeDeep.withValues(alpha: 0.35),
                        _bronze,
                        _bronzeDeep.withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.isEnablingFlow)
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        l10n.commonCancel,
                        style: TextStyle(
                          color: _panelInk.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentNeonGreen,
                        foregroundColor: const Color(0xFF0A0F0C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.reminderEnableNotificationsAction),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: _bronze.withValues(alpha: 0.9),
                    ),
                    child: Text(l10n.commonClose),
                  ),
                ),
              Text(
                l10n.reminderDurationsPerPrayerTitle,
                style: AppTextStyles.titleSmall.copyWith(
                  color: _panelInk,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 48,
                height: 2.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [_bronzeDeep, _bronze],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.reminderDurationsPerPrayerSubtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: _panelInk.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: PrayerReminderPrefs.slotCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openEditor(i),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                _bronzeDeep.withValues(alpha: 0.14),
                                Colors.white.withValues(alpha: 0.04),
                              ],
                            ),
                            border: Border.all(
                              color: _bronze.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [_bronze, _bronzeDeep],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _prayerSlotLabel(l10n, i),
                                        style: AppTextStyles.labelLarge
                                            .copyWith(
                                          color: _panelInk,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _pairLineForPrayer(
                                          widget.prefs,
                                          i,
                                          l10n,
                                        ),
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                          color: _panelInk.withValues(
                                            alpha: 0.52,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: _bronze.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              _ReminderSheetActionButton(
                icon: Icons.done_all_rounded,
                label: l10n.reminderApplyDurationsAllButton,
                primary: true,
                onTap: _applyDurationsToAllPrayers,
              ),
              const SizedBox(height: 10),
              _ReminderSheetActionButton(
                icon: Icons.graphic_eq_rounded,
                label: l10n.prayerSoundPickerTitle,
                primary: false,
                onTap: () async {
                  await widget.onBildirimSesi();
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, curve: Curves.easeOutCubic);
  }
}

/// Alt aksiyonlar: liste satırı değil, bronz çerçeveli belirgin buton.
class _ReminderSheetActionButton extends StatelessWidget {
  const _ReminderSheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  static const _bronze = Color(0xFFC9A074);
  static const _bronzeDeep = Color(0xFF8A6645);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _bronze.withValues(alpha: 0.18),
        highlightColor: _bronze.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: primary
                  ? [
                      _bronzeDeep.withValues(alpha: 0.55),
                      _bronze.withValues(alpha: 0.28),
                      const Color(0xFF1A1612),
                    ]
                  : [
                      const Color(0xFF1C1814),
                      _bronzeDeep.withValues(alpha: 0.22),
                    ],
            ),
            border: Border.all(
              color: _bronze.withValues(alpha: primary ? 0.55 : 0.38),
              width: primary ? 1.4 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: _bronzeDeep.withValues(alpha: primary ? 0.28 : 0.14),
                blurRadius: primary ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _bronze.withValues(alpha: 0.95),
                        _bronzeDeep.withValues(alpha: 0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _bronze.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: const Color(0xFF1A120C), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: const Color(0xFFF3EDE4),
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _bronze.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DualReminderSheet extends StatefulWidget {
  const _DualReminderSheet({
    required this.prayerTitle,
    required this.initialEarlyIndex,
    required this.initialSecondIndex,
  });

  final String prayerTitle;
  final int initialEarlyIndex;
  final int initialSecondIndex;

  @override
  State<_DualReminderSheet> createState() => _DualReminderSheetState();
}

class _DualReminderSheetState extends State<_DualReminderSheet> {
  static const _itemExtent = 40.0;
  late FixedExtentScrollController _earlyCtrl;
  late FixedExtentScrollController _secondCtrl;
  late int _earlyIndex;
  late int _secondIndex;

  List<int> get _earlyList => PrayerReminderPrefs.pickerEarlyValues;
  List<int> get _secondList => PrayerReminderPrefs.pickerSecondValues;

  @override
  void initState() {
    super.initState();
    _earlyIndex = widget.initialEarlyIndex.clamp(0, _earlyList.length - 1);
    _secondIndex = widget.initialSecondIndex.clamp(0, _secondList.length - 1);
    _earlyCtrl = FixedExtentScrollController(initialItem: _earlyIndex);
    _secondCtrl = FixedExtentScrollController(initialItem: _secondIndex);
  }

  @override
  void dispose() {
    _earlyCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.reminderDualAlertTitle(widget.prayerTitle),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.creamBase,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.reminderDualAlertSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textOnDarkMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.creamBase.withValues(
                          alpha: 0.85,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.commonCancel),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentNeonGreen,
                        foregroundColor: const Color(0xFF0A0F0C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(context, (
                        early: _earlyList[_earlyIndex],
                        second: _secondList[_secondIndex],
                      )),
                      child: Text(l10n.commonDone),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _WheelColumn(
                          title: l10n.reminderFirstAlertTitle,
                          controller: _earlyCtrl,
                          itemExtent: _itemExtent,
                          itemCount: _earlyList.length,
                          labelBuilder: (i) =>
                              _minutePickerLabelEarly(l10n, _earlyList[i]),
                          selectedIndex: _earlyIndex,
                          onChanged: (i) => setState(() => _earlyIndex = i),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _WheelColumn(
                          title: l10n.reminderSecondAlertTitle,
                          controller: _secondCtrl,
                          itemExtent: _itemExtent,
                          itemCount: _secondList.length,
                          labelBuilder: (i) =>
                              _minutePickerLabelSecond(l10n, _secondList[i]),
                          selectedIndex: _secondIndex,
                          onChanged: (i) => setState(() => _secondIndex = i),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 240.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.05, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.title,
    required this.controller,
    required this.itemExtent,
    required this.itemCount,
    required this.labelBuilder,
    required this.selectedIndex,
    required this.onChanged,
  });

  final String title;
  final FixedExtentScrollController controller;
  final double itemExtent;
  final int itemCount;
  final String Function(int i) labelBuilder;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: itemExtent,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 1.25,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, i) {
                    final sel = i == selectedIndex;
                    return Center(
                      child: Text(
                        labelBuilder(i),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: sel
                              ? AppColors.creamBase
                              : AppColors.textOnDarkMuted.withValues(
                                  alpha: 0.45,
                                ),
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                          fontSize: sel ? 17 : 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: itemExtent + 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.accentNeonGreen.withValues(
                          alpha: 0.35,
                        ),
                        width: 1.2,
                      ),
                    ),
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
