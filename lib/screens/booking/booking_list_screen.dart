import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'booking_detail_screen.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Silakan login terlebih dahulu'));
    }

    return StreamBuilder<List<BookingModel>>(
      stream: firestoreService.getUserBookings(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade50,
                  ),
                  child: const Icon(Icons.book_online,
                      size: 80, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada booking',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yuk booking lapangan sekarang!',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingDetailScreen(booking: booking),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Top gradient strip sesuai status
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getStatusGradient(booking.status),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking.fieldName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ),
                                  _buildStatusChip(booking.status),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Color(0xFF00BFA5)),
                                  const SizedBox(width: 4),
                                  Text(booking.date,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 13)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.access_time,
                                      size: 14, color: Color(0xFF00BFA5)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${booking.startTime} - ${booking.endTime}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rp ${NumberFormat('#,###', 'id_ID').format(booking.totalPrice)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1B5E20),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget _buildStatusChip(String status) {
    List<Color> gradientColors;
    String label;
    switch (status) {
      case 'confirmed':
        gradientColors = [const Color(0xFF2E7D32), const Color(0xFF00BFA5)];
        label = 'Dikonfirmasi';
        break;
      case 'cancelled':
        gradientColors = [Colors.red.shade700, Colors.red.shade400];
        label = 'Dibatalkan';
        break;
      default:
        gradientColors = [Colors.orange.shade700, Colors.yellow.shade600];
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}