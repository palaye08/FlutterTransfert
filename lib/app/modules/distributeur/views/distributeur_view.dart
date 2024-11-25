


 import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getxcli/app/modules/distributeur/controllers/distributeur_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DistributorView extends GetView<DistributorController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            _buildActionButtons(),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distributeur:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${controller.user.value?['prenom'] ?? ''} ${controller.user.value?['nom'] ?? ''}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => controller.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 124, 161, 236).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde Disponible',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Obx(() => Text(
                      '${controller.user.value?['solde']?.toStringAsFixed(0) ?? '0'} CFA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Obx(() => QrImageView(
                      data: controller.userDocumentId.value,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Dépôt',
            color: Colors.green,
            onTap: () => Get.toNamed('/depot'),
          ),
          _buildActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Retrait',
            color: Colors.orange,
            onTap: () => Get.toNamed('/retrait'),
          ),
          _buildActionButton(
            icon: Icons.cancel_outlined,
            label: 'Annuler',
            color: Colors.red,
            onTap: () => Get.toNamed('/annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            foregroundColor: color,
            backgroundColor: color.withOpacity(0.1),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Transactions Récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
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
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune transaction',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.transactions.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final transaction = controller.transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction['type'] == 'depot'
                            ? Colors.green[100]
                            : Colors.orange[100],
                        child: Icon(
                          transaction['type'] == 'depot'
                              ? Icons.add
                              : Icons.remove,
                          color: transaction['type'] == 'depot'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      title: Text(
                        '${transaction['type'].toString().toUpperCase()}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Client: ${transaction['clientName']}',
                      ),
                      trailing: Text(
                        '${transaction['montant'].toStringAsFixed(0)} CFA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction['type'] == 'depot'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
} 