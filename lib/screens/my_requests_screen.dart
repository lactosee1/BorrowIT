
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_request.dart';
import '../services/notification_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _subscription;

  final Map<String, String> _previousStatuses = {};
  bool _firstSnapshotReceived = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _subscription = FirebaseFirestore.instance
          .collection('borrowRequests')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen(
        _handleSnapshot,
        onError: (Object error) {
          debugPrint(
            'Request notification listener error: $error',
          );
        },
      );
    }
  }

  Future<void> _handleSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      ) async {
    for (final document in snapshot.docs) {
      final request = BorrowRequest.fromFirestore(
        document.id,
        document.data(),
      );

      final previousStatus = _previousStatuses[request.id];
      _previousStatuses[request.id] = request.status;

      // Don't notify for the initial snapshot.
      if (_firstSnapshotReceived &&
          previousStatus != null &&
          previousStatus != request.status) {
        try {
          await NotificationService.showStatusNotification(
            requestId: request.id,
            equipmentName: request.equipmentName,
            status: request.status,
          );
        } catch (error) {
          debugPrint(
            'Could not show status notification: $error',
          );
        }
      }

      try {
        if (request.status == 'Approved' ||
            request.status == 'Borrowed') {
          await NotificationService.scheduleReturnReminders(
            requestId: request.id,
            equipmentName: request.equipmentName,
            returnDate: request.returnDate,
          );
        } else {
          await NotificationService.cancelReturnReminders(
            request.id,
          );
        }
      } catch (error) {
        debugPrint(
          'Could not update return reminders: $error',
        );
      }
    }

    _firstSnapshotReceived = true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'borrowed':
        return Colors.blue;
      case 'returned':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      case 'overdue':
        return Colors.deepOrange;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Requests'),
        ),
        body: const Center(
          child: Text(
            'Please log in to view your requests.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
            ),
            tooltip: 'Notification permissions',
            onPressed: () async {
              try {
                await NotificationService.requestPermission();

                if (!context.mounted) return;

                await NotificationService.showTestNotification();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent.'),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notification error: $error'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('borrowRequests')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load your requests.',
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No borrowing requests yet.',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your submitted requests will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final color = statusColor(request.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              request.equipmentName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              request.status,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Quantity: ${request.quantity}'),
                      const SizedBox(height: 8),
                      Text(
                        'Borrow date: '
                            '${formatDate(request.borrowDate)}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Return date: '
                            '${formatDate(request.returnDate)}',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Purpose:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(request.purpose),
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
