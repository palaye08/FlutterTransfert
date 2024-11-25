import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            _buildQuickActions(),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${controller.user.value?.prenom ?? 'Utilisateur'}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  Text(
                    'Bon retour !',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue[800]),
            onPressed: () => controller.signOut(),
          ),
        ],
      ),
    );
  }
Widget _buildBalanceCard() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: EdgeInsets.all(16), // Réduit le padding pour plus d'espace
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue[600]!, Colors.blue[400]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Section gauche : Solde total et visibilité
        Expanded(
          flex: 2, // Donne plus d'espace à la section du solde
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Minimise la hauteur
            children: [
              Text(
                'Solde Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16, // Légèrement réduit
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 8),
              Obx(() => Row(
                children: [
                  Flexible( // Permet au texte de se réduire si nécessaire
                    child: Text(
                      controller.isBalanceVisible.value
                          ? '${controller.user.value?.solde.toStringAsFixed(0) ?? '0.00'} CFA'
                          : '**** CFA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28, // Légèrement réduit
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Gère le débordement du texte
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero, // Réduit le padding du bouton
                    constraints: BoxConstraints(), // Minimise les contraintes
                    icon: Icon(
                      controller.isBalanceVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                      size: 20, // Taille d'icône réduite
                    ),
                    onPressed: () {
                      controller.isBalanceVisible.value = !controller.isBalanceVisible.value;
                    },
                  ),
                ],
              )),
            ],
          ),
        ),
        SizedBox(width: 8), // Espacement entre les sections
        // Section droite : QR Code
        Expanded(
          flex: 1, // Moins d'espace pour le QR code
          child: Obx(() {
            final userId = controller.userDocumentId.value;
            return Container(
              padding: EdgeInsets.all(4), // Padding réduit
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AspectRatio(
                aspectRatio: 1, // Maintient le QR code carré
                child: QrImageView(
                  data: userId,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) => Center(
                    child: Text(
                      'Erreur QR',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );
}
Widget _buildQuickActions() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Réduit le padding horizontal
    child: Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Changed from spaceEvenly to spaceBetween
      children: [
        // Afficher les boutons Dépôt et Retrait pour les distributeurs
        if (controller.isDistributeur.value) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(
                icon: Icons.arrow_downward,
                label: 'Dépôt',
                onTap: () => _showDepotDialog(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(
                icon: Icons.arrow_upward,
                label: 'Retrait',
                onTap: () => _showRetraitDialog(),
              ),
            ),
          ),
        ] else ...[
          // Afficher le bouton Envoyer pour les utilisateurs normaux
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(
                icon: Icons.send,
                label: 'Envoyer',
                onTap: () => Get.toNamed('/transfert'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(
                icon: Icons.launch,
                label: 'Planifier',
                onTap: () => Get.toNamed('/planifier'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(
                icon: Icons.remove,
                label: 'Annuler',
                onTap: () => Get.toNamed('/annuler'),
              ),
            ),
          ),
        ],
      ],
    )),
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.blue[800],
      backgroundColor: Colors.blue[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Réduit le padding
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min, // Important pour minimiser la largeur
      mainAxisAlignment: MainAxisAlignment.center, // Centre le contenu
      children: [
        Icon(icon, size: 20), // Réduit la taille de l'icône
        SizedBox(width: 4), // Réduit l'espace entre l'icône et le texte
        Text(
          label,
          style: TextStyle(
            fontSize: 13, // Réduit la taille du texte
          ),
        ),
      ],
    ),
  );
}


// Dialogue pour le dépôt
void _showDepotDialog() {
  final montantController = TextEditingController();
  final phoneController = TextEditingController();
  
  Get.dialog(
    AlertDialog(
      title: Text('Effectuer un dépôt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: montantController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: 'CFA',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final montant = double.parse(montantController.text);
              await controller.effectuerDepot(
                montant: montant,
                phoneNumber: phoneController.text,
              );
              Get.back();
              Get.snackbar(
                'Succès',
                'Dépôt effectué avec succès',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            } catch (e) {
              Get.snackbar(
                'Erreur',
                'Erreur lors du dépôt: $e',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          },
          child: Text('Confirmer'),
        ),
      ],
    ),
  );
}

// Dialogue pour le retrait
void _showRetraitDialog() {
  final montantController = TextEditingController();
  final phoneController = TextEditingController();
  
  Get.dialog(
    AlertDialog(
      title: Text('Effectuer un retrait'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: montantController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: 'CFA',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final montant = double.parse(montantController.text);
              await controller.effectuerRetrait(
                montant: montant,
                phoneNumber: phoneController.text,
              );
              Get.back();
              Get.snackbar(
                'Succès',
                'Retrait effectué avec succès',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            } catch (e) {
              Get.snackbar(
                'Erreur',
                'Erreur lors du retrait: $e',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          },
          child: Text('Confirmer'),
        ),
      ],
    ),
  );
}
Widget _buildTransactionsList() {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernières Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (controller.transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aucune transaction disponible',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: controller.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = controller.transactions[index];
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                  final DateTime transactionDate = DateTime.parse(transaction.date);
                  final String formattedDate = _formatDate(transactionDate);

                  return Obx(() {
                    final otherUserId = transaction.senderId == currentUserId 
                        ? transaction.receiverId 
                        : transaction.senderId;
                    final otherUser = controller.getUserInfo(otherUserId);
                    String displayName = otherUser != null 
                        ? '${otherUser.prenom} ${otherUser.nom}'
                        : 'Chargement...';

                    // Déterminer le type d'affichage en fonction du type de transaction
                    IconData transactionIcon;
                    Color iconColor;
                    String titleText;
                    bool showAsPositive;

                    if (transaction.type == 'depot') {
                      if (transaction.receiverId == currentUserId) {
                        titleText = 'Dépôt reçu';
                        showAsPositive = true;
                        transactionIcon = Icons.arrow_downward;
                        iconColor = Colors.green;
                      } else {
                        titleText = 'Dépôt effectué';
                        showAsPositive = false;
                        transactionIcon = Icons.arrow_upward;
                        iconColor = Colors.red;
                      }
                    } else if (transaction.type == 'retrait') {
                      if (transaction.senderId == currentUserId) {
                        titleText = 'Retrait effectué';
                        showAsPositive = false;
                        transactionIcon = Icons.arrow_upward;
                        iconColor = Colors.red;
                      } else {
                        titleText = 'Retrait reçu';
                        showAsPositive = true;
                        transactionIcon = Icons.arrow_downward;
                        iconColor = Colors.green;
                      }
                    } else if (transaction.type == 'planifie') {
                      if (transaction.senderId == currentUserId) {
                        titleText = 'Transfert planifié envoyé';
                        showAsPositive = false;
                        transactionIcon = Icons.schedule;
                        iconColor = Colors.orange;
                      } else {
                        titleText = 'Transfert planifié reçu';
                        showAsPositive = true;
                        transactionIcon = Icons.schedule;
                        iconColor = Colors.orange;
                      }
                    } else {
                      // Transfert normal
                      if (transaction.senderId == currentUserId) {
                        titleText = 'Transfert envoyé';
                        showAsPositive = false;
                        transactionIcon = Icons.arrow_upward;
                        iconColor = Colors.red;
                      } else {
                        titleText = 'Transfert reçu';
                        showAsPositive = true;
                        transactionIcon = Icons.arrow_downward;
                        iconColor = Colors.green;
                      }
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.2),
                          child: Icon(
                            transactionIcon,
                            color: iconColor,
                          ),
                        ),
                        title: Text(
                          titleText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.senderId == currentUserId 
                                  ? 'Vers: $displayName' 
                                  : 'De: $displayName',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${showAsPositive ? '+' : '-'} ${transaction.montant.toStringAsFixed(2)} CFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: iconColor,
                          ),
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    ),
  );
}
String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inDays == 0) {
    // Aujourd'hui
    return "Aujourd'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  } else if (difference.inDays == 1) {
    // Hier
    return "Hier ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  } else if (difference.inDays < 7) {
    // Cette semaine
    final List<String> jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return "${jours[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  } else {
    // Plus ancien
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}


}
