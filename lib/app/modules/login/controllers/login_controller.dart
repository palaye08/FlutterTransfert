import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getxcli/app/routes/app_pages.dart';
import '/app/data/services/firebase_service.dart';

class LoginController extends GetxController {
  final telephoneController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final isButtonEnabled = false.obs; // Pour activer/désactiver le bouton
  final formKey = GlobalKey<FormState>();

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void onInit() {
    super.onInit();
    telephoneController.addListener(_checkFormValidity);
    passwordController.addListener(_checkFormValidity);
  }

  @override
  void onClose() {
    telephoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void _checkFormValidity() {
    isButtonEnabled.value = 
        telephoneController.text.isNotEmpty && passwordController.text.isNotEmpty;
  }

  String? validateTelephone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    return null;
  }

  Future<void> login() async {
    if (formKey.currentState?.validate() == true) {
      isLoading.value = true;
      try {
        await _firebaseService.loginWithEmailAndPassword(
          email: telephoneController.text,
          password: passwordController.text,
        );
        Get.offNamed(Routes.HOME);
      } catch (e) {
        Get.snackbar('Erreur', 'Échec de la connexion: ${e.toString()}');
      } finally {
        isLoading.value = false;
      }
    }
  }
 // Modification du login_controller.dart pour la redirection
/* Future loginWithGoogle() async {
  isLoading.value = true;
  try {
    await _firebaseService.loginWithGoogle();
    
    // Vérifier le type d'utilisateur
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['type'] != 'distributeur') {
          Get.offNamed(Routes.HOME);
        } else {
          Get.offNamed(Routes.DISTRIBUTEUR);
        }
      }
    }
  } catch (e) {
    Get.snackbar('Erreur', 'Échec de la connexion Google: ${e.toString()}');
  } finally {
    isLoading.value = false;
  }
} */

  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    try {
      await _firebaseService.loginWithGoogle();
      
      Get.offNamed(Routes.HOME);
    } catch (e) {
      Get.snackbar('Erreur', 'Échec de la connexion Google: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
