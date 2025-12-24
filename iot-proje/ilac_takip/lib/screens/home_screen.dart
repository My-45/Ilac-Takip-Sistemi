import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mevcut kullanıcının UID'sini al
    final user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;
    
    // IoT cihazının veritabanı yolu
    // Örnek Yol: users/USER_UID/devices/DEVICE_ID/last_known_state
    // BURAYI PROJENİZİN REALTIME DATABASE YAPISINA GÖRE DÜZENLEYİN!
    final databaseRef = FirebaseDatabase.instance.ref('users/$uid/device_001/last_known_state');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa - İlaç Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Çıkış Yapma
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Hoş geldiniz, ${user?.email ?? 'Kullanıcı'}', style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            
            const Text('Anlık Cihaz Durumu (Firebase Verisi):', style: TextStyle(fontWeight: FontWeight.bold)),
            
            // Realtime Database Veri Akışı
            StreamBuilder(
              stream: databaseRef.onValue, // Anlık veri akışını dinle
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Veri Hatası: ${snapshot.error}');
                }

                // Veri gelmişse ve boş değilse
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final bool isBoxOpen = data['box_open'] ?? false;
                  final double weightGrams = (data['weight_grams'] ?? 0.0).toDouble();
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(isBoxOpen ? Icons.lock_open : Icons.lock, color: isBoxOpen ? Colors.red : Colors.green),
                      title: Text('Kutu Durumu: ${isBoxOpen ? 'AÇIK' : 'KAPALI'}'),
                      subtitle: Text('Kalan İlaç Ağırlığı: ${weightGrams.toStringAsFixed(2)} gram'),
                    ),
                  );
                }
                return const Text('IoT Cihazı Verisi Bekleniyor...');
              },
            ),
          ],
        ),
      ),
    );
  }
}