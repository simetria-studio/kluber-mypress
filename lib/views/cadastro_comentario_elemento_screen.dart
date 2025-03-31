import 'package:flutter/material.dart';
import '../models/comentario_elemento_model.dart';
import '../database/database_helper.dart';

class CadastroComentarioElementoScreen extends StatefulWidget {
  final int elementoId;

  const CadastroComentarioElementoScreen({
    super.key,
    required this.elementoId,
  });

  @override
  State<CadastroComentarioElementoScreen> createState() =>
      _CadastroComentarioElementoScreenState();
}

class _CadastroComentarioElementoScreenState
    extends State<CadastroComentarioElementoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();

  void _salvarComentario() async {
    if (_formKey.currentState!.validate()) {
      try {
        final comentario = ComentarioElemento(
          comentario: _comentarioController.text,
          elementoId: widget.elementoId,
        );

        await DatabaseHelper.instance.createComentarioElemento(comentario);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comentário salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar comentário: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
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
          'Adicionar Comentário',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _comentarioController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Comentário',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um comentário';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _salvarComentario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SALVAR COMENTÁRIO',
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
      ),
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }
} 