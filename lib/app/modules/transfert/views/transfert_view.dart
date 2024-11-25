import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getxcli/app/data/models/contacts_model.dart';
import '../controllers/transfert_controller.dart';

class TransfertView extends GetView<TransfertController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfert à un contact'),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Liste des contacts
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.contacts.isEmpty) {
                return Center(
                  child: Text('Aucun contact trouvé'),
                );
              }

              return ListView.builder(
                itemCount: controller.contacts.length,
                itemBuilder: (context, index) {
                  final contact = controller.contacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(contact.name[0].toUpperCase()),
                      backgroundColor: Colors.blue[800],
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    onTap: () => _showTransferDialog(context, contact),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

 void _showTransferDialog(BuildContext context, ContactModel contact) {
  controller.montantController.clear();
  Get.dialog(
    AlertDialog(
      title: Text('Transfert à ${contact.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.montantController,
            keyboardType: TextInputType.numberWithOptions(decimal: true), // Permettre les décimaux
            decoration: InputDecoration(
              labelText: 'Montant (CFA)',
              border: OutlineInputBorder(),
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
          onPressed: () {
            // Convertir explicitement en double et remplacer la virgule par un point
            final montant = double.tryParse(
              controller.montantController.text.replaceAll(',', '.')
            );
            if (montant != null && montant > 0) {
              controller.effectuerTransfertVersContact(contact, montant);
            } else {
              Get.snackbar('Erreur', 'Montant invalide');
            }
          },
          child: Text('Envoyer'),
        ),
      ],
    ),
  );
}
}
