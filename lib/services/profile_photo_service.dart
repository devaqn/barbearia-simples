import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';

class ProfilePhotoService {
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _db;

  ProfilePhotoService(this._db);

  Future<String?> pickFromCamera() async {
    final xf = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    return xf?.path;
  }

  Future<String?> pickFromGallery() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    return xf?.path;
  }

  Future<void> updateUserPhoto(int userId, String path) async {
    await _db.update('usuarios', {'foto_url': path}, userId);
  }
}
