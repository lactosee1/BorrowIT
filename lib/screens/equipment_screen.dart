
import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import 'equipment_details_screen.dart';
import 'my_requests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final equipmentService = EquipmentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Catalog'),
        actions: [
          // My Requests button
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'My Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyRequestsScreen(),
                ),
              );
            },
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: equipmentService.getEquipment(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not load equipment. Please try again.',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final equipment = snapshot.data ?? [];

          if (equipment.isEmpty) {
            return const Center(
              child: Text('No equipment available yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: equipment.length,
            itemBuilder: (context, index) {
              final item = equipment[index];


              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EquipmentDetailsScreen(
                          equipment: item,
                        ),
                      ),
                    );
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.devices),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.category}\n'
                        '${item.description}\n'
                        'Quantity: ${item.quantity}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isAvailable && item.quantity > 0
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: item.isAvailable && item.quantity > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );

            },
          );
        },
      ),
    );
  }
}
