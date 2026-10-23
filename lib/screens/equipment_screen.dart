
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import 'equipment_details_screen.dart';
import 'my_requests_screen.dart';
import 'home_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Catalog'),
        actions: [
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search equipment',
                hintText: 'Search by name, category, or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: _equipmentService.getEquipment(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load equipment. Please try again.',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
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

                final filteredEquipment = equipment.where((item) {
                  final name = item.name.toLowerCase();
                  final category = item.category.toLowerCase();
                  final description = item.description.toLowerCase();

                  return name.contains(_searchQuery) ||
                      category.contains(_searchQuery) ||
                      description.contains(_searchQuery);
                }).toList();

                if (filteredEquipment.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching equipment found.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEquipment.length,
                  itemBuilder: (context, index) {
                    final item = filteredEquipment[index];
                    final available =
                        item.isAvailable && item.quantity > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EquipmentDetailsScreen(
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
                              available
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: available
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
          ),
        ],
      ),
    );
  }
}
