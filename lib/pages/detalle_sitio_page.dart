import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetalleSitioPage extends StatefulWidget {
  final String sitioId;
  final String userRole;
  final String userId;

  const DetalleSitioPage({
    required this.sitioId,
    required this.userRole,
    required this.userId,
  });

  @override
  State<DetalleSitioPage> createState() => _DetalleSitioPageState();
}

class _DetalleSitioPageState extends State<DetalleSitioPage> {
  final _resenaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Sitio'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('sitios')
            .doc(widget.sitioId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final imagenes = List<String>.from(data['imagenes'] ?? []);
          final puedeResponder =
              widget.userRole == 'publicador' &&
              data['creadorUid'] == widget.userId;

          return Column(
            children: [
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: imagenes
                      .map(
                        (b64) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.memory(
                            base64Decode(b64),
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['titulo'] ?? 'Sin título',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['ubicacion'] ?? 'Sin ubicación',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Text(data['descripcion'] ?? ''),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reseñas')
                      .where('sitioId', isEqualTo: widget.sitioId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar reseñas:\n${snapshot.error}',
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Sé el primero en dejar una reseña.'),
                      );
                    }

                    List<DocumentSnapshot> resenasDocs = snapshot.data!.docs;

                    resenasDocs.sort((a, b) {
                      final aFecha = (a['creadoEn'] as Timestamp?)?.toDate();
                      final bFecha = (b['creadoEn'] as Timestamp?)?.toDate();
                      if (aFecha == null || bFecha == null) return 0;
                      return bFecha.compareTo(aFecha);
                    });

                    return ListView.builder(
                      itemCount: resenasDocs.length,
                      itemBuilder: (context, index) {
                        final resData =
                            resenasDocs[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(resData['comentario'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (resData['respuestaAdmin'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Respuesta: ${resData['respuestaAdmin']}',
                                      style: TextStyle(color: Colors.teal[700]),
                                    ),
                                  ),
                                if (puedeResponder &&
                                    resData['respuestaAdmin'] == null)
                                  TextButton(
                                    onPressed: () =>
                                        _responderResena(resenasDocs[index].id),
                                    child: const Text(
                                      'Responder como publicador',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _resenaController,
                        decoration: const InputDecoration(
                          labelText: 'Escribe una reseña',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.teal),
                      onPressed: _enviarResena,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _enviarResena() async {
    final texto = _resenaController.text.trim();
    if (texto.isEmpty) return;

    await FirebaseFirestore.instance.collection('reseñas').add({
      'sitioId': widget.sitioId,
      'comentario': texto,
      'creadorUid': widget.userId,
      'creadoEn': FieldValue.serverTimestamp(),
    });

    _resenaController.clear();
  }

  void _responderResena(String resenaId) {
    TextEditingController _respuestaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Responder reseña'),
        content: TextField(
          controller: _respuestaCtrl,
          decoration: const InputDecoration(hintText: 'Respuesta...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final respuesta = _respuestaCtrl.text.trim();
              if (respuesta.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('reseñas')
                    .doc(resenaId)
                    .update({'respuestaAdmin': respuesta});
              }
              Navigator.pop(context);
            },
            child: const Text('Responder'),
          ),
        ],
      ),
    );
  }
}
