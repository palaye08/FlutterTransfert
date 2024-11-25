import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlanifierController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observable variables
  final montant = ''.obs;
  final phoneNumber = ''.obs;
  final delayMinutes = 1.obs;
  final isLoading = false.obs;
  final error = ''.obs;
  
  // Current user info
  final currentUserId = ''.obs;
  final currentUserPhone = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentUserInfo();
  }

  Future<void> loadCurrentUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        currentUserId.value = user.uid;
        currentUserPhone.value = userDoc.data()?['telephone'] ?? '';
      }
    } catch (e) {
      error.value = 'Erreur lors du chargement des informations utilisateur';
    }
  }

  Future<String> _findUserIdByPhoneNumber(String phoneNumber) async {
    try {
      final userQuerySnapshot = await _firestore
          .collection('users')
          .where('telephone', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (userQuerySnapshot.docs.isEmpty) {
        throw Exception('Aucun utilisateur trouvé avec ce numéro de téléphone');
      }
      return userQuerySnapshot.docs.first.id;
    } catch (e) {
      print('Erreur lors de la recherche de l\'utilisateur: $e');
      rethrow;
    }
  }
Future<void> planifierTransaction() async {
  try {
    isLoading.value = true;
    error.value = '';
    
    // Validation des entrées
    if (montant.isEmpty || phoneNumber.isEmpty) {
      throw Exception('Veuillez remplir tous les champs');
    }

    // Log pour le débogage
    print('Début de la transaction planifiée');
    print('Montant: $montant');
    print('Téléphone: $phoneNumber');

    final receiverId = await _findUserIdByPhoneNumber(phoneNumber.value);
    print('ReceiverID trouvé: $receiverId');

    final body = {
      'montant': int.parse(montant.value),
      'receiverId': receiverId,
      'receiverPhone': phoneNumber.value,
      'senderId': currentUserId.value,
      'delay_minutes': delayMinutes.value
    };

    print('Envoi de la requête au serveur...');
    print('Corps de la requête: ${json.encode(body)}');

    // Tentative de connexion avec timeout
    final response = await http.post(
      Uri.parse('http://192.168.39.212:8000/api/planifier'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Ajoutez d'autres headers si nécessaire pour votre API
      },
      body: json.encode(body),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('La connexion au serveur a expiré');
      },
    );

    print('Réponse reçue du serveur');
    print('Status code: ${response.statusCode}');
    print('Corps de la réponse: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      Get.snackbar(
        'Succès',
        'Transaction planifiée avec succès pour ${responseData['execution_time']}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Get.back();
    } else if (response.statusCode == 404) {
      throw Exception('API endpoint non trouvé');
    } else if (response.statusCode == 500) {
      throw Exception('Erreur serveur interne');
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }

  } on SocketException catch (e) {
    print('Erreur de connexion socket: $e');
    error.value = 'Impossible de se connecter au serveur. Vérifiez votre connexion et l\'état du serveur.';
  } on TimeoutException catch (e) {
    print('Timeout: $e');
    error.value = 'La connexion au serveur a pris trop de temps.';
  } on FormatException catch (e) {
    print('Erreur de format: $e');
    error.value = 'Erreur de format dans la réponse du serveur.';
  } catch (e) {
    print('Erreur générale: $e');
    error.value = 'Une erreur est survenue: $e';
  } finally {
    isLoading.value = false;
    
    if (error.value.isNotEmpty) {
      Get.snackbar(
        'Erreur',
        error.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }
}
}