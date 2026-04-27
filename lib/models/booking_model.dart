import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String fieldId;
  final String fieldName;
  final String date;
  final String startTime;
  final String endTime;
  final int totalPrice;
  final String status;
  final String paymentProofUrl;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.fieldName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.paymentProofUrl = '',
    required this.createdAt,
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
  return BookingModel(
    id: id,
    userId: map['userId'] ?? '',
    fieldId: map['fieldId'] ?? '',
    fieldName: map['fieldName'] ?? '',
    date: map['date'] ?? '',
    startTime: map['startTime'] ?? '',
    endTime: map['endTime'] ?? '',
    totalPrice: map['totalPrice'] ?? 0,
    status: map['status'] ?? 'pending',
    paymentProofUrl: map['paymentProofUrl'] ?? '',
    createdAt: map['createdAt'] != null
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.now(),  // ← fallback kalau null
  );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'totalPrice': totalPrice,
      'status': status,
      'paymentProofUrl': paymentProofUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}