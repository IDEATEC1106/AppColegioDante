import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiUrl = "http://38.224.68.171:5000/api";

void main() {
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
        useMaterial3: false,
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
    if (_userController.text.trim().isEmpty) {
      _showError("Por favor, ingrese su usuario/código");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario": _userController.text.trim(),
          "password": _passController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["id_alumno"] != null) {
          final int idAlumno = int.parse(data["id_alumno"].toString());

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
        _showError("Respuesta del servidor (${response.statusCode})");
      }
    } catch (e) {
      _showError("Error de conexión con el servidor");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'escudodante.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.school, size: 100, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              const Text(
                'Colegio Dante Alighieri',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Usuario / Código',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'INGRESAR',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MENÚ PRINCIPAL ---
class MainMenuScreen extends StatelessWidget {
  final int idAlumno;

  const MainMenuScreen({super.key, required this.idAlumno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. INFORMACIÓN DEL ALUMNO
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.blue, size: 30),
              title: const Text('Información del Alumno'),
              subtitle: const Text('Datos personales, grado y sección'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfoAlumnoScreen(idAlumno: idAlumno),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 2. ESTADO DE PAGOS
          Card(
            child: ListTile(
              leading: const Icon(Icons.payment, color: Colors.blue, size: 30),
              title: const Text('Estado de Pagos'),
              subtitle: const Text('Consulta de cuotas pendientes y pagadas'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PagosScreen(idAlumno: idAlumno),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 3. COMUNICADOS
          Card(
            child: ListTile(
              leading: const Icon(Icons.announcement, color: Colors.blue, size: 30),
              title: const Text('Comunicados'),
              subtitle: const Text('Avisos y notas del colegio'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComunicadosScreen(idAlumno: idAlumno),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- PANTALLA INFORMACIÓN DEL ALUMNO ---
class InfoAlumnoScreen extends StatelessWidget {
  final int idAlumno;

  const InfoAlumnoScreen({super.key, required this.idAlumno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Alumno'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<http.Response>(
        future: http.get(Uri.parse("$apiUrl/alumno?id=$idAlumno")),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text("No se pudo cargar la información del alumno"));
          }

          final data = jsonDecode(snapshot.data!.body);
          if (data.isEmpty) {
            return const Center(child: Text("No se encontraron registros"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: data.entries.map<Widget>((entry) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      entry.key.toString().replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      entry.value?.toString() ?? 'N/A',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// --- PANTALLA PAGOS ---
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
          backgroundColor: Colors.blue,
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
          return const Center(child: Text("No hay cuotas registradas"));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            final String concepto = item['Conceptos'] ?? item['concepto'] ?? item['desc_concepto'] ?? 'Cuota';
            final String fecha = item['Fch_Ven'] ?? item['fch_ven'] ?? item['fec_venc'] ?? 'N/A';
            final String comprobante = item['Comprobante'] ?? '';
            final String monto = item['Total'] ?? item['monto'] ?? item['monto_cuota'] ?? '0.00';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.green),
                title: Text(
                  comprobante.isNotEmpty ? "$comprobante - $concepto" : concepto,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Fecha Vence: $fecha"),
                trailing: Text(
                  "S/ $monto",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- PANTALLA COMUNICADOS ---
class ComunicadosScreen extends StatefulWidget {
  final int idAlumno;

  const ComunicadosScreen({super.key, required this.idAlumno});

  @override
  State<ComunicadosScreen> createState() => _ComunicadosScreenState();
}

class _ComunicadosScreenState extends State<ComunicadosScreen> {

  Future<void> _marcarComoLeido(dynamic idComunica) async {
    if (idComunica == null) return;
    try {
      await http.post(
        Uri.parse("$apiUrl/actualizar_comunicado"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": idComunica}),
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _mostrarPopUpDetalle(BuildContext context, Map<String, dynamic> item, bool esNoLeido) {
    final String asunto = item['Asunto'] ?? item['comu_asunto'] ?? item['titulo'] ?? 'Comunicado';
    final String detalle = item['Detalle'] ?? item['comu_detalle'] ?? item['mensaje'] ?? 'Sin detalle';
    final String fecha = item['Fecha'] ?? item['comu_fecha'] ?? '';
    final String remitente = item['Remitente'] ?? '';
    final dynamic idComunica = item['id_comunica'] ?? item['id'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(asunto, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (remitente.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text("De: $remitente", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
                  ),
                if (fecha.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text("Fecha: $fecha", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                const Divider(),
                const SizedBox(height: 8),
                Text(detalle, style: const TextStyle(fontSize: 15, height: 1.3)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (esNoLeido && idComunica != null) {
                  await _marcarComoLeido(idComunica);
                }
              },
              child: const Text("CERRAR", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comunicados'),
          backgroundColor: Colors.blue,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'No Leídos'),
              Tab(text: 'Leídos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList("$apiUrl/comunicados_no_leidos?id=${widget.idAlumno}", true),
            _buildList("$apiUrl/comunicados_leidos?id=${widget.idAlumno}", false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String url, bool esNoLeido) {
    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse(url)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
          return const Center(child: Text("Error al cargar comunicados"));
        }

        List items = jsonDecode(snapshot.data!.body);
        if (items.isEmpty) {
          return const Center(child: Text("No hay comunicados"));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            final String asunto = item['Asunto'] ?? item['comu_asunto'] ?? item['titulo'] ?? 'Comunicado';
            final String fecha = item['Fecha'] ?? item['comu_fecha'] ?? '';
            final String remitente = item['Remitente'] ?? '';
            final String fechaLectura = item['Fecha_Lectura'] ?? item['Fch_Lectura'] ?? item['fecha_lectura'] ?? item['FechaLectura'] ?? item['Fecha'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      esNoLeido ? Icons.mark_email_unread : Icons.mark_email_read,
                      color: esNoLeido ? Colors.orange : Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (esNoLeido) ...[
                            // NO LEÍDOS: Fecha primero, luego Asunto, luego Remitente
                            if (fecha.isNotEmpty)
                              Text(
                                "Fecha: $fecha",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              asunto,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (remitente.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "De: $remitente",
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ] else ...[
                            // LEÍDOS: Asunto, Remitente y Fecha/Hora de lectura
                            Text(
                              asunto,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (remitente.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                "De: $remitente",
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                            if (fechaLectura.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Leído: $fechaLectura",
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _mostrarPopUpDetalle(context, item, esNoLeido),
                      child: const Text("Ver Detalle", style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
