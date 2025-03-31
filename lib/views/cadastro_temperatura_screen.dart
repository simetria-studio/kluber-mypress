import 'package:flutter/material.dart';
import '../models/elemento_model.dart';
import '../models/temperatura_elemento_model.dart';
import '../database/database_helper.dart';

class CadastroTemperaturaScreen extends StatefulWidget {
  final Elemento elemento;

  const CadastroTemperaturaScreen({
    super.key,
    required this.elemento,
  });

  @override
  State<CadastroTemperaturaScreen> createState() => _CadastroTemperaturaScreenState();
}

class _CadastroTemperaturaScreenState extends State<CadastroTemperaturaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zona1Controller = TextEditingController();
  final _zona2Controller = TextEditingController();
  final _zona3Controller = TextEditingController();
  final _zona4Controller = TextEditingController();
  final _zona5Controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _salvarTemperatura() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final temperatura = TemperaturaElemento(
          dataRegistro: DateTime.now().toIso8601String(),
          zona1: _zona1Controller.text.isNotEmpty ? double.parse(_zona1Controller.text) : null,
          zona2: _zona2Controller.text.isNotEmpty ? double.parse(_zona2Controller.text) : null,
          zona3: _zona3Controller.text.isNotEmpty ? double.parse(_zona3Controller.text) : null,
          zona4: _zona4Controller.text.isNotEmpty ? double.parse(_zona4Controller.text) : null,
          zona5: _zona5Controller.text.isNotEmpty ? double.parse(_zona5Controller.text) : null,
          elementoId: widget.elemento.id!,
        );

        await DatabaseHelper.instance.createTemperaturaElemento(temperatura);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Temperatura salva com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar temperatura: ${e.toString()}'),
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
          'Nova Temperatura',
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
                  controller: _zona1Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Zona 1',
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    suffixText: '°C',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _zona2Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Zona 2',
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    suffixText: '°C',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _zona3Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Zona 3',
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    suffixText: '°C',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _zona4Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Zona 4',
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    suffixText: '°C',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _zona5Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Zona 5',
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    suffixText: '°C',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _salvarTemperatura,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
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
                            'SALVAR TEMPERATURA',
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
    _zona1Controller.dispose();
    _zona2Controller.dispose();
    _zona3Controller.dispose();
    _zona4Controller.dispose();
    _zona5Controller.dispose();
    super.dispose();
  }
} 