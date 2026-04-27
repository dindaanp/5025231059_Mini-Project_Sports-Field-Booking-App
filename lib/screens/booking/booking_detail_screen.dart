import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import 'dart:convert';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF00BFA5),
              ],
            ),
          ),
        ),
        title: const Text(
          'Detail Booking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradient(booking.status),
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(booking.status).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildStatusIcon(booking.status),
                  const SizedBox(height: 10),
                  Text(
                    _getStatusText(booking.status),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detail info card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF00BFA5)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.receipt_long,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Detail Booking',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.sports_soccer, 'Lapangan',
                            booking.fieldName),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.calendar_today, 'Tanggal',
                            booking.date),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.access_time, 'Jam',
                            '${booking.startTime} - ${booking.endTime}'),
                        const Divider(height: 20),
                        _buildInfoRow(
                          Icons.payments,
                          'Total',
                          'Rp ${NumberFormat('#,###', 'id_ID').format(booking.totalPrice)}',
                          valueColor: const Color(0xFF1B5E20),
                          valueBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bukti pembayaran
            if (booking.paymentProofUrl.isNotEmpty) ...[
              const Text(
                'Bukti Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00BFA5), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(booking.paymentProofUrl),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text('Gagal memuat gambar'),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tombol batalkan
            if (booking.status == 'pending')
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Batalkan Booking'),
                        content: const Text(
                            'Yakin ingin membatalkan booking ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Tidak'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Ya, Batalkan',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await firestoreService.updateBookingStatus(
                          booking.id, 'cancelled');
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batalkan Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF00BFA5)),
        ),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight:
                  valueBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black87,
              fontSize: valueBold ? 15 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.white, size: 60);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.white, size: 60);
      default:
        return const Icon(Icons.hourglass_empty,
            color: Colors.white, size: 60);
    }
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'confirmed':
        return [const Color(0xFF1B5E20), const Color(0xFF00BFA5)];
      case 'cancelled':
        return [Colors.red.shade700, Colors.red.shade400];
      default:
        return [Colors.orange.shade700, Colors.yellow.shade600];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Booking Dikonfirmasi';
      case 'cancelled':
        return 'Booking Dibatalkan';
      default:
        return 'Menunggu Konfirmasi';
    }
  }
}