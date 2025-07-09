import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

import 'pages/home_publicador.dart';
import 'pages/home_visitante.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Turística',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RootPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => HomePage(),
        '/home_publicador': (context) => HomePublicador(),
        '/home_visitante': (context) =>
            HomeVisitante(), // <-- Agrega esta línea
      },
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Aquí puedes obtener el usuario y decidir a qué home navegar según el rol
          // Por ejemplo, si tienes un campo en Firestore o en el User para el rol:
          return FutureBuilder<String>(
            future: _getUserRole(snapshot.data),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (roleSnapshot.hasError || !roleSnapshot.hasData) {
                // Si hay error o no hay rol, regresa al login
                return const LoginPage();
              }
              if (roleSnapshot.data == 'publicador') {
                return HomePublicador();
              } else if (roleSnapshot.data == 'visitante') {
                return HomeVisitante();
              } else {
                // Si el rol no es válido, regresa al login
                return const LoginPage();
              }
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }

  // Este método obtiene el rol del usuario desde tu base de datos (Firestore)
  Future<String> _getUserRole(User? user) async {
    if (user == null) throw Exception('Usuario no autenticado');
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null || data['role'] == null) {
      throw Exception('No se encontró el rol del usuario');
    }
    return data['role'] as String;
  }
}
