import 'package:flutter/material.dart';
import '../models/elemento_model.dart';
import '../models/temperatura_elemento_model.dart';
import '../database/database_helper.dart';

class TemperaturaElementoScreen extends StatefulWidget {
  final Elemento elemento;

  const TemperaturaElementoScreen({
    super.key,
    required this.elemento,
  });

  @override
  State<TemperaturaElementoScreen> createState() =>
      _TemperaturaElementoScreenState();
}

class _TemperaturaElementoScreenState extends State<TemperaturaElementoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zona1Controller = TextEditingController();
  final _zona2Controller = TextEditingController();
  final _zona3Controller = TextEditingController();
  final _zona4Controller = TextEditingController();
  final _zona5Controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _salvarTemperaturas() async {
    print('Iniciando salvamento de temperaturas...');
    if (_formKey.currentState!.validate()) {
      print('Formulário validado com sucesso');
      setState(() {
        _isLoading = true;
      });

      try {
        print('Criando objeto TemperaturaElemento...');
        final temperatura = TemperaturaElemento(
          dataRegistro: DateTime.now().toIso8601String(),
          elementoId: widget.elemento.id!,
          zona1: _zona1Controller.text.isNotEmpty
              ? double.parse(_zona1Controller.text)
              : null,
          zona2: _zona2Controller.text.isNotEmpty
              ? double.parse(_zona2Controller.text)
              : null,
          zona3: _zona3Controller.text.isNotEmpty
              ? double.parse(_zona3Controller.text)
              : null,
          zona4: _zona4Controller.text.isNotEmpty
              ? double.parse(_zona4Controller.text)
              : null,
          zona5: _zona5Controller.text.isNotEmpty
              ? double.parse(_zona5Controller.text)
              : null,
        );

        print('Elemento ID: ${widget.elemento.id}');
        print('Temperatura antes de salvar: ${temperatura.toMap()}');

        print('Chamando DatabaseHelper.createTemperaturaElemento...');
        await DatabaseHelper.instance.createTemperaturaElemento(temperatura);
        print('Temperatura salva com sucesso!');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Temperaturas registradas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('Erro ao salvar temperatura: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao registrar temperaturas: ${e.toString()}'),
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
    } else {
      print('Formulário inválido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Registrar Temperaturas',
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
                Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: const Color(0xFFFABA00).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: Color(0xFFFABA00),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Temperaturas',
                              style: TextStyle(
                                color: Color(0xFFFABA00),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFFFABA00), height: 24),
                        _buildTemperaturaField(_zona1Controller, 'Zona 1'),
                        const SizedBox(height: 16),
                        _buildTemperaturaField(_zona2Controller, 'Zona 2'),
                        const SizedBox(height: 16),
                        _buildTemperaturaField(_zona3Controller, 'Zona 3'),
                        const SizedBox(height: 16),
                        _buildTemperaturaField(_zona4Controller, 'Zona 4'),
                        const SizedBox(height: 16),
                        _buildTemperaturaField(_zona5Controller, 'Zona 5'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.save, color: Colors.black),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'REGISTRAR TEMPERATURAS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    onPressed: _isLoading ? null : _salvarTemperaturas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      disabledBackgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildTemperaturaField(
      TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.thermostat, color: Color(0xFFFABA00)),
        suffixText: '°C',
      ),
      keyboardType: TextInputType.number,
    );
  }

  @override
  void dispose() {
    _zona1Controller.dispose();
    _zona2Controller.dispose();
    _zona3Controller.dispose();
    _zona4Controller.dispose();
    _zona5Controller.dispose();
    super.dispose();
  }
}
