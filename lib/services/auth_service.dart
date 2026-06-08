import '../models/user_model.dart';

class AuthService {
  static UserModel? currentUser;

  static bool login(String customerNumber, String password) {
    final user = UserModel.authenticate(customerNumber, password);
    if (user != null) {
      currentUser = user;
      return true;
    }
    return false;
  }

  static void logout() {
    currentUser = null;
  }
}