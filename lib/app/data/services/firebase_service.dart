import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '/app/data/models/user_model.dart';
import '/app/data/models/transaction_model.dart' as app_transaction;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );
  final logger = Logger();

  // Connexion avec email et mot de passe
  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erreur de connexion : ${e.toString()}');
    }
  }

 Future<void> createTransaction({
    required String senderId,
    required double montant,  // Assurez-vous que c'est bien déclaré comme double
    required String receiverId,
    required String receiverPhone,
    required String type,
  }) async {
    try {
      // Créer la transaction
      final transactionData = {
        'senderId': senderId,
        'montant': montant.toDouble(), // Conversion explicite en double
        'receiverId': receiverId,
        'receiverPhone': receiverPhone,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      };

      // Obtenir les soldes actuels
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();

      double senderBalance = (senderDoc.data()?['solde'] ?? 0).toDouble();
      double receiverBalance = (receiverDoc.data()?['solde'] ?? 0).toDouble();

      // Vérifier si le solde est suffisant
      if (senderBalance < montant) {
        throw Exception('Solde insuffisant');
      }

      // Utiliser une transaction Firebase pour garantir l'atomicité
      await _firestore.runTransaction((transaction) async {
        // Mettre à jour le solde de l'expéditeur
        transaction.update(
          _firestore.collection('users').doc(senderId),
          {'solde': (senderBalance - montant).toDouble()}
        );

        // Mettre à jour le solde du destinataire
        transaction.update(
          _firestore.collection('users').doc(receiverId),
          {'solde': (receiverBalance + montant).toDouble()}
        );

        // Créer l'enregistrement de la transaction
        transaction.set(
          _firestore.collection('transactions').doc(),
          transactionData
        );
      });
    } catch (e) {
      print('Erreur dans createTransaction: $e');
      throw e;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        Get.snackbar("Connexion", "Connexion Echouée");
        return false;
      }

      final DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        
        String nom = googleUser.displayName ?? "Unknown";
        List<String> nameParts = nom.split(' ');
        String prenom = nameParts.isNotEmpty ? nameParts.first : '';
        nom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : nom;

        final UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          email: googleUser.email ?? '',
          nom: nom,
          prenom: prenom,
          telephone: googleUser.id ?? '',
          type: 'client'
        );

        await _firestore
            .collection("users")
            .doc(userModel.uid)
            .set(userModel.toJson());
      }

      logger.i("Connexion réussie");
      return true;
    } catch (e) {
      logger.e("Erreur lors de la connexion avec Google: $e");
      Get.snackbar('Erreur de connexion', "Une erreur s'est produite lors de la connexion Google");
      return false;
    }
  }

 Future<UserModel> getUserData(String uid) async {
    try {
      final userData = await _firestore.collection('users').doc(uid).get();
      if (userData.exists) {
        final data = userData.data()!;
        
        // Assurer que les valeurs numériques sont converties en double
        if (data['solde'] != null) {
          data['solde'] = (data['solde'] is int) 
              ? (data['solde'] as int).toDouble() 
              : data['solde'];
        }
        
        if (data['plafond'] != null) {
          data['plafond'] = (data['plafond'] is int) 
              ? (data['plafond'] as int).toDouble() 
              : data['plafond'];
        }
        
        return UserModel.fromJson(data);
      } else {
        throw Exception('Utilisateur non trouvé');
      }
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      throw Exception('Erreur lors de la récupération des données : $e');
    }
  }

  // Mettre à jour le solde utilisateur
  Future<void> updateUserBalance(String uid, double newBalance) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'solde': newBalance,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour du solde: $e');
      throw Exception('Erreur lors de la mise à jour du solde : $e');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Vérifier si l'utilisateur est connecté
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Obtenir l'utilisateur courant
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}

extension on GoogleSignInAccount {
  get phoneNumber => null;
}