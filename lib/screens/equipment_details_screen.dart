
import 'package:flutter/material.dart';
import '../models/equipment.dart';
import 'borrow_request_screen.dart';

class EquipmentDetailsScreen extends StatelessWidget {
  final Equipment equipment;

  const EquipmentDetailsScreen({
    super.key,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable =
        equipment.isAvailable && equipment.quantity > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: equipment.imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  equipment.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.devices,
                      size: 100,
                      color: Colors.indigo,
                    );
                  },
                ),
              )
                  : const Icon(
                Icons.devices,
                size: 100,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              equipment.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(equipment.category),
              avatar: const Icon(Icons.category_outlined),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              equipment.description.isNotEmpty
                  ? equipment.description
                  : 'No description available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Quantity'),
                subtitle: Text('${equipment.quantity} unit(s)'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(
                  isAvailable
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                title: const Text('Availability'),
                subtitle: Text(
                  isAvailable ? 'Available' : 'Not available',
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: isAvailable
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BorrowRequestScreen(
                      equipment: equipment,
                    ),
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.assignment_outlined),
              label: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Request to Borrow'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
