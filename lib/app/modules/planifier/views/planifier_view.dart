import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
              // Frequency Dropdown
              Obx(() => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Fréquence',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.repeat, color: Colors.blue[800]),
                    ),
                    value: controller.frequency.value,
                    items: controller.frequencyOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.capitalizeFirst ?? value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      controller.frequency.value = value!;
                      // Reset frequency value based on selected frequency
                      controller.frequencyValue.value = 1;
                    },
                  )),
              SizedBox(height: 16),
              // Frequency Value Input
              Obx(() {
                // Determine the input type based on frequency
                if (controller.frequency.value == 'minutes') {
                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Délai (minutes)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.timer, color: Colors.blue[800]),
                    ),
                    value: controller.frequencyValue.value,
                    items: [1, 5, 10, 15, 30, 60].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value minute${value > 1 ? 's' : ''}'),
                      );
                    }).toList(),
                    onChanged: (value) => controller.frequencyValue.value = value!,
                  );
                } else {
                  // For daily, weekly, monthly
                  return TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Valeur de fréquence',
                      hintText: controller.frequency.value == 'daily' 
                        ? 'Ex: tous les 2 jours' 
                        : (controller.frequency.value == 'weekly' 
                          ? 'Ex: toutes les 3 semaines' 
                          : 'Ex: tous les 2 mois'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.numbers, color: Colors.blue[800]),
                    ),
                    onChanged: (value) => controller.frequencyValue.value = int.tryParse(value) ?? 1,
                  );
                }
              }),
              SizedBox(height: 16),
              // Date Picker
              Obx(() => ListTile(
                    title: Text('Date de début'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(controller.startDate.value),
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                    trailing: Icon(Icons.calendar_today, color: Colors.blue[800]),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: controller.startDate.value,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2025),
                      );
                      if (picked != null) {
                        controller.startDate.value = picked;
                      }
                    },
                  )),
              SizedBox(height: 24),
              // Bouton pour Planifier le Transfert
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            await controller.planifierTransaction();
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