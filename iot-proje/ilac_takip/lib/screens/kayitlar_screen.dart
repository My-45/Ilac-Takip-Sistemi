import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class KayitlarScreen extends StatefulWidget {
  @override
  State<KayitlarScreen> createState() => _KayitlarScreenState();
}

class _KayitlarScreenState extends State<KayitlarScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> kayitlar = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    kayitlariGetir();
  }

  void kayitlariGetir() async {
    try {
      final snapshot = await _database.child('kayitlar/test_user_1').get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> veriler = snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> liste = [];
        
        veriler.forEach((key, value) {
          liste.add({
            'id': key,
            ...value as Map<dynamic, dynamic>
          });
        });
        
        // Tarihe göre sırala (en yeni üstte)
        liste.sort((a, b) {
          String tarihA = a['tarih'] ?? '';
          String tarihB = b['tarih'] ?? '';
          return tarihB.compareTo(tarihA);
        });
        
        setState(() {
          kayitlar = liste;
          yukleniyor = false;
        });
        print('✅ ${kayitlar.length} kayıt bulundu');
      } else {
        setState(() {
          yukleniyor = false;
        });
        print('⚠️ Kayıt bulunamadı');
      }
    } catch (e) {
      setState(() {
        yukleniyor = false;
      });
      print('❌ Kayıt çekme hatası: $e');
    }
  }

  String tarihFormatla(String tarih) {
    try {
      DateTime dt = DateTime.parse(tarih);
      return DateFormat('dd MMM yyyy', 'tr_TR').format(dt);
    } catch (e) {
      return tarih;
    }
  }

  String gecikmeMetni(Map kayit) {
    if (kayit['ilac_alindi'] != true) {
      return '❌ Alınmadı';
    }
    
    int? gecikme = kayit['gecikme_dakika'];
    if (gecikme == null) {
      return '✅ Alındı';
    }
    
    if (gecikme == 0) {
      return '✅ Zamanında';
    } else if (gecikme > 0) {
      return '⚠️ $gecikme dk gecikme';
    } else {
      return '⏰ ${gecikme.abs()} dk erken';
    }
  }

  Color durumRengi(Map kayit) {
    if (kayit['ilac_alindi'] != true) {
      return Colors.red;
    }
    
    int? gecikme = kayit['gecikme_dakika'];
    if (gecikme == null || gecikme == 0) {
      return Colors.green;
    } else if (gecikme > 0 && gecikme <= 15) {
      return Colors.orange;
    } else if (gecikme > 15) {
      return Colors.red;
    }
    
    return Colors.blue;
  }

  IconData durumIkonu(Map kayit) {
    if (kayit['ilac_alindi'] != true) {
      return Icons.cancel;
    }
    
    int? gecikme = kayit['gecikme_dakika'];
    if (gecikme == null || gecikme == 0) {
      return Icons.check_circle;
    } else {
      return Icons.access_time;
    }
  }

  // İstatistikler
  Map<String, dynamic> istatistikleriHesapla() {
    if (kayitlar.isEmpty) {
      return {
        'toplam': 0,
        'alinan': 0,
        'alinmayan': 0,
        'uyum_yuzdesi': 0.0,
      };
    }

    int toplam = kayitlar.length;
    int alinan = kayitlar.where((k) => k['ilac_alindi'] == true).length;
    int alinmayan = toplam - alinan;
    double uyumYuzdesi = (alinan / toplam) * 100;

    return {
      'toplam': toplam,
      'alinan': alinan,
      'alinmayan': alinmayan,
      'uyum_yuzdesi': uyumYuzdesi,
    };
  }

  @override
  Widget build(BuildContext context) {
    final istatistikler = istatistikleriHesapla();

    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanım Kayıtları'),
        backgroundColor: Colors.blue,
      ),
      body: yukleniyor
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // İstatistik Kartları
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: [
                      Text(
                        'Genel İstatistikler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _istatistikKarti(
                            'Toplam',
                            '${istatistikler['toplam']}',
                            Colors.blue,
                            Icons.list,
                          ),
                          _istatistikKarti(
                            'Alınan',
                            '${istatistikler['alinan']}',
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _istatistikKarti(
                            'Atlandı',
                            '${istatistikler['alinmayan']}',
                            Colors.red,
                            Icons.cancel,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_up, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Uyum Oranı: ${istatistikler['uyum_yuzdesi'].toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Kayıt Listesi
                Expanded(
                  child: kayitlar.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Henüz kayıt yok',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: kayitlar.length,
                          itemBuilder: (context, index) {
                            final kayit = kayitlar[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: durumRengi(kayit),
                                  child: Icon(
                                    durumIkonu(kayit),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  kayit['ilac_adi'] ?? 'İsimsiz İlaç',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      '📅 ${tarihFormatla(kayit['tarih'] ?? '')}',
                                    ),
                                    Text(
                                      '⏰ Planlanan: ${kayit['planlanan_saat']}',
                                    ),
                                    if (kayit['gerceklesen_saat'] != null)
                                      Text(
                                        '✓ Gerçekleşen: ${kayit['gerceklesen_saat']}',
                                      ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: durumRengi(kayit).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    gecikmeMetni(kayit),
                                    style: TextStyle(
                                      color: durumRengi(kayit),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _istatistikKarti(String baslik, String deger, Color renk, IconData ikon) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(ikon, color: renk, size: 32),
          SizedBox(height: 8),
          Text(
            deger,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          SizedBox(height: 4),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}