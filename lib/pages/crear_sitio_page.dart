import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrearSitioPage extends StatefulWidget {
  final String? sitioId;
  final Map<String, dynamic>? sitioData;

  const CrearSitioPage({Key? key, this.sitioId, this.sitioData})
    : super(key: key);

  @override
  _CrearSitioPageState createState() => _CrearSitioPageState();
}

class _CrearSitioPageState extends State<CrearSitioPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _descripcionController = TextEditingController();

  List<String> _imagenesBase64 = [];
  List<Uint8List> _imagenesBytes = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.sitioData != null) {
      _tituloController.text = widget.sitioData!['titulo'] ?? '';
      _ubicacionController.text = widget.sitioData!['ubicacion'] ?? '';
      _descripcionController.text = widget.sitioData!['descripcion'] ?? '';
      if (widget.sitioData!['imagenes'] != null) {
        _imagenesBase64 = List<String>.from(widget.sitioData!['imagenes']);
        _imagenesBytes = _imagenesBase64
            .map((b64) => base64Decode(b64))
            .toList();
      }
    }
  }

  Future<void> _pickImage() async {
    if (_imagenesBase64.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solo se permiten hasta 5 imágenes')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      const maxSizeBytes = 1572864;
      if (bytes.length > maxSizeBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La imagen es demasiado grande. Máximo permitido: 1.5MB.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _imagenesBytes.add(bytes);
        _imagenesBase64.add(base64Encode(bytes));
      });
    }
  }

  Future<void> _saveSitio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagenesBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes subir al menos una imagen')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = {
      'titulo': _tituloController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'imagenes': _imagenesBase64,
      'creadorUid': user.uid,
      'creadoEn': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.sitioId == null) {
        await FirebaseFirestore.instance.collection('sitios').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('sitios')
            .doc(widget.sitioId)
            .update(data);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagenesBytes.removeAt(index);
      _imagenesBase64.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sitioId == null ? 'Crear Sitio' : 'Editar Sitio'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(labelText: 'Título'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _ubicacionController,
                  decoration: InputDecoration(labelText: 'Ubicación'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  decoration: InputDecoration(labelText: 'Descripción'),
                  maxLines: 4,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Imágenes (máx. 5):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagenesBytes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _imagenesBytes.length) {
                        return GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.teal.shade100,
                            ),
                            child: Icon(Icons.add_a_photo, size: 40),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: MemoryImage(_imagenesBytes[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveSitio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    widget.sitioId == null
                        ? 'Guardar Sitio'
                        : 'Actualizar Sitio',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
