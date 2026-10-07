import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colegio Dante Alighieri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFF007373),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- PANTALLA LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verificarLogin() async {
    final user = _userController.text.trim();
    final password = _passController.text.trim();

    if (user.isEmpty || password.isEmpty) {
      _mostrarAlerta("Campos Incompletos", "Por favor, llene los dos campos.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$apiUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user": user}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final rowData = jsonDecode(response.body);
        final ndocApoDb = (rowData["NDocApo"] ?? rowData["ndocapo"] ?? "").toString().trim();
        final nombreApoderado = rowData["Apoderado"] ?? rowData["apoderado"] ?? "Apoderado Registrado";
        final nombreEstudiante = rowData["estudiante"] ?? rowData["Estudiante"] ?? "Estudiante";
        final idAlumno = rowData["Id_alumno"] ?? rowData["id_alumno"] ?? rowData["Id_Alumno"];

        if (password == ndocApoDb) {
          final datosAlumno = {
            "codigo": user,
            "nombre_completo": nombreEstudiante,
            "nro_doc": password,
            "id_alumno": idAlumno,
            "apoderado": nombreApoderado,
            "grado": "-",
            "seccion": "-",
            "turno": "-"
          };

          // CAPTURAR TOKEN FCM DE FIREBASE
          _registrarTokenFCM(idAlumno);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(datosAlumno: datosAlumno)),
          );
        } else {
          _mostrarAlerta("Error de Acceso", "La contraseña es incorrecta.");
        }
      } else {
        _mostrarAlerta("Error de Acceso", "El código de alumno no existe.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarAlerta("Error de Conexión", "No se pudo conectar con el servidor.");
    }
  }

  Future<void> _registrarTokenFCM(dynamic idAlumno) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        if (token != null) {
          await http.post(
            Uri.parse("$apiUrl/registrar_token_fcm"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"id_alumno": idAlumno, "token_fcm": token}),
          );
          print("Token FCM registrado exitosamente: $token");
        }
      }
    } catch (e) {
      print("Error registrando token FCM nativo: $e");
    }
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/escudodante.png', width: 120, height: 120, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 100, color: Color(0xFF007373))),
              const SizedBox(height: 10),
              const Text("COLEGIO DANTE ALIGHIERI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF007373)), textAlign: TextAlign.center),
              const Text("Aplicativo Institucional", style: TextStyle(fontSize: 14, color: Color(0xFF6699CC)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(controller: _userController, decoration: const InputDecoration(labelText: "Usuario (Código)", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A6A6)),
                  onPressed: _isLoading ? null : _verificarLogin,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("INGRESAR", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA HOME ---
class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> datosAlumno;
  const HomeScreen({super.key, required this.datosAlumno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 330,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE2EFF8), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Apoderado: ${datosAlumno['apoderado']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF007373))),
                    Text("Estudiante: ${datosAlumno['nombre_completo']}", style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("MENÚ PRINCIPAL", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008080), fontSize: 16)),
              const SizedBox(height: 15),
              _buildMenuButton(context, "1. Información del Estudiante Matriculado", () => Navigator.push(context, MaterialPageRoute(builder: (c) => EstudianteScreen(datosAlumno: datosAlumno)))),
              _buildMenuButton(context, "2. Estado de Cuenta - PAGOS", () => Navigator.push(context, MaterialPageRoute(builder: (c) => PagosScreen(idAlumno: datosAlumno['id_alumno'])))),
              _buildMenuButton(context, "3. Comunicados Informativos", () => Navigator.push(context, MaterialPageRoute(builder: (c) => ComunicadosScreen(idAlumno: datosAlumno['id_alumno'])))),
              const SizedBox(height: 20),
              SizedBox(
                width: 330,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen())),
                  child: const Text("4. Salir del sistema"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      width: 330,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A6A6), padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}

// --- PANTALLA ESTUDIANTE ---
class EstudianteScreen extends StatelessWidget {
  final Map<String, dynamic> datosAlumno;
  const EstudianteScreen({super.key, required this.datosAlumno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text("INFORMACIÓN DEL ESTUDIANTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF007373))),
              const SizedBox(height: 15),
              Container(
                width: 330,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE2EFF8), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CÓDIGO INTERNO", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("${datosAlumno['codigo']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(),
                    const Text("APELLIDOS Y NOMBRES", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("${datosAlumno['nombre_completo']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Divider(),
                    const Text("NRO. DOCUMENTO", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("${datosAlumno['nro_doc']}", style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 330,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A6A6)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("VOLVER AL MENÚ", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA PAGOS ---
class PagosScreen extends StatelessWidget {
  final dynamic idAlumno;
  const PagosScreen({super.key, required this.idAlumno});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ESTADO DE CUENTA - PAGOS", style: TextStyle(fontSize: 16, color: Color(0xFF007373))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF007373),
            tabs: [Tab(text: "Pendientes"), Tab(text: "Historial Pagos")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList("$apiUrl/cuotas_pendientes?id=$idAlumno", true),
            _buildList("$apiUrl/cuotas_pagadas?id=$idAlumno", false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String url, bool esPendiente) {
    return FutureBuilder(
      future: http.get(Uri.parse(url)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        List items = jsonDecode(snapshot.data!.body);
        if (items.isEmpty) return const Center(child: Text("No hay registros."));
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: esPendiente ? const Color(0xFFFFE6E6) : const Color(0xE6FFE6E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("Comprobante: ${item['Comprobante'] ?? '-'} | Total: S/. ${item['Total'] ?? '0.00'}"),
            );
          },
        );
      },
    );
  }
}

// --- PANTALLA COMUNICADOS ---
class ComunicadosScreen extends StatelessWidget {
  final dynamic idAlumno;
  const ComunicadosScreen({super.key, required this.idAlumno});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("COMUNICADOS INFORMATIVOS", style: TextStyle(fontSize: 16, color: Color(0xFF007373))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF007373),
            tabs: [Tab(text: "No Leídos"), Tab(text: "Historial / Leídos")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildComunicadosList("$apiUrl/comunicados_no_leidos?id=$idAlumno"),
            _buildComunicadosList("$apiUrl/comunicados_leidos?id=$idAlumno"),
          ],
        ),
      ),
    );
  }

  Widget _buildComunicadosList(String url) {
    return FutureBuilder(
      future: http.get(Uri.parse(url)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        List items = jsonDecode(snapshot.data!.body);
        if (items.isEmpty) return const Center(child: Text("No tienes comunicados registrados."));
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index];
            return Card(
              child: ListTile(
                title: Text(item['Asunto'] ?? 'Sin Asunto', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Emitido: ${item['Fecha'] ?? '-'}"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(item['Asunto'] ?? 'Detalle'),
                      content: Text(item['Detalle'] ?? 'Sin contenido.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("CERRAR"))],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
