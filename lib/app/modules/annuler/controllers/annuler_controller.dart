import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart' as model;
import '../../../data/models/user_model.dart';

class AnnulerController extends GetxController {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final isLoading = true.obs;
  final cancelableTransactions = <model.Transaction>[].obs;
  final receiverInfoCache = <String, Rx<UserModel?>>{};

  @override
  void onInit() {
    super.onInit();
    loadCancelableTransactions();
  }
Future<void> loadCancelableTransactions() async {
  try {
    isLoading.value = true;
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      isLoading.value = false;
      return;
    }

    // Créer un timestamp pour il y a une heure
    final oneHourAgo = firestore.Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 1))
    );

    _firestore
        .collection('transactions')
        .where('senderId', isEqualTo: currentUser.uid)
        .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
        .where('status', isEqualTo: 'completed')  // Seulement les transactions non annulées
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            print('Nombre de transactions trouvées: ${snapshot.docs.length}');
            final transactions = snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  print('Transaction trouvée: $data');
                  return model.Transaction.fromFirestore(doc);
                })
                .where((transaction) {
                  // Vérifier si la transaction est toujours dans la fenêtre d'une heure
                  final transactionDate = DateTime.parse(transaction.date);
                  final now = DateTime.now();
                  final difference = now.difference(transactionDate);
                  return difference.inHours < 1;
                })
                .toList();
            cancelableTransactions.value = transactions;
            isLoading.value = false;
          },
          onError: (error) {
            print('Erreur dans le stream des transactions: $error');
            isLoading.value = false;
          },
        );
  } catch (e) {
    print('Erreur lors du chargement des transactions: $e');
    isLoading.value = false;
  }
}

  Rx<UserModel?> getReceiverInfo(String receiverId) {
    if (!receiverInfoCache.containsKey(receiverId)) {
      receiverInfoCache[receiverId] = Rx<UserModel?>(null);
      loadReceiverInfo(receiverId);
    }
    return receiverInfoCache[receiverId]!;
  }

  Future<void> loadReceiverInfo(String receiverId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(receiverId).get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        userData['uid'] = docSnapshot.id;
        receiverInfoCache[receiverId]?.value = UserModel.fromJson(userData);
      }
    } catch (e) {
      print('Erreur lors du chargement des informations du destinataire: $e');
    }
  }

  String formatTransactionTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double getRemainingTimePercentage(String dateStr) {
    final transactionDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final expiryDate = transactionDate.add(const Duration(hours: 1));
    
    if (now.isAfter(expiryDate)) return 0;
    
    final totalDuration = const Duration(hours: 1).inSeconds;
    final remainingDuration = expiryDate.difference(now).inSeconds;
    
    return remainingDuration / totalDuration;
  }

  String getRemainingTimeText(String dateStr) {
    final transactionDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final expiryDate = transactionDate.add(const Duration(hours: 1));
    
    final remaining = expiryDate.difference(now);
    if (remaining.isNegative) return "Délai expiré";
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '$minutes min $seconds sec';
  }

  bool isTransactionCancelable(String dateStr) {
    final transactionDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(transactionDate);
    return difference.inHours < 1;
  }

  void showCancelConfirmation(model.Transaction transaction) {
    if (!isTransactionCancelable(transaction.date)) {
      Get.snackbar(
        'Impossible d\'annuler',
        'Le délai d\'une heure est dépassé pour cette transaction',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: Text('Confirmer l\'annulation'),
        content: Text(
          'Voulez-vous vraiment annuler ce transfert de ${transaction.montant.toStringAsFixed(0)} CFA ?'
          '\nLes frais de ${transaction.frais.toStringAsFixed(0)} CFA ne seront pas remboursés.'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              cancelTransaction(transaction);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
            ),
            child: Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

Future<void> cancelTransaction(model.Transaction transaction) async {
  try {
    await _firestore.runTransaction((txn) async {
      print('Début de la transaction d\'annulation');
      print('Recherche des documents...');

      // 1. Effectuer d'abord toutes les lectures
      final senderDoc = _firestore.collection('users').doc(transaction.senderId);
      final receiverDoc = _firestore.collection('users').doc(transaction.receiverId);

      // Rechercher la transaction avec plusieurs critères pour être plus précis
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('senderId', isEqualTo: transaction.senderId)
          .where('receiverId', isEqualTo: transaction.receiverId)
          .where('montant', isEqualTo: transaction.montant)
          .where('status', isEqualTo: 'completed')
          .get();

      // Filtrer pour trouver la transaction exacte
      final matchingDoc = transactionsQuery.docs.firstWhere(
        (doc) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final transactionDate = DateTime.parse(transaction.date);

          // Comparer les timestamps avec une tolérance de quelques secondes
          final difference = timestamp.difference(transactionDate).inSeconds.abs();
          return difference < 5; // Tolérance de 5 secondes
        },
        orElse: () => throw Exception('Transaction non trouvée'),
      );

      final transactionDoc = matchingDoc.reference;

      print('Documents à traiter:');
      print('- Transaction ID: ${matchingDoc.id}');
      print('- Sender ID: ${transaction.senderId}');
      print('- Receiver ID: ${transaction.receiverId}');

      final senderSnapshot = await txn.get(senderDoc);
      final receiverSnapshot = await txn.get(receiverDoc);
      final transactionSnapshot = await txn.get(transactionDoc);

      // Vérifications
      if (!senderSnapshot.exists) {
        throw Exception('Document de l\'expéditeur non trouvé: ${transaction.senderId}');
      }
      if (!receiverSnapshot.exists) {
        throw Exception('Document du destinataire non trouvé: ${transaction.receiverId}');
      }
      if (!transactionSnapshot.exists) {
        throw Exception('Document de transaction non trouvé dans la transaction');
      }

      // Extraire les données
      final senderData = senderSnapshot.data() as Map<String, dynamic>;
      final receiverData = receiverSnapshot.data() as Map<String, dynamic>;

      final senderCurrentBalance = (senderData['solde'] as num).toDouble();
      final receiverCurrentBalance = (receiverData['solde'] as num).toDouble();

      print('Mise à jour des soldes:');
      print('- Ancien solde expéditeur: $senderCurrentBalance');
      print('- Ancien solde destinataire: $receiverCurrentBalance');
      print('- Montant à annuler: ${transaction.montant}');

      // 2. Effectuer les écritures
      txn.update(senderDoc, {
        'solde': senderCurrentBalance + transaction.montant
      });

      txn.update(receiverDoc, {
        'solde': receiverCurrentBalance - transaction.montant
      });

     print('Suppression du document de la transaction...');
      txn.delete(transactionDoc);

      // 4. Mettre à jour la liste locale immédiatement
      cancelableTransactions.value = cancelableTransactions
          .where((t) => t.date != transaction.date)
          .toList();

      print('Mise à jour et suppression effectuées avec succès');
    });

    Get.snackbar(
      'Succès',
      'Transfert annulé avec succès et supprimé',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e) {
    print('Erreur détaillée lors de l\'annulation de la transaction: $e');
    String messageErreur = 'Impossible d\'annuler le transfert';

    if (e.toString().contains('expéditeur non trouvé')) {
      messageErreur = 'Compte expéditeur non trouvé';
    } else if (e.toString().contains('destinataire non trouvé')) {
      messageErreur = 'Compte destinataire non trouvé';
    } else if (e.toString().contains('Transaction non trouvée')) {
      messageErreur = 'Transaction non trouvée';
    }

    Get.snackbar(
      'Erreur',
      messageErreur,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
}


   }