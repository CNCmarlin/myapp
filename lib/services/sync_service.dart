import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'google_drive_service.dart';

class SyncService {
  final LocalStorageService _storageService;
  final GoogleDriveService _driveService;
  bool _isSyncing = false;

  SyncService({
    required LocalStorageService storageService,
    required GoogleDriveService driveService,
  })  : _storageService = storageService,
        _driveService = driveService;

  // 🛡️ SHIELD: Background Backup Orchestrator
  // This method is designed to be called "Fire-and-Forget" from Providers.
  Future<void> performBackup() async {
    if (_isSyncing) return; // Prevent concurrent sync overlaps
    _isSyncing = true;

    try {
      if (kDebugMode) debugPrint('[Sync] Starting background backup to Google Drive...');

      // 1. Create a thread-safe snapshot of the active Isar database
      final backupPath = await _storageService.createBackupCopy();

      // 2. Upload the snapshot to the private AppData folder
      await _driveService.uploadBackup(backupPath);

      if (kDebugMode) debugPrint('[Sync] Backup completed successfully.');
    } catch (e) {
      // Micro-Heal: Silently log errors to avoid interrupting user workflow
      debugPrint('[Sync] Backup failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
}