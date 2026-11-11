import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:io';
import '../models/anexo_comentario_model.dart';
import '../database/database_helper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CadastroAnexoScreen extends StatefulWidget {
  final int comentarioId;

  const CadastroAnexoScreen({
    super.key,
    required this.comentarioId,
  });

  @override
  State<CadastroAnexoScreen> createState() => _CadastroAnexoScreenState();
}

class _CadastroAnexoScreenState extends State<CadastroAnexoScreen> {
  File? _imageFile;
  String? _nomeArquivo;
  bool _isLoading = false;

  Future<void> _tirarFoto() async {
    final ImagePicker picker = ImagePicker();

    // Mostrar opções para o usuário
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFABA00)),
                title:
                    const Text('Câmera', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo =
                      await picker.pickImage(source: ImageSource.camera);
                  _processarImagem(photo);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFFFABA00)),
                title: const Text('Galeria',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  _processarImagem(image);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processarImagem(XFile? imageFile) async {
    if (imageFile != null) {
      try {
        // Converter XFile para File
        final File originalFile = File(imageFile.path);
        final String targetPath = originalFile.path.replaceAll(
          '.${originalFile.path.split('.').last}',
          '_compressed.jpg',
        );

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          originalFile.path,
          targetPath,
          quality: 70,
          format: CompressFormat.jpeg,
          minWidth: 1024, // Adiciona limite de largura
          minHeight: 1024, // Adiciona limite de altura
        );

        if (compressedFile != null) {
          final originalName = p.basename(imageFile.path);
          setState(() {
            _imageFile = File(compressedFile.path);
            _nomeArquivo = originalName.contains('.')
                ? '${p.basenameWithoutExtension(originalName)}.jpg'
                : '$originalName.jpg';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao processar imagem: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _salvarAnexo() async {
    if (_imageFile != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        final bytes = await _imageFile!.readAsBytes();
        final base64Image = base64Encode(bytes);

        final extension = _imageFile!.path.split('.').last.toLowerCase();
        final mimeType = 'image/$extension';

        final anexo = AnexoComentario(
          nome: _nomeArquivo ?? p.basename(_imageFile!.path),
          tipo: mimeType,
          url: _imageFile!.path,
          base64: base64Image,
          comentarioId: widget.comentarioId,
        );

        await DatabaseHelper.instance.createAnexoComentario(anexo);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anexo salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar anexo: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Adicionar Anexo',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_imageFile != null) ...[
                  if (_nomeArquivo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.attachment,
                              color: Color(0xFFFABA00), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _nomeArquivo!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _tirarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      _imageFile == null ? 'SELECIONAR ARQUIVO' : 'TROCAR ARQUIVO',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading || _imageFile == null ? null : _salvarAnexo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      disabledBackgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'SALVAR ANEXO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
