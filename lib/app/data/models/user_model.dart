class UserModel {
  String uid;
  String email;
  String nom;
  String prenom;
  String telephone;
  String type;
  double solde;  // Changé de int à double
  double plafond;  // Changé de int à double

  UserModel({
    required this.uid,
    required this.email,
    this.nom = '',
    this.prenom = '',
    this.telephone = '',
    this.type = 'client',
    this.solde = 0.0,  // Initialisation avec 0.0
    this.plafond = 5000.0,  // Initialisation avec 5000.0
  });

  // Convertir UserModel en Map pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'type': type,
      'solde': solde,
      'plafond': plafond,
    };
  }

  // Créer UserModel à partir des données Firestore
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      type: json['type'] ?? 'client',
      solde: (json['solde'] ?? 0).toDouble(),  // Conversion explicite en double
      plafond: (json['plafond'] ?? 5000).toDouble(),  // Conversion explicite en double
    );
  }

  // Copier le modèle avec de nouvelles valeurs
  UserModel copyWith({
    String? uid,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? type,
    double? solde,  // Changé de int à double
    double? plafond,  // Changé de int à double
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      type: type ?? this.type,
      solde: solde ?? this.solde,
      plafond: plafond ?? this.plafond,
    );
  }
}