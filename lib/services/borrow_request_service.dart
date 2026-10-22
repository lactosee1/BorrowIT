
import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRequestService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> approveRequest(String requestId) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore
          .collection('borrowRequests')
          .doc(requestId);

      final requestSnapshot =
      await transaction.get(requestRef);

      if (!requestSnapshot.exists) {
        throw Exception('Borrowing request not found.');
      }

      final requestData = requestSnapshot.data()!;

      if (requestData['status'] != 'Pending') {
        throw Exception(
          'This request has already been processed.',
        );
      }

      final equipmentId = requestData['equipmentId'] as String;
      final requestedQuantity =
      (requestData['quantity'] as num).toInt();

      final equipmentRef =
      _firestore.collection('equipment').doc(equipmentId);

      final equipmentSnapshot =
      await transaction.get(equipmentRef);

      if (!equipmentSnapshot.exists) {
        throw Exception('Equipment not found.');
      }

      final equipmentData = equipmentSnapshot.data()!;

      final availableQuantity =
      (equipmentData['quantity'] as num).toInt();

      if (requestedQuantity <= 0) {
        throw Exception('Invalid requested quantity.');
      }

      if (availableQuantity < requestedQuantity) {
        throw Exception(
          'Not enough equipment available. '
              'Available quantity: $availableQuantity.',
        );
      }

      final remainingQuantity =
          availableQuantity - requestedQuantity;

      transaction.update(equipmentRef, {
        'quantity': remainingQuantity,
        'isAvailable': remainingQuantity > 0,
      });

      transaction.update(requestRef, {
        'status': 'Approved',
      });
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore
          .collection('borrowRequests')
          .doc(requestId);

      final requestSnapshot =
      await transaction.get(requestRef);

      if (!requestSnapshot.exists) {
        throw Exception('Borrowing request not found.');
      }

      final requestData = requestSnapshot.data()!;

      if (requestData['status'] != 'Pending') {
        throw Exception(
          'This request has already been processed.',
        );
      }

      transaction.update(requestRef, {
        'status': 'Rejected',
      });
    });
  }

  Future<void> markAsBorrowed(String requestId) async {
    final requestRef = _firestore
        .collection('borrowRequests')
        .doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot =
      await transaction.get(requestRef);

      if (!requestSnapshot.exists) {
        throw Exception('Borrowing request not found.');
      }

      final requestData = requestSnapshot.data()!;

      if (requestData['status'] != 'Approved') {
        throw Exception(
          'Only approved requests can be marked as borrowed.',
        );
      }

      transaction.update(requestRef, {
        'status': 'Borrowed',
      });
    });
  }

  Future<void> markAsReturned(String requestId) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore
          .collection('borrowRequests')
          .doc(requestId);

      final requestSnapshot =
      await transaction.get(requestRef);

      if (!requestSnapshot.exists) {
        throw Exception('Borrowing request not found.');
      }

      final requestData = requestSnapshot.data()!;

      if (requestData['status'] != 'Borrowed') {
        throw Exception(
          'Only borrowed equipment can be marked as returned.',
        );
      }

      final equipmentId = requestData['equipmentId'] as String;
      final returnedQuantity =
      (requestData['quantity'] as num).toInt();

      if (returnedQuantity <= 0) {
        throw Exception('Invalid returned quantity.');
      }

      final equipmentRef =
      _firestore.collection('equipment').doc(equipmentId);

      final equipmentSnapshot =
      await transaction.get(equipmentRef);

      if (!equipmentSnapshot.exists) {
        throw Exception('Equipment not found.');
      }

      final equipmentData = equipmentSnapshot.data()!;
      final currentQuantity =
      (equipmentData['quantity'] as num).toInt();

      final updatedQuantity = currentQuantity + returnedQuantity;

      transaction.update(equipmentRef, {
        'quantity': updatedQuantity,
        'isAvailable': updatedQuantity > 0,
      });

      transaction.update(requestRef, {
        'status': 'Returned',
      });
    });
  }

}
