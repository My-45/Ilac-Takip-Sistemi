import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // true: Giriş (Login), false: Kayıt (SignUp)
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    // [1] İşlemin başlamasından önce loading state'i açılır
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (err) {
      
      // [2] Hata yakalandığında, BuildContext kullanmadan önce kontrol ederiz
      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message ?? 'Bir hata oluştu.')),
        );
      }
    } finally {
      // [3] İşlem bittiğinde (hata olsun veya olmasın) loading state'i kapatılır.
      // Bu işlemi de sadece widget hala monte edilmişse yaparız.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('İlaç Takip Sistemi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // E-posta Alanı
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Şifre Alanı
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              // Giriş/Kayıt Butonu
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submitAuthForm,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                  child: Text(_isLogin ? 'GİRİŞ YAP' : 'KAYIT OL'),
                ),
              
              const SizedBox(height: 10),

              // Geçiş Butonu
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin ? 'Hesabınız yok mu? Kayıt Olun' : 'Zaten hesabınız var mı? Giriş Yapın'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}