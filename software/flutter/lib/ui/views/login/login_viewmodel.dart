import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/auth_service.dart';

class LoginViewModel extends BaseViewModel {
  final _userService = locator<UserService>();
  final _navigationService = locator<NavigationService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginUser() async {
    setBusy(true);
    try {
      await _userService.loginUser(
          emailController.text, passwordController.text);
      _navigationService.replaceWithHomeView();
    } catch (e) {
      // Handle error
      print(e);
    } finally {
      setBusy(false);
    }
  }
}
