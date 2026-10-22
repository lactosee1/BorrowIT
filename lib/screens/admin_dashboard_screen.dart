
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../models/borrow_request.dart';
import '../services/borrow_request_service.dart';
import 'admin_equipment_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static final BorrowRequestService _requestService =
  BorrowRequestService();

  Future<void> _performAction(
      BuildContext context,
      String requestId,
      String action,
      ) async {
    try {
      switch (action) {
        case 'Approve':
          await _requestService.approveRequest(requestId);
          break;
        case 'Reject':
          await _requestService.rejectRequest(requestId);
          break;
        case 'Borrowed':
          await _requestService.markAsBorrowed(requestId);
          break;
        case 'Returned':
          await _requestService.markAsReturned(requestId);
          break;
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'Borrowed'
                ? 'Equipment marked as borrowed.'
                : action == 'Returned'
                ? 'Equipment returned and stock updated.'
                : 'Request ${action.toLowerCase()}d.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not perform action: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BorrowIT Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Manage Equipment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const AdminEquipmentScreen(),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('borrowRequests')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load borrowing requests.',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          final requests = documents.map((document) {
            return BorrowRequest.fromFirestore(
              document.id,
              document.data(),
            );
          }).toList();

          requests.sort((a, b) {
            return (b.createdAt ?? b.borrowDate)
                .compareTo(a.createdAt ?? a.borrowDate);
          });

          final pendingCount = requests
              .where((request) => request.status == 'Pending')
              .length;

          if (requests.isEmpty) {
            return const Center(
              child: Text('No borrowing requests yet.'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total Requests: ${requests.length}\n'
                      'Pending Requests: $pendingCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.equipmentName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Student UID: ${request.userId}'),
                            Text('Quantity: ${request.quantity}'),
                            Text('Purpose: ${request.purpose}'),
                            Text(
                              'Borrow date: '
                                  '${request.borrowDate.toString().split(' ').first}',
                            ),
                            Text(
                              'Return date: '
                                  '${request.returnDate.toString().split(' ').first}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: ${request.status}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: request.status == 'Pending'
                                    ? Colors.orange
                                    : request.status == 'Approved'
                                    ? Colors.green
                                    : request.status == 'Rejected'
                                    ? Colors.red
                                    : request.status == 'Borrowed'
                                    ? Colors.blue
                                    : Colors.teal,
                              ),
                            ),

                            // Pending: Approve or Reject
                            if (request.status == 'Pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _performAction(
                                        context,
                                        request.id,
                                        'Approve',
                                      ),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _performAction(
                                        context,
                                        request.id,
                                        'Reject',
                                      ),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Approved: Mark as Borrowed
                            if (request.status == 'Approved') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _performAction(
                                    context,
                                    request.id,
                                    'Borrowed',
                                  ),
                                  icon: const Icon(Icons.outbox),
                                  label: const Text('Mark as Borrowed'),
                                ),
                              ),
                            ],

                            // Borrowed: Mark as Returned
                            if (request.status == 'Borrowed') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _performAction(
                                    context,
                                    request.id,
                                    'Returned',
                                  ),
                                  icon: const Icon(Icons.assignment_turned_in),
                                  label: const Text('Mark as Returned'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
