import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'firebase_options.dart';
// firebase bağlantısı ve uygulama başlatma kısmı 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
// tema yapısını hazırlama ve ana ekran olarak HomePage i açar 
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İlaç Takip Sistemi',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}
// firebase bağlantısı ve veri dinleme
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //  NodeMCU ile uyumlu olduğunu kontrol etme
  final DatabaseReference _db = FirebaseDatabase.instance.ref('ilaclar');

  Map<String, Map<String, dynamic>> ilaclar = {
    'ilac1': {},
    'ilac2': {},
    'ilac3': {},
  };
  
  bool yukleniyor = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    
    // Firebase dinleyici - veri dinleme - verilerin okunması
    _subscription = _db.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        setState(() {
          // Her slot için veri güncelleme kısmı
          ['ilac1', 'ilac2', 'ilac3'].forEach((key) {
            if (data.containsKey(key)) {
              ilaclar[key] = Map<String, dynamic>.from(data[key] as Map);
            } else {
              // Slot boşsa varsayılan değerler bunlar
              ilaclar[key] = {
                'ilac_adi': '',
                'saat': '',
                'doz': '',
                'aktif': false,
                'alindi': false,
                'ledOn': false,
                'zamanAsimi': false,
              };
            }
          });
          yukleniyor = false;
        });
      } else {
        setState(() {
          yukleniyor = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  //  İlaç bilgilerini güncelleme kısmı
  Future<void> ilacGuncelle(
    String slotKey,
    String ilacAdi,
    String saat,
    String doz,
  ) async {
    try {
      await _db.child(slotKey).set({
        'ilac_adi': ilacAdi,
        'saat': saat,
        'doz': doz,
        'aktif': true,
        'alindi': false,
        'ledOn': false,
        'zamanAsimi': false,
        'ledOnTime': 0,
        'alinmaZamani': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $ilacAdi kaydedildi - Saat: $saat'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  //  İlacı sıfırla (tekrar kullanım için)
  Future<void> ilaciSifirla(String slotKey) async {
    await _db.child(slotKey).update({
      'aktif': false,
      'alindi': false,
      'ledOn': false,
      'zamanAsimi': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ İlaç sıfırlandı'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔹 İlacı silme kısmı
  Future<void> ilaciSil(String slotKey) async {
    await _db.child(slotKey).set({
      'ilac_adi': '',
      'saat': '',
      'doz': '',
      'aktif': false,
      'alindi': false,
      'ledOn': false,
      'zamanAsimi': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ İlaç silindi'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔹 İlaç düzenleme kısmı
  void ilacDuzenleDialog(String slotKey, String slotAdi) {
    final mevcut = ilaclar[slotKey] ?? {};
    
    String ilacAdi = mevcut['ilac_adi'] ?? '';
    String saat = mevcut['saat'] ?? '';
    String doz = mevcut['doz'] ?? '';

    final ilacAdiController = TextEditingController(text: ilacAdi);
    final dozController = TextEditingController(text: doz);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.medication, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(slotAdi),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ilacAdiController,
                decoration: const InputDecoration(
                  labelText: 'İlaç Adı',
                  prefixIcon: Icon(Icons.medication_liquid),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => ilacAdi = v,
              ),
              const SizedBox(height: 16),
              
              // Saat seçme
              InkWell(
                onTap: () async {
                  TimeOfDay? secilenSaat = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (secilenSaat != null) {
                    setState(() {
                      saat = '${secilenSaat.hour.toString().padLeft(2, '0')}:'
                          '${secilenSaat.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Saat',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    saat.isEmpty ? 'Saat seçin' : saat,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: saat.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: dozController,
                decoration: const InputDecoration(
                  labelText: 'Doz (opsiyonel)',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                  hintText: 'Örn: 1 tablet',
                ),
                onChanged: (v) => doz = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Vazgeç'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (ilacAdi.isNotEmpty && saat.isNotEmpty) {
                ilacGuncelle(slotKey, ilacAdi, saat, doz);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İlaç adı ve saat gereklidir!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '💊 İlaç Takip Sistemi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Bilgilendirme kartı
                  _bilgiKarti(),
                  const SizedBox(height: 16),

                  // İlaç slotları
                  Expanded(
                    child: ListView(
                      children: [
                        _ilacSlotKart('ilac1', 'Slot 1 - LED 1', Colors.red),
                        const SizedBox(height: 12),
                        _ilacSlotKart('ilac2', 'Slot 2 - LED 2', Colors.orange),
                        const SizedBox(height: 12),
                        _ilacSlotKart('ilac3', 'Slot 3 - LED 3', Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _bilgiKarti() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.indigo.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Her slot için ilaç adı ve saat girin. Zamanı gelince LED yanacak. '
              'Kapağı 2 dakika içinde açın!',
              style: TextStyle(
                color: Colors.indigo.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ilacSlotKart(String slotKey, String baslik, Color renk) {
    final ilac = ilaclar[slotKey] ?? {};
    
    String ilacAdi = ilac['ilac_adi'] ?? '';
    String saat = ilac['saat'] ?? '';
    String doz = ilac['doz'] ?? '';
    bool aktif = ilac['aktif'] == true;
    bool ledOn = ilac['ledOn'] == true;
    bool alindi = ilac['alindi'] == true;
    bool zamanAsimi = ilac['zamanAsimi'] == true;

    Color cardColor = Colors.white;
    String durumMetni = 'Boş Slot';
    IconData durumIcon = Icons.add_circle_outline;
    Color durumColor = Colors.grey;

    if (ledOn) {
      cardColor = renk.withOpacity(0.15);
      durumMetni = '🔴 LED AÇIK - Kapak Açın!';
      durumIcon = Icons.notifications_active;
      durumColor = renk;
    } else if (alindi) {
      cardColor = Colors.green.shade50;
      durumMetni = '✅ İlaç Alındı';
      durumIcon = Icons.check_circle;
      durumColor = Colors.green;
    } else if (zamanAsimi) {
      cardColor = Colors.red.shade50;
      durumMetni = '⏱️ Zaman Aşımı';
      durumIcon = Icons.warning_amber;
      durumColor = Colors.red;
    } else if (aktif && ilacAdi.isNotEmpty) {
      durumMetni = '⏰ Zamanlandı';
      durumIcon = Icons.schedule;
      durumColor = Colors.blue;
    }

    return Card(
      color: cardColor,
      elevation: ledOn ? 8 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: ledOn ? renk : Colors.transparent,
          width: ledOn ? 3 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: renk,
                    shape: BoxShape.circle,
                    boxShadow: ledOn
                        ? [
                            BoxShadow(
                              color: renk.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // İlaç bilgileri  kısmı
            if (ilacAdi.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.medication, size: 20, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ilacAdi,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Saat belirleme ksımı
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  saat.isEmpty ? 'Saat belirlenmedi' : saat,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: saat.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),

            if (doz.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_pharmacy, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Doz: $doz',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Durum gösterme kısmı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: durumColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: durumColor.withOpacity(0.3),
                ),
              ),
              child: Row(
              mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(durumIcon, color: durumColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    durumMetni,
                    style: TextStyle(
                      color: durumColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Butonlar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ilacDuzenleDialog(slotKey, baslik),
                  icon: Icon(
                    ilacAdi.isEmpty ? Icons.add : Icons.edit,
                    size: 18,
                  ),
                  label: Text(ilacAdi.isEmpty ? 'İlaç Ekle' : 'Düzenle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),

                if (ilacAdi.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => ilaciSifirla(slotKey),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Sıfırla'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ilaciSil(slotKey),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Sil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}