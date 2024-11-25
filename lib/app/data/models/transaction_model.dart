import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String senderId;
  final String receiverId;
  final double montant;
  final String date;
  final String etat;
  final double frais;
  final String type;
  final String id; // Ajout de l'ID du document

  Transaction({
    required this.senderId,
    required this.receiverId,
    required this.montant,
    required this.date,
    required this.etat,
    required this.frais,
    required this.type,
    required this.id, // ID requis dans le constructeur
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Transaction(
      id: doc.id, // Utilisation de l'ID du document Firestore
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? 'DEFAULT_RECEIVER_ID',
      montant: (data['montant'] is num ? (data['montant'] as num).toDouble() : 0.0),
      date: data['timestamp']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
      etat: data['status'] ?? 'en cours', // Changé de 'etat' à 'status' pour correspondre à votre code
      frais: (data['frais'] is num ? (data['frais'] as num).toDouble() : 0.0),
      type: data['type'] ?? 'transfert',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'montant': montant.toDouble(),
      'timestamp': date, // Changé de 'date' à 'timestamp' pour correspondre à votre code
      'status': etat, // Changé de 'etat' à 'status'
      'frais': frais.toDouble(),
      'type': type,
    };
  }
}