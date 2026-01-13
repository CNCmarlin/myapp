import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path/path.dart' as path;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn;

  GoogleDriveService(this._googleSignIn);

  // Obtain the authenticated HTTP client from the existing Google Sign-In session
  Future<drive.DriveApi?> _getDriveApi() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  // 🛡️ SHIELD: Upload the Isar database snapshot to the private AppData folder
  Future<void> uploadBackup(String filePath) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    final file = File(filePath);
    final fileName = path.basename(file.path);
    
    // Query specifically for the AppData folder (hidden from the user's main Drive view)
    final query = "name = '$fileName' and 'appDataFolder' in parents";
    final fileList = await driveApi.files.list(q: query, spaces: 'appDataFolder');

    final driveFile = drive.File();
    driveFile.name = fileName;
    driveFile.parents = ['appDataFolder'];

    final media = drive.Media(file.openRead(), file.lengthSync());

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      // Micro-Heal: Update the existing backup file instead of creating duplicates
      final existingId = fileList.files!.first.id!;
      await driveApi.files.update(driveFile, existingId, uploadMedia: media);
    } else {
      // Create the backup for the first time
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }
}