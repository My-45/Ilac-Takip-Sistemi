import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class IlacDetayScreen extends StatefulWidget {
  final String ilacId;
  final Map<dynamic, dynamic> ilacBilgileri;

  const IlacDetayScreen({
    Key? key,
    required this.ilacId,
    required this.ilacBilgileri,
  }) : super(key: key);

  @override
  State<IlacDetayScreen> createState() => _IlacDetayScreenState();
}

class _IlacDetayScreenState extends State<IlacDetayScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late TextEditingController ilacAdiController;
  late TextEditingController dozController;
  late TextEditingController saatController;
  bool duzenlemeModu = false;

  @override
  void initState() {
    super.initState();
    ilacAdiController = TextEditingController(
      text: widget.ilacBilgileri['ilac_adi'] ?? '',
    );
    dozController = TextEditingController(
      text: widget.ilacBilgileri['doz'] ?? '',
    );
    saatController = TextEditingController(
      text: widget.ilacBilgileri['saat'] ?? '',
    );
  }

  @override
  void dispose() {
    ilacAdiController.dispose();
    dozController.dispose();
    saatController.dispose();
    super.dispose();
  }

  void ilacGuncelle() async {
    try {
      await _database.child('kullanicilar/test_user_1/ilaclar/${widget.ilacId}').update({
        'ilac_adi': ilacAdiController.text,
        'doz': dozController.text,
        'saat': saatController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ İlaç güncellendi!')),
      );
      
      setState(() {
        duzenlemeModu = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e')),
      );
    }
  }

  void ilacSil() async {
    // Onay dialogu göster
    bool? onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İlacı Sil'),
        content: Text('${widget.ilacBilgileri['ilac_adi']} ilacını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await _database.child('kullanicilar/test_user_1/ilaclar/${widget.ilacId}').remove();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ İlaç silindi!')),
        );
        
        Navigator.pop(context, true); // Geri dön ve listeyi yenile
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ilacBilgileri['ilac_adi'] ?? 'İlaç Detayı'),
        backgroundColor: Colors.blue,
        actions: [
          if (!duzenlemeModu)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  duzenlemeModu = true;
                });
              },
              tooltip: 'Düzenle',
            ),
          if (!duzenlemeModu)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: ilacSil,
              tooltip: 'Sil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlaç ikonu
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 24),

            // İlaç Bilgileri
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlaç Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // İlaç Adı
                    TextField(
                      controller: ilacAdiController,
                      enabled: duzenlemeModu,
                      decoration: InputDecoration(
                        labelText: 'İlaç Adı',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Doz
                    TextField(
                      controller: dozController,
                      enabled: duzenlemeModu,
                      decoration: InputDecoration(
                        labelText: 'Doz',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Saat
                    TextField(
                      controller: saatController,
                      enabled: duzenlemeModu,
                      decoration: InputDecoration(
                        labelText: 'Saat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Durum
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.circle, 
                        color: widget.ilacBilgileri['aktif'] == true 
                          ? Colors.green 
                          : Colors.grey,
                      ),
                      title: Text(
                        widget.ilacBilgileri['aktif'] == true 
                          ? 'Aktif' 
                          : 'Pasif',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Kullanım Geçmişi (Şimdilik placeholder)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullanım Geçmişi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Henüz kayıt yok',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Düzenleme modundaysa kaydet/iptal butonları
            if (duzenlemeModu)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // İptal - değişiklikleri geri al
                          ilacAdiController.text = widget.ilacBilgileri['ilac_adi'] ?? '';
                          dozController.text = widget.ilacBilgileri['doz'] ?? '';
                          saatController.text = widget.ilacBilgileri['saat'] ?? '';
                          
                          setState(() {
                            duzenlemeModu = false;
                          });
                        },
                        child: Text('İptal'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: ilacGuncelle,
                        child: Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}