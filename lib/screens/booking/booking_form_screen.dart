import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/booking_model.dart';
import '../../models/field_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';

class BookingFormScreen extends StatefulWidget {
  final FieldModel field;
  const BookingFormScreen({super.key, required this.field});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  List<String> _bookedSlots = [];
  DateTime? _selectedDate;
  String? _startTime;
  String? _endTime;
  File? _paymentProof;
  bool _isLoading = false;

  bool get _isScheduleLocked => _paymentProof != null;

  final List<String> _timeSlots = [
    '06:00', '07:00', '08:00', '09:00', '10:00',
    '11:00', '12:00', '13:00', '14:00', '15:00',
    '16:00', '17:00', '18:00', '19:00', '20:00', '21:00',
  ];

  int get _totalPrice {
    if (_startTime == null || _endTime == null) return 0;
    final start = int.parse(_startTime!.split(':')[0]);
    final end = int.parse(_endTime!.split(':')[0]);
    final duration = end - start;
    return duration > 0 ? duration * widget.field.price : 0;
  }

  int _getDuration() {
  if (_startTime == null || _endTime == null) return 0;

  final start = int.parse(_startTime!.split(':')[0]);
  final end = int.parse(_endTime!.split(':')[0]);

  return end - start;
}

  Future<void> _pickDate() async {
    if (_isScheduleLocked) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _startTime = null;
        _endTime = null;
      });
      await _loadBookedSlots();
    }
  }

  Future<void> _pickPaymentProof() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF00BFA5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 20),
              ),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _storageService.pickImageFromCamera();
                if (file != null) setState(() => _paymentProof = file);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF00BFA5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library,
                    color: Colors.white, size: 20),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _storageService.pickImageFromGallery();
                if (file != null) setState(() => _paymentProof = file);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removePaymentProof() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Bukti Pembayaran?'),
        content: const Text(
            'Jadwal akan terbuka kembali dan bisa diubah. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _paymentProof = null);
              Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null) {
      _showError('Pilih tanggal terlebih dahulu');
      return;
    }
    if (_startTime == null) {
      _showError('Pilih jam mulai terlebih dahulu');
      return;
    }
    if (_endTime == null) {
      _showError('Pilih jam selesai terlebih dahulu');
      return;
    }
    if (_totalPrice <= 0) {
      _showError('Jam selesai harus lebih dari jam mulai');
      return;
    }
    if (_paymentProof == null) {
      _showError('Harap unggah bukti pembayaran terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;
      final bookingId = const Uuid().v4();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final isAvailable = await _firestoreService.isTimeSlotAvailable(
        fieldId: widget.field.id,
        date: dateStr,
        startTime: _startTime!,
        endTime: _endTime!,
      );

      if (!isAvailable) {
        _showError('Jadwal sudah dibooking, pilih jam lain!');
        setState(() => _isLoading = false);
        return;
      }

      final proofUrl = await _storageService.uploadPaymentProof(
        _paymentProof!,
        bookingId,
      );

      final booking = BookingModel(
        id: bookingId,
        userId: user.uid,
        fieldId: widget.field.id,
        fieldName: widget.field.name,
        date: dateStr,
        startTime: _startTime!,
        endTime: _endTime!,
        totalPrice: _totalPrice,
        status: 'pending',
        paymentProofUrl: proofUrl ?? '',
        createdAt: DateTime.now(),
      );

      await _firestoreService.addBooking(booking);

      await NotificationService.showBookingNotification(
        fieldName: widget.field.name,
        date: DateFormat('dd MMM yyyy').format(_selectedDate!),
        time: '$_startTime - $_endTime',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil! Silakan menunggu konfirmasi.'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Gagal booking: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadBookedSlots() async {
    if (_selectedDate == null) return;
    final slots = await _firestoreService.getBookedSlots(
      fieldId: widget.field.id,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
    );
    setState(() => _bookedSlots = slots);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  bool _isSlotBooked(String time) => _bookedSlots.contains(time);

  Widget _buildTimeGrid({
    required String label,
    required String? selectedTime,
    required void Function(String) onSelect,
    bool isEndTime = false,
  }) {
    final slots = isEndTime && _startTime != null
        ? _timeSlots.where((t) => t.compareTo(_startTime!) > 0).toList()
        : _timeSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20))),
            if (_isScheduleLocked) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock, size: 14, color: Colors.orange),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(Colors.green.shade50, Colors.green.shade300,
                'Tersedia'),
            const SizedBox(width: 10),
            _legendDot(
                Colors.red.shade100, Colors.red.shade300, 'Dipesan'),
            const SizedBox(width: 10),
            _legendDot(const Color(0xFF1B5E20), const Color(0xFF1B5E20),
                'Dipilih'),
            if (_isScheduleLocked) ...[
              const SizedBox(width: 10),
              _legendDot(Colors.grey.shade200, Colors.grey.shade400,
                  'Terkunci'),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (isEndTime && _startTime == null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text('Pilih jam mulai terlebih dahulu',
                    style:
                        TextStyle(color: Colors.orange, fontSize: 13)),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((time) {
              final booked = _isSlotBooked(time);
              final selected = selectedTime == time;
              final locked = _isScheduleLocked && !selected;

              Color bgColor;
              Color textColor;
              Color borderColor;

              if (selected) {
                bgColor = const Color(0xFF1B5E20);
                textColor = Colors.white;
                borderColor = const Color(0xFF1B5E20);
              } else if (booked) {
                bgColor = Colors.red.shade100;
                textColor = Colors.red.shade800;
                borderColor = Colors.red.shade300;
              } else if (locked) {
                bgColor = Colors.grey.shade200;
                textColor = Colors.grey.shade400;
                borderColor = Colors.grey.shade300;
              } else {
                bgColor = Colors.green.shade50;
                textColor = const Color(0xFF1B5E20);
                borderColor = Colors.green.shade300;
              }

              return GestureDetector(
                onTap: (booked || locked) ? null : () => onSelect(time),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    time,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }


  Widget _legendDot(Color bg, Color border, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Formulir Booking',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info lapangan
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF00BFA5)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_soccer,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.field.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(widget.field.price)}/jam',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pilih tanggal
            const Text('Tanggal Booking',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isScheduleLocked ? null : _pickDate,
              icon: Icon(
                _isScheduleLocked ? Icons.lock : Icons.calendar_today,
                color: _isScheduleLocked
                    ? Colors.grey
                    : const Color(0xFF1B5E20),
              ),
              label: Text(
                _selectedDate == null
                    ? 'Pilih Tanggal'
                    : DateFormat('dd MMMM yyyy', 'id_ID')
                        .format(_selectedDate!),
                style: TextStyle(
                  color: _isScheduleLocked
                      ? Colors.grey
                      : _selectedDate == null
                          ? Colors.grey
                          : Colors.black,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: _isScheduleLocked
                      ? Colors.grey.shade300
                      : const Color(0xFF1B5E20),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Grid jam
            if (_selectedDate != null) ...[
              _buildTimeGrid(
                label: 'Jam Mulai',
                selectedTime: _startTime,
                onSelect: (t) => setState(() {
                  _startTime = t;
                  _endTime = null;
                }),
              ),
              const SizedBox(height: 16),
              _buildTimeGrid(
                label: 'Jam Selesai',
                selectedTime: _endTime,
                onSelect: (t) => setState(() => _endTime = t),
                isEndTime: true,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text('Pilih tanggal dahulu untuk melihat slot jam',
                        style: TextStyle(color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Total harga + durasi
            if (_totalPrice > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF00BFA5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Durasi
                    Text(
                      '${_startTime!} - ${_endTime!} (${_getDuration()} jam)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                    ),
                      ),
                    const SizedBox(height: 6),

                    // Total harga
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500)),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(_totalPrice)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bukti Pembayaran
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bukti Pembayaran',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20))),
                if (_paymentProof != null)
                  TextButton.icon(
                    onPressed: _removePaymentProof,
                    icon: const Icon(Icons.delete,
                        size: 16, color: Colors.red),
                    label: const Text('Hapus & Ubah Jadwal',
                        style:
                            TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isScheduleLocked)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hapus bukti bayar jika ingin mengubah jadwal.',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            GestureDetector(
              onTap: _pickPaymentProof,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _paymentProof != null
                        ? const Color(0xFF00BFA5)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: _paymentProof != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_paymentProof!,
                            fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1B5E20),
                                  Color(0xFF00BFA5)
                                ],
                              ),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 28, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          const Text('Ketuk untuk mengunggah bukti pembayaran',
                              style: TextStyle(color: Colors.grey)),
                          const Text('(Foto/Galeri)',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol booking
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF00BFA5)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text(
                        'Konfirmasi Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}