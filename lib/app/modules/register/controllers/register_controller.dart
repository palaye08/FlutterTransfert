import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/app/data/services/firebase_service.dart';
import '/app/data/models/user_model.dart';
import '/app/routes/app_pages.dart';

class RegisterController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Variables observables
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  // Clé du formulaire
  final formKey = GlobalKey<FormState>();

  // Controllers pour les champs de texte
  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController telephoneController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  get register => null;

  @override
  void onInit() {
    super.onInit();
    nomController = TextEditingController();
    prenomController = TextEditingController();
    telephoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void onClose() {
    nomController.dispose();
    prenomController.dispose();
    telephoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

 /*  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Erreur',
        'Les mots de passe ne correspondent pas',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    try {
      isLoading.value = true;
      final telephone = telephoneController.text.trim();
      final password = passwordController.text;
      final nom = nomController.text.trim();
      final prenom = prenomController.text.trim();

      if (telephone.isEmpty || password.isEmpty || nom.isEmpty || prenom.isEmpty) {
        throw 'Veuillez remplir tous les champs';
      }

      // Créer le modèle utilisateur
      final userModel = UserModel(
        uid: '', // Sera rempli après l'enregistrement
        email: '$telephone@fakeemail.com', // Email fictif basé sur le téléphone
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        type: 'client', // Type par défaut
      );

      // Enregistrer l'utilisateur
      await _firebaseService.registerWithPhoneAndPassword(
        telephone: telephone,
        password: password,
        userModel: userModel,
      );

      Get.snackbar(
        'Succès',
        'Compte créé avec succès !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );

      // Rediriger vers la page de connexion
      Get.offNamed(Routes.LOGIN);

    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    } finally {
      isLoading.value = false;
    }
  } */

  // Validateurs
  String? validateNom(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nom';
    }
    if (value.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? validatePrenom(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre prénom';
    }
    if (value.length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? validateTelephone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Veuillez entrer un numéro de téléphone valide';
    }
    if (value.length != 8) {
      return 'Le numéro doit contenir 8 chiffres';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }
}