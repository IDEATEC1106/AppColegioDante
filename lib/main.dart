import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const String apiUrl = "http://38.224.68.171:5000/api";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colegio Dante Alighieri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario": _userController.text,
          "password": _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final int idAlumno = data["id_alumno"];
          _registrarTokenFCM(idAlumno);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainMenuScreen(idAlumno: idAlumno),
            ),
          );
        } else {
          _showError(data["message"] ?? "Credenciales incorrectas");
        }
      } else {
        _showError("Error de conexión con el servidor");
      }
    } catch (e) {
      _showError("Error de red: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarTokenFCM(int idAlumno) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await http.post(
          Uri.parse("$apiUrl/registrar_token_fcm"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"id_alumno": idAlumno, "token_fcm": token}),
        );
      }
    } catch (e) {
      debugPrint("Error token FCM: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/escudodante.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                'Colegio Dante Alighieri',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Ingresar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  final int idAlumno;

  const MainMenuScreen({super.key, required this.idAlumno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú Principal')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Estado de Pagos'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PagosScreen(idAlumno: idAlumno),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.announcement),
            title: const Text('Comunicados'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComunicadosScreen(idAlumno: idAlumno),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PagosScreen extends StatelessWidget {
  final int idAlumno;

  const PagosScreen({super.key, required this.idAlumno});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Pagadas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList("$apiUrl/cuotas_pendientes?id=$idAlumno"),
            _buildList("$apiUrl/cuotas_pagadas?id=$idAlumno"),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String url) {
    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse(url)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
          return const Center(child: Text("Error al cargar datos"));
        }
        List items = jsonDecode(snapshot.data!.body);
        if (items.isEmpty) {
          return const Center(child: Text("No hay registros"));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item['concepto'] ?? 'Cuota'),
              subtitle: Text("Monto: S/ ${item['monto']}"),
            );
          },
        );
      },
    );
  }
}

class ComunicadosScreen extends StatelessWidget {
  final int idAlumno;

  const ComunicadosScreen({super.key, required this.idAlumno});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comunicados'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'No Leídos'),
              Tab(text: 'Leídos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList("$apiUrl/comunicados_no_leidos?id=$idAlumno"),
            _buildList("$apiUrl/comunicados_leidos?id=$idAlumno"),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String url) {
    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse(url)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
          return const Center(child: Text("Error al cargar datos"));
        }
        List items = jsonDecode(snapshot.data!.body);
        if (items.isEmpty) {
          return const Center(child: Text("No hay comunicados"));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item['titulo'] ?? 'Comunicado'),
              subtitle: Text(item['mensaje'] ?? ''),
            );
          },
        );
      },
    );
  }
}
