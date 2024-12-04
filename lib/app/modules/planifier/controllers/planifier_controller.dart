import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PlanifierController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observable variables
  final montant = ''.obs;
  final phoneNumber = ''.obs;
  final delayMinutes = 1.obs;
  final isLoading = false.obs;
  final error = ''.obs;
  
  // Frequency-related observables
  final frequency = 'minutes'.obs;
  final frequencyValue = 1.obs;
  final startDate = DateTime.now().obs;

  // Transaction details after successful planning
  final transactionDetails = Rx<Map<String, dynamic>?>(null);

  // Available frequency options
  final frequencyOptions = ['minutes', 'daily', 'weekly', 'monthly'];
  
  // Current user info
  final currentUserId = ''.obs;
  final currentUserPhone = ''.obs;

  // Local server configuration
  static const String _serverBaseUrl = 'http://192.168.1.124:8000/api';

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
      transactionDetails.value = null;
      
      // Validation des entrées
      if (montant.isEmpty || phoneNumber.isEmpty) {
        throw Exception('Veuillez remplir tous les champs');
      }

      final receiverId = await _findUserIdByPhoneNumber(phoneNumber.value);

      final body = {
        'montant': int.parse(montant.value),
        'receiverId': receiverId,
        'receiverPhone': phoneNumber.value,
        'senderId': currentUserId.value,
        'frequency': frequency.value,
        'frequencyValue': frequencyValue.value,
        'startDate': startDate.value.toIso8601String().split('T')[0]
      };

      final response = await http.post(
        Uri.parse('$_serverBaseUrl/planifier'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La connexion au serveur a expiré');
        },
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // Store transaction details
        transactionDetails.value = responseData['transaction_details'];

        // Show detailed success dialog
        _showTransactionDetailsDialog(responseData);
          // Show success snackbar
        Get.snackbar(
          'Succès', 
          'Transfert planifié effectué avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );


        Get.back(); // Optionally close the current screen
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }

    } on SocketException catch (e) {
      error.value = 'Impossible de se connecter au serveur. Vérifiez votre connexion et l\'état du serveur.';
    } on TimeoutException catch (e) {
      error.value = 'La connexion au serveur a pris trop de temps.';
    } on FormatException catch (e) {
      error.value = 'Erreur de format dans la réponse du serveur.';
    } catch (e) {
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

  void _showTransactionDetailsDialog(Map<String, dynamic> responseData) {
    final details = responseData['transaction_details'];
    final executionTime = responseData['execution_time'];

    Get.dialog(
      AlertDialog(
        title: Text('Transaction Planifiée', style: TextStyle(color: Colors.blue[800])),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              _buildDetailRow('Montant', '${details['montant']} CFA'),
              _buildDetailRow('Destinataire', details['receiverPhone']),
              _buildDetailRow('Fréquence', 
                '${details['frequency']} (tous les ${details['frequencyValue']})'),
              _buildDetailRow('Première exécution', 
                _formatDateTime(details['timestamp'])),
              _buildDetailRow('Type', details['type']),
              _buildDetailRow('Statut', details['status']),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: Colors.blue[800])),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      // Parse the input date string
      final DateTime parsedDate = DateTime.parse(dateTimeString);
      
      // Format the date in a more readable format
      return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
    } catch (e) {
      return dateTimeString; // Return original string if parsing fails
    }
  }
}