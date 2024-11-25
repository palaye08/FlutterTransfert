import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getxcli/app/modules/planifier/controllers/planifier_controller.dart';

class PlanifierView extends GetView<PlanifierController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planifier un transfert'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Text(
                'Entrez les informations pour planifier un transfert.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              // Montant Input Field
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.money, color: Colors.blue[800]),
                  suffix: Text('CFA'),
                ),
                onChanged: (value) => controller.montant.value = value,
              ),
              SizedBox(height: 16),
              // Numéro de Téléphone Input Field
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone du destinataire',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.phone, color: Colors.blue[800]),
                ),
                onChanged: (value) => controller.phoneNumber.value = value,
              ),
              SizedBox(height: 16),
              // Dropdown for Délai d'exécution
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Délai d\'exécution',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.timer, color: Colors.blue[800]),
                ),
                value: controller.delayMinutes.value,
                items: [1, 5, 10, 15, 30, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value minute${value > 1 ? 's' : ''}'),
                  );
                }).toList(),
                onChanged: (value) => controller.delayMinutes.value = value!,
              ),
              SizedBox(height: 24),
              // Bouton pour Planifier le Transfert
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            await controller.planifierTransaction();
                            if (controller.error.value.isEmpty) {
                              // Afficher un Snackbar de succès
                              Get.snackbar(
                                'Succès',
                                'Le transfert a été planifié avec succès.',
                                backgroundColor: Colors.green[600],
                                colorText: Colors.white,
                                duration: Duration(seconds: 3),
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Planifier le transfert',
                            style: TextStyle(fontSize: 16),
                          ),
                  )),
              SizedBox(height: 16),
              // Message d'erreur
              Obx(() => controller.error.value.isNotEmpty
                  ? Text(
                      controller.error.value,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
