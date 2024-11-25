import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:getxcli/app/data/models/contacts_model.dart';
import 'package:getxcli/app/data/services/firebase_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getxcli/app/modules/home/controllers/home_controller.dart';

class TransfertController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final contacts = <ContactModel>[].obs;
  final isLoading = true.obs;
  final montantTransfert = 0.0.obs;
  final selectedContact = Rxn<ContactModel>();
  final searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController montantController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadContacts();
    debounce(
      searchQuery,
      (_) {
        filterContacts();
      },
      time: Duration(milliseconds: 500),
    );
  }

  Future<void> loadContacts() async {
    try {
      isLoading.value = true;
      
      // Vérifier la permission avec flutter_contacts
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        throw Exception('Permission de contacts non accordée');
      }

      // Charger les contacts avec flutter_contacts
      final deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Convertir les contacts en ContactModel
      contacts.value = deviceContacts
          .where((contact) => contact.phones.isNotEmpty)
          .map((contact) => ContactModel(
                id: contact.id,
                name: contact.displayName.isNotEmpty
                    ? contact.displayName
                    : 'Sans nom',
                phoneNumber:
                    contact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), ''),
              ))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les contacts: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterContacts() {
    if (searchQuery.value.isEmpty) {
      loadContacts();
      return;
    }

    final query = searchQuery.value.toLowerCase();
    contacts.value = contacts
        .where((contact) =>
            contact.name.toLowerCase().contains(query) ||
            contact.phoneNumber.contains(query))
        .toList();
  }

Future<void> effectuerTransfertVersContact(ContactModel contact, double montant) async {
  try {
    print('Type du montant: ${montant.runtimeType}'); // Vérifier le type
    print('Valeur du montant: $montant'); // Vérifier la valeur

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Nettoyer le numéro de téléphone (enlever les espaces et caractères non numériques)
    String phoneNumber = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Rechercher l'utilisateur avec ce numéro de téléphone
    final userQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('telephone', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (userQuerySnapshot.docs.isEmpty) {
      throw Exception('Aucun utilisateur trouvé avec ce numéro de téléphone');
    }

    // Récupérer l'ID du destinataire
    String receiverId = userQuerySnapshot.docs.first.id;
      // Rafraîchir la page d'accueil
    Get.find<HomeController>().refreshData();

    await _firebaseService.createTransaction(
      senderId: currentUser.uid,
      montant: montant,
      receiverId: receiverId,
      receiverPhone: contact.phoneNumber,
      type: 'transfert',
    );

   // Rafraîchir la page d'accueil
    Get.find<HomeController>().refreshData();
    
    Get.back();
    Get.snackbar(
      'Succès',
      'Transfert de ${montant.toStringAsFixed(0)} CFA envoyé à ${contact.name}',
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e, stackTrace) {
    print('Erreur complète: $e'); // Log de l'erreur
    print('Stack trace: $stackTrace'); // Log de la stack trace
    Get.snackbar(
      'Erreur',
      'Échec du transfert: ${e.toString()}',
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }
}
  @override
  void onClose() {
    searchController.dispose();
    montantController.dispose();
    super.onClose();
  }
}