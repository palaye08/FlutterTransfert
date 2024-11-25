// import 'firebase_service.dart';
// import 'secure_storage_service.dart';

// class ApiService {
//   final FirebaseService _firebaseService;
//   final SecureStorageService _secureStorage;

//   ApiService(this._firebaseService, this._secureStorage);

//   Future<String> login(String email, String password) async {
//     // Vérifie l'utilisateur dans Firebase Auth
//     final user = await _firebaseService.loginWithEmailAndPassword(email, password);

//     if (user != null) {
//       // Récupère les données utilisateur depuis Firestore
//       final userData = await _firebaseService.getUserByEmail(email);
//       if (userData != null) {
//         final token = userData['token']; // Exemple : utilisez un champ `token`
//         await _secureStorage.storeAuthToken(token);
//         return token;
//       } else {
//         throw Exception('Utilisateur introuvable dans Firestore.');
//       }
//     } else {
//       throw Exception('Authentification échouée.');
//     }
//   }

//   Future<String?> getAuthToken() async {
//     return await _secureStorage.getAuthToken();
//   }
// }
