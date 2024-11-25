import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DistributorController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final user = Rxn<Map<String, dynamic>>();
  final isBalanceVisible = true.obs;
  final userDocumentId = ''.obs;
  final transactions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    loadTransactions();
  }

  Future<void> loadUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        userDocumentId.value = currentUser.uid;
        final doc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          user.value = doc.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> loadTransactions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final querySnapshot = await _firestore
            .collection('transactions')
            .where('distributorId', isEqualTo: userId)
            .orderBy('date', descending: true)
            .get();

        transactions.value = querySnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
      }
    } catch (e) {
      print('Erreur lors du chargement des transactions: $e');
    }
  }

 Future makeDeposit(String clientId, double amount) async {
  try {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null) throw Exception('Utilisateur non connecté.');

    // Appeler le service pour créer une transaction
    await _firestore.collection('transactions').add({
      'senderId': senderId,
      'receiverId': clientId,
      'montant': amount,
      'type': 'depot',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'completed',
    });

    // Mettre à jour les soldes
    await _firestore.runTransaction((transaction) async {
      final senderDoc = _firestore.collection('users').doc(senderId);
      final receiverDoc = _firestore.collection('users').doc(clientId);

      final senderSnapshot = await transaction.get(senderDoc);
      final receiverSnapshot = await transaction.get(receiverDoc);

      if (!senderSnapshot.exists || !receiverSnapshot.exists) {
        throw Exception('Utilisateur introuvable.');
      }

      final double senderBalance = (senderSnapshot.data()?['solde'] ?? 0).toDouble();
      final double receiverBalance = (receiverSnapshot.data()?['solde'] ?? 0).toDouble();

      if (senderBalance < amount) {
        throw Exception('Solde insuffisant.');
      }

      transaction.update(senderDoc, {'solde': senderBalance - amount});
      transaction.update(receiverDoc, {'solde': receiverBalance + amount});
    });

    Get.snackbar('Succès', 'Dépôt effectué avec succès.');
    loadTransactions();
  } catch (e) {
    print('Erreur lors du dépôt: $e');
    Get.snackbar('Erreur', 'Échec du dépôt.');
  }
}


  Future<void> makeWithdrawal(String clientId, double amount) async {
    // Implémenter la logique de retrait
  }

  Future<void> cancelTransaction(String transactionId) async {
    // Implémenter la logique d'annulation
  }

  void signOut() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}