# Sports Field Booking App

Aplikasi mobile berbasis Flutter untuk melakukan booking lapangan olahraga secara online.  
Aplikasi ini dibuat dengan fitur utama CRUD, Firebase Authentication, Notification, dan penggunaan resource smartphone Camera. Pada aplikasi ini, user bisa melakukan:
- Login dan register akun
- Melihat daftar lapangan
- Melakukan booking berdasarkan tanggal dan jam
- Mengupload bukti pembayaran menggunakan kamera atau galeri
- Mendapatkan notifikasi setelah booking berhasil
- Membatalkan booking yang telah dilakukan


## Fitur Utama

### 1. Authentication (Firebase)
- Register user
- Login user
- Logout
- Data user tersimpan di Firebase Firestore


### 2. CRUD
- Create booking lapangan
- Read data lapangan & booking
- Update status booking
- Delete booking


### 3. Camera (Smartphone Resource)
- Upload bukti pembayaran via:
  - Kamera
  - Galeri


### 4. Firestore
- Menyimpan data booking
- Menyimpan data lapangan


### 5. Notification
- Notifikasi lokal setelah booking berhasil


### 6. Booking System
- Pilih tanggal
- Pilih jam mulai & selesai
- Validasi bentrok jadwal
- Perhitungan total harga otomatis
