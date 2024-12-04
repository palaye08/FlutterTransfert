import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/firebase_service.dart';
import 'package:flutter/material.dart';

class HomeController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final user = Rx<UserModel?>(null);
  final transactions = <Transaction>[].obs;
  final userDocumentId = ''.obs;
  final isBalanceVisible = true.obs;
  final _usersInfo = <String, Rx<UserModel>>{}.obs;

  final isDistributeur = false.obs;

  // Streams pour les mises à jour en temps réel
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;

  @override
  void onInit() {
    super.onInit();
    setupRealtimeUpdates();
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.onClose();
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

  Future<void> effectuerDepot({
    required double montant,
    required String phoneNumber,
  }) async {
    if (!isDistributeur.value) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Rechercher l'ID du destinataire par son numéro de téléphone
      final receiverId = await _findUserIdByPhoneNumber(phoneNumber);
 

      await _firebaseService.createTransaction(
        senderId: currentUser.uid,
        montant: montant,
        receiverId: receiverId, // Utiliser l'ID trouvé
        receiverPhone: phoneNumber,
        type: 'depot',
      );
    } catch (e) {
      print('Erreur lors du dépôt: $e');
      rethrow;
    }
    Get.find<HomeController>().refreshData();
  }

  Future<void> effectuerRetrait({
    required double montant,
    required String phoneNumber,
  }) async {
    if (!isDistributeur.value) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Rechercher l'ID du destinataire par son numéro de téléphone
      final receiverId = await _findUserIdByPhoneNumber(phoneNumber);
      await _firebaseService.createTransaction(
        senderId: receiverId,
        montant: montant, // Montant négatif pour un retrait
        receiverId:currentUser.uid , // Utiliser l'ID trouvé
        receiverPhone: phoneNumber,
        type: 'retrait',
      );
    } catch (e) {
      print('Erreur lors du retrait: $e');
      rethrow;
    }
    Get.find<HomeController>().refreshData();

  }

  void setupRealtimeUpdates() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Écouter les changements des données utilisateur
      _userSubscription = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          userDocumentId.value = docSnapshot.id;
          final userData = docSnapshot.data()!;
          user.value = UserModel.fromJson(userData);
          // Mettre à jour le statut distributeur
          isDistributeur.value = userData['type'] == 'distributeur';
        }
      }, onError: (error) {
        print('Erreur lors de l\'écoute des données utilisateur: $error');
      });

      _setupTransactionsListener(currentUser.uid);
    }
  }

 void _setupTransactionsListener(String userId) {
  _transactionsSubscription = _firestore
      .collection('transactions')
      .where(Filter.or(
        Filter('senderId', isEqualTo: userId),
        Filter('receiverId', isEqualTo: userId),
      ))
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((querySnapshot) {
        transactions.value = querySnapshot.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Tri supplémentaire côté client
        
        _loadRelatedUsersInfo(userId);
  });
}


  void _loadRelatedUsersInfo(String currentUserId) {
    for (var transaction in transactions) {
      if (transaction.senderId != currentUserId) {
        getUserInfo(transaction.senderId);
      }
      if (transaction.receiverId != currentUserId) {
        getUserInfo(transaction.receiverId);
      }
    }
  }

  UserModel? getUserInfo(String userId) {
    if (!_usersInfo.containsKey(userId)) {
      _loadUserInfo(userId);
      return null;
    }
    return _usersInfo[userId]?.value;
  }

  Future<void> _loadUserInfo(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        _usersInfo[userId] = Rx<UserModel>(UserModel.fromJson(userData));
      }
    } catch (e) {
      print('Erreur lors du chargement des informations utilisateur: $e');
    }
  }

  Future<void> refreshData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Rafraîchir les données utilisateur
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          userDocumentId.value = userDoc.id;
          user.value = UserModel.fromJson(userDoc.data()!);
        }

        // Rafraîchir les transactions
        final transactionsQuery = await _firestore
            .collection('transactions')
            .where(Filter.or(
              Filter('senderId', isEqualTo: currentUser.uid),
              Filter('receiverId', isEqualTo: currentUser.uid),
            ))
            .get();

        transactions.value = transactionsQuery.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Rafraîchir les informations des utilisateurs
        for (var transaction in transactions) {
          if (transaction.senderId != currentUser.uid) {
            await _loadUserInfo(transaction.senderId);
          }
          if (transaction.receiverId != currentUser.uid) {
            await _loadUserInfo(transaction.receiverId);
          }
        }
      } catch (e) {
        print('Erreur lors du rafraîchissement des données: $e');
      }
    }
  }

  void toggleBalanceVisibility() {
    isBalanceVisible.value = !isBalanceVisible.value;
  }

  Future<void> signOut() async {
    _userSubscription?.cancel();
    _transactionsSubscription?.cancel();
    await _firebaseService.signOut();
    Get.offAllNamed('/login');
  }
}
class Transaction {
  final String senderId;
  final String receiverId;
  final double montant;
  final String date;
  final String type;

  Transaction({
    required this.senderId,
    required this.receiverId,
    required this.montant,
    required this.date,
    required this.type,
  });

  DateTime get dateTime => DateTime.parse(date);

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    String formattedDate = '';
    if (data['timestamp'] != null) {
      if (data['timestamp'] is Timestamp) {
        formattedDate = (data['timestamp'] as Timestamp).toDate().toIso8601String();
      } else {
        formattedDate = data['timestamp'].toString();
      }
    } else {
      formattedDate = DateTime.now().toIso8601String();
    }

    return Transaction(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      montant: (data['montant'] is num ? (data['montant'] as num).toDouble() : 0.0),
      date: formattedDate,
      type: data['type'] ?? 'transfert',
    );
  }
}

