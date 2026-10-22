
import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRequest {
  final String id;
  final String userId;
  final String equipmentId;
  final String equipmentName;
  final int quantity;
  final DateTime borrowDate;
  final DateTime returnDate;
  final String purpose;
  final String status;
  final DateTime? createdAt;
  final String? imageUrl;

  const BorrowRequest({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.quantity,
    required this.borrowDate,
    required this.returnDate,
    required this.purpose,
    required this.status,
    this.createdAt,
    this.imageUrl,
  });

  factory BorrowRequest.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BorrowRequest(
      id: id,
      userId: data['userId'] ?? '',
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      borrowDate: (data['borrowDate'] as Timestamp).toDate(),
      returnDate: (data['returnDate'] as Timestamp).toDate(),
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'quantity': quantity,
      'borrowDate': Timestamp.fromDate(borrowDate),
      'returnDate': Timestamp.fromDate(returnDate),
      'purpose': purpose,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    };
  }
}
