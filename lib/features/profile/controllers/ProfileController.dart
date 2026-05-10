import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/user_model.dart';
import '../../../features/auth/controllers/AuthController.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();
  var currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  void _loadUser() {
    final raw = _storage.read<Map>('user');
    if (raw != null) {
      currentUser.value = UserModel.fromJson(Map<String, dynamic>.from(raw));
    }
  }

  Future<void> logout() async {
    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().logout();
    } else {
      _storage.remove('access_token');
      _storage.remove('user');
      Get.offAllNamed('/login');
    }
  }
}
