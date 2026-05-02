// Her vakit (0…5) için kullanıcının seçtiği ses dosyası (uygulama dizinine kopyalanır).

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_reminder_prefs.dart';

abstract final class PrayerUserNotificationSoundStore {
  static const _legacyFajrBase = 'prayer_ntf_user_fajr';
  static const _legacyImsakBase = 'prayer_ntf_user_imsak';

  /// [FileType.audio] Android’de çoğu cihazda boş “Son” ekranı açılıyor; önce custom kullan.
  static const List<String> _kAudioExtensions = [
    'wav',
    'm4a',
    'mp3',
    'aac',
    'caf',
    'aiff',
    'aif',
    'ogg',
    'flac',
  ];
  static const List<String> _kIosNotificationAudioExtensions = [
    'wav',
    'caf',
    'aiff',
    'aif',
  ];

  static String _slotBase(int slot) => 'prayer_ntf_user_slot_$slot';

  static List<String> _pickerAllowedExtensions() {
    if (!kIsWeb && Platform.isIOS) return _kIosNotificationAudioExtensions;
    return _kAudioExtensions;
  }

  static bool _isAllowedAudioExt(String ext) {
    var e = ext.trim().toLowerCase();
    if (e.startsWith('.')) e = e.substring(1);
    if (e.length > 8) e = e.substring(0, 8);
    if (!kIsWeb && Platform.isIOS) {
      return _kIosNotificationAudioExtensions.contains(e);
    }
    return _kAudioExtensions.contains(e);
  }

  static Future<Directory> _slotStorageDirectory() {
    if (!kIsWeb && Platform.isAndroid) {
      return getApplicationSupportDirectory();
    }
    return getApplicationDocumentsDirectory();
  }

  /// Android 11+: [FileType.custom] + dar filtre “Son” sekmesinde boş kalabiliyor; önce
  /// [FileType.any] ile tam gezinti, sonra uzantı filtresi. Manifest’te [queries] şart.
  static Future<FilePickerResult?> _pickFilesWithFallback() async {
    if (!kIsWeb && Platform.isAndroid) {
      await Permission.audio.request();
    }
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final r = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowCompression: false,
          withData: true,
          dialogTitle: 'Ses dosyası seç',
        );
        if (r != null && r.files.isNotEmpty) return r;
      } catch (e) {
        debugPrint('FilePicker any (Android): $e');
      }
      try {
        final r = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: _pickerAllowedExtensions(),
          allowCompression: false,
          withData: true,
          dialogTitle: 'Ses dosyası seç',
        );
        if (r != null && r.files.isNotEmpty) return r;
      } catch (e) {
        debugPrint('FilePicker custom (Android): $e');
      }
      return null;
    }
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _pickerAllowedExtensions(),
        allowCompression: false,
        withData: true,
        dialogTitle: 'Ses dosyası seç',
      );
      if (r != null && r.files.isNotEmpty) return r;
    } catch (e) {
      debugPrint('FilePicker custom: $e');
    }
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowCompression: false,
        withData: true,
        dialogTitle: 'Ses dosyası seç',
      );
      if (r != null && r.files.isNotEmpty) return r;
    } catch (e) {
      debugPrint('FilePicker any: $e');
    }
    if (Platform.isIOS) {
      try {
        final r = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowCompression: false,
          withData: true,
          dialogTitle: 'Ses dosyası seç',
        );
        if (r != null && r.files.isNotEmpty) return r;
      } catch (e) {
        debugPrint('FilePicker audio (iOS): $e');
      }
    }
    return null;
  }

  /// Eski `fajr` / `imsak` dosyalarını `slot_0` / `slot_1` adlarına kopyalar (bir kez).
  static Future<void> migrateLegacyDiskFilesIfNeeded(
    SharedPreferences p,
  ) async {
    if (kIsWeb) return;
    if (p.getBool('prayer_reminder_ntf_slot_files_copied_v1') ?? false) {
      return;
    }
    final legacyDir = await getApplicationDocumentsDirectory();
    final dir = await _slotStorageDirectory();

    Future<void> copyDoc(String oldB, String newB, String? ext) async {
      if (ext == null || ext.isEmpty) return;
      final oldF = File('${legacyDir.path}/$oldB.$ext');
      final newF = File('${dir.path}/$newB.$ext');
      if (await newF.exists()) return;
      if (await oldF.exists()) await oldF.copy(newF.path);
    }

    await copyDoc(
      _legacyFajrBase,
      _slotBase(0),
      PrayerReminderPrefs.userSoundExtForSlot(p, 0),
    );
    await copyDoc(
      _legacyImsakBase,
      _slotBase(1),
      PrayerReminderPrefs.userSoundExtForSlot(p, 1),
    );

    if (Platform.isIOS) {
      final lib = await getLibraryDirectory();
      final sounds = '${lib.path}/Sounds';
      Future<void> copyIos(String oldB, String newB, String? ext) async {
        if (ext == null || ext.isEmpty) return;
        final oldF = File('$sounds/$oldB.$ext');
        final newF = File('$sounds/$newB.$ext');
        if (await newF.exists()) return;
        if (await oldF.exists()) await oldF.copy(newF.path);
      }

      await copyIos(
        _legacyFajrBase,
        _slotBase(0),
        PrayerReminderPrefs.userSoundExtForSlot(p, 0),
      );
      await copyIos(
        _legacyImsakBase,
        _slotBase(1),
        PrayerReminderPrefs.userSoundExtForSlot(p, 1),
      );
    }

    await p.setBool('prayer_reminder_ntf_slot_files_copied_v1', true);
  }

  static Future<String?> absolutePathForSlot(
    SharedPreferences p,
    int slot,
  ) async {
    assert(slot >= 0 && slot < PrayerReminderPrefs.slotCount);
    final ext = PrayerReminderPrefs.userSoundExtForSlot(p, slot);
    if (ext == null || ext.isEmpty) return null;
    final dir = await _slotStorageDirectory();
    final f = File('${dir.path}/${_slotBase(slot)}.$ext');
    if (!await f.exists()) {
      final legacyDir = await getApplicationDocumentsDirectory();
      final legacy = File('${legacyDir.path}/${_slotBase(slot)}.$ext');
      if (!await legacy.exists()) return null;
      await legacy.copy(f.path);
    }
    return f.path;
  }

  static String? iosBundledSoundFileNameForSlot(SharedPreferences p, int slot) {
    final e = PrayerReminderPrefs.userSoundExtForSlot(p, slot);
    if (e == null || e.isEmpty) return null;
    if (!kIsWeb &&
        Platform.isIOS &&
        !_kIosNotificationAudioExtensions.contains(e.toLowerCase())) {
      return null;
    }
    return '${_slotBase(slot)}.$e';
  }

  static Future<bool> importForSlot(SharedPreferences p, int slot) async {
    assert(slot >= 0 && slot < PrayerReminderPrefs.slotCount);
    try {
      final ext = await _pickAndCopy(slot: slot);
      if (ext == null) return false;
      await PrayerReminderPrefs.bumpUserSoundChannelForSlot(p, slot);
      await PrayerReminderPrefs.setUserSoundExtForSlot(p, slot, ext);
      return true;
    } catch (e, st) {
      debugPrint('Prayer user sound import slot $slot failed: $e');
      debugPrint('$st');
      return false;
    }
  }

  static Future<bool> importForAllSlots(SharedPreferences p) async {
    if (kIsWeb) return false;
    try {
      final r = await _pickFilesWithFallback();
      if (r == null || r.files.isEmpty) return false;
      final picked = r.files.single;

      for (var slot = 0; slot < PrayerReminderPrefs.slotCount; slot++) {
        final ext = await _copyPickedFileToSlot(picked, slot: slot);
        if (ext == null) return false;
        await PrayerReminderPrefs.bumpUserSoundChannelForSlot(p, slot);
        await PrayerReminderPrefs.setUserSoundExtForSlot(p, slot, ext);
      }
      return true;
    } catch (e, st) {
      debugPrint('Prayer user sound import all failed: $e');
      debugPrint('$st');
      return false;
    }
  }

  static Future<void> clearForSlot(SharedPreferences p, int slot) async {
    assert(slot >= 0 && slot < PrayerReminderPrefs.slotCount);
    final ext = PrayerReminderPrefs.userSoundExtForSlot(p, slot);
    await PrayerReminderPrefs.clearUserSoundSlot(p, slot);
    if (ext == null) return;
    await _deleteStoredFiles(base: _slotBase(slot), ext: ext);
  }

  static Future<void> _deleteStoredFiles({
    required String base,
    required String ext,
  }) async {
    if (kIsWeb) return;
    final dir = await _slotStorageDirectory();
    final f = File('${dir.path}/$base.$ext');
    if (await f.exists()) await f.delete();
    if (Platform.isAndroid) {
      final legacyDir = await getApplicationDocumentsDirectory();
      final legacyF = File('${legacyDir.path}/$base.$ext');
      if (await legacyF.exists()) await legacyF.delete();
    }
    if (Platform.isIOS) {
      final lib = await getLibraryDirectory();
      final iosF = File('${lib.path}/Sounds/$base.$ext');
      if (await iosF.exists()) await iosF.delete();
    }
  }

  static Future<String?> _pickAndCopy({required int slot}) async {
    if (kIsWeb) return null;
    final r = await _pickFilesWithFallback();
    if (r == null || r.files.isEmpty) return null;
    return _copyPickedFileToSlot(r.files.single, slot: slot);
  }

  static Future<String?> _copyPickedFileToSlot(
    PlatformFile picked, {
    required int slot,
  }) async {
    final path = picked.path;

    Uint8List? bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (path != null && path.isNotEmpty) {
        final src = File(path);
        if (await src.exists()) {
          bytes = await src.readAsBytes();
        }
      }
    }
    if (bytes == null || bytes.isEmpty) return null;

    var ext = picked.extension?.toLowerCase() ?? '';
    if (ext.startsWith('.')) ext = ext.substring(1);
    if (ext.isEmpty && path != null && path.isNotEmpty) {
      final i = path.lastIndexOf('.');
      ext = i >= 0 ? path.substring(i + 1).toLowerCase() : '';
    }
    if (ext.isEmpty) {
      final n = picked.name;
      final i = n.lastIndexOf('.');
      ext = i >= 0 ? n.substring(i + 1).toLowerCase() : '';
    }
    if (ext.length > 8) ext = ext.substring(0, 8);
    if (!_isAllowedAudioExt(ext)) return null;

    final base = _slotBase(slot);
    final dir = await _slotStorageDirectory();
    final dest = File('${dir.path}/$base.$ext');
    await dest.writeAsBytes(bytes, flush: true);

    if (Platform.isIOS) {
      final lib = await getLibraryDirectory();
      final soundsDir = Directory('${lib.path}/Sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }
      final iosDest = File('${soundsDir.path}/$base.$ext');
      await iosDest.writeAsBytes(bytes, flush: true);
    }

    return ext;
  }
}
