import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/field_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fields
  Future<void> addField(FieldModel field) async {
    await _firestore.collection('fields').add(field.toMap());
  }

  Stream<List<FieldModel>> getFields() {
    return _firestore.collection('fields').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FieldModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateField(String id, FieldModel field) async {
    await _firestore.collection('fields').doc(id).update(field.toMap());
  }

  Future<void> deleteField(String id) async {
    await _firestore.collection('fields').doc(id).delete();
  }

  // Bookings
  Future<void> addBooking(BookingModel booking) async {
    await _firestore.collection('bookings').add(booking.toMap());
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<BookingModel>> getAllBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _firestore
        .collection('bookings')
        .doc(id)
        .update({'status': status});
  }

  Future<void> updateBooking(String id, Map<String, dynamic> data) async {
    await _firestore.collection('bookings').doc(id).update(data);
  }

  Future<void> deleteBooking(String id) async {
    await _firestore.collection('bookings').doc(id).delete();
  }

  Future<List<String>> getBookedSlots({
    required String fieldId,
    required String date,
  }) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .where('date', isEqualTo: date)
        .get();

    List<String> booked = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
    
      // skip booking yang dibatalkan
      if (data['status'] == 'cancelled') continue;

      final start = int.parse(data['startTime'].split(':')[0]);
      final end = int.parse(data['endTime'].split(':')[0]);

      for (int i = start; i < end; i++) {
        booked.add('${i.toString().padLeft(2, '0')}:00');
      }
    }
    return booked;
  }

  Future<bool> isTimeSlotAvailable({
    required String fieldId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final snapshot = await _firestore
        .collection('bookings')
       .where('fieldId', isEqualTo: fieldId)
       .where('date', isEqualTo: date)
       .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // skip booking yang dibatalkan
      if (data['status'] == 'cancelled') continue;

      final existingStart = data['startTime'];
      final existingEnd = data['endTime'];

      if (!(endTime.compareTo(existingStart) <= 0 ||
          startTime.compareTo(existingEnd) >= 0)) {
        return false;
      }
    }
    return true;
    }
  }