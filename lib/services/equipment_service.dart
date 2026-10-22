
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';

class EquipmentService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<List<Equipment>> getEquipment() {
    return _firestore
        .collection('equipment')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Equipment.fromFirestore(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }
}
