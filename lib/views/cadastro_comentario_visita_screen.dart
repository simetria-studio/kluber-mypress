import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CadastroComentarioVisitaScreen extends StatefulWidget {
  final int visitaId;

  const CadastroComentarioVisitaScreen({
    super.key,
    required this.visitaId,
  });

  @override
  State<CadastroComentarioVisitaScreen> createState() =>
      _CadastroComentarioVisitaScreenState();
}

class _CadastroComentarioVisitaScreenState
    extends State<CadastroComentarioVisitaScreen> {
  final _comentarioController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarComentarioAtual();
  }

  Future<void> _carregarComentarioAtual() async {
    try {
      final visita = await DatabaseHelper.instance.getVisita(widget.visitaId);
      _comentarioController.text = visita.comentario;
    } catch (_) {
      // Se não conseguir carregar, mantém campo vazio para o usuário preencher.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _finalizarCadastro() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await DatabaseHelper.instance.updateComentarioVisita(
        widget.visitaId,
        _comentarioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro finalizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar cadastro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Comentário da Visita',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFABA00)),
            )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finalize a visita com um comentário geral (opcional).',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _comentarioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Comentário',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.comment, color: Color(0xFFFABA00)),
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _finalizarCadastro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFABA00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'FINALIZAR',
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
    );
  }
}
