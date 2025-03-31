import 'package:flutter/material.dart';
import '../models/problema_model.dart';
import '../database/database_helper.dart';

class CadastroProblemaScreen extends StatefulWidget {
  final int visitaId;
  final Problema? problema;

  const CadastroProblemaScreen({
    super.key,
    required this.visitaId,
    this.problema,
  });

  @override
  State<CadastroProblemaScreen> createState() => _CadastroProblemaScreenState();
}

class _CadastroProblemaScreenState extends State<CadastroProblemaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _problemaRedutorPrincipal = false;
  bool _problemaTemperatura = false;
  bool _problemaTamborPrincipal = false;

  final _comentarioRedutorController = TextEditingController();
  final _comentarioTemperaturaController = TextEditingController();
  final _comentarioTamborController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.problema != null) {
      _problemaRedutorPrincipal =
          widget.problema!.problemaRedutorPrincipal == 1;
      _problemaTemperatura = widget.problema!.problemaTemperatura == 1;
      _problemaTamborPrincipal = widget.problema!.problemaTamborPrincipal == 1;
      _comentarioRedutorController.text =
          widget.problema!.comentarioRedutorPrincipal ?? '';
      _comentarioTemperaturaController.text =
          widget.problema!.comentarioTemperatura ?? '';
      _comentarioTamborController.text =
          widget.problema!.comentarioTamborPrincipal ?? '';
    }
  }

  Future<void> _salvarProblema() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final problema = Problema(
          id: widget.problema?.id,
          problemaRedutorPrincipal: _problemaRedutorPrincipal ? 1 : 0,
          comentarioRedutorPrincipal: _comentarioRedutorController.text,
          problemaTemperatura: _problemaTemperatura ? 1 : 0,
          comentarioTemperatura: _comentarioTemperaturaController.text,
          problemaTamborPrincipal: _problemaTamborPrincipal ? 1 : 0,
          comentarioTamborPrincipal: _comentarioTamborController.text,
          myPressVisitaId: widget.visitaId,
        );

        if (widget.problema != null) {
          await DatabaseHelper.instance.updateProblema(problema);
        } else {
          await DatabaseHelper.instance.createProblema(problema);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.problema != null
                  ? 'Problema atualizado com sucesso!'
                  : 'Problema cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar problema: ${e.toString()}'),
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

  Widget _buildProblemSection({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFABA00),
          contentPadding: EdgeInsets.zero,
        ),
        if (value)
          TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Descreva o problema...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFFFABA00).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFFFABA00).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFABA00),
                ),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Por favor, descreva o problema';
              }
              return null;
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Cadastrar Problemas',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProblemSection(
                  title: 'Problema no Redutor Principal',
                  value: _problemaRedutorPrincipal,
                  onChanged: (value) {
                    setState(() {
                      _problemaRedutorPrincipal = value;
                    });
                  },
                  controller: _comentarioRedutorController,
                ),
                _buildProblemSection(
                  title: 'Problema de Temperatura',
                  value: _problemaTemperatura,
                  onChanged: (value) {
                    setState(() {
                      _problemaTemperatura = value;
                    });
                  },
                  controller: _comentarioTemperaturaController,
                ),
                _buildProblemSection(
                  title: 'Problema no Tambor Principal',
                  value: _problemaTamborPrincipal,
                  onChanged: (value) {
                    setState(() {
                      _problemaTamborPrincipal = value;
                    });
                  },
                  controller: _comentarioTamborController,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _salvarProblema,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SALVAR PROBLEMAS',
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
    _comentarioRedutorController.dispose();
    _comentarioTemperaturaController.dispose();
    _comentarioTamborController.dispose();
    super.dispose();
  }
}
