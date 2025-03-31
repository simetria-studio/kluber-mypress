import 'package:flutter/material.dart';
import '../models/elemento_model.dart';
import '../database/database_helper.dart';

class CadastroElementoScreen extends StatefulWidget {
  final int prensaId;

  const CadastroElementoScreen({
    super.key,
    required this.prensaId,
  });

  @override
  State<CadastroElementoScreen> createState() => _CadastroElementoScreenState();
}

class _CadastroElementoScreenState extends State<CadastroElementoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumo1Controller = TextEditingController();
  final _consumo2Controller = TextEditingController();
  final _consumo3Controller = TextEditingController();
  final _tomaController = TextEditingController();
  final _posicaoController = TextEditingController();
  final _tipoController = TextEditingController();
  final _mypressController = TextEditingController();

  void _salvarElemento() async {
    if (_formKey.currentState!.validate()) {
      try {
        final elemento = Elemento(
          consumo1: double.parse(_consumo1Controller.text),
          consumo2: double.parse(_consumo2Controller.text),
          consumo3: double.parse(_consumo3Controller.text),
          toma: _tomaController.text,
          posicao: _posicaoController.text,
          tipo: _tipoController.text,
          mypress: _mypressController.text,
          prensaId: widget.prensaId,
        );

        await DatabaseHelper.instance.createElemento(elemento);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Elemento cadastrado com sucesso!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao cadastrar elemento')),
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
          'Cadastrar Elemento',
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
                  controller: _consumo1Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Consumo 1',
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'g/h',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consumo2Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Consumo 2',
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'g/h',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consumo3Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Consumo 3',
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'g/h',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tomaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Toma',
                    prefixIcon: Icon(Icons.settings_input_component, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _posicaoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Posição',
                    prefixIcon: Icon(Icons.place, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    prefixIcon: Icon(Icons.category, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mypressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'MyPress',
                    prefixIcon: Icon(Icons.precision_manufacturing, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _salvarElemento,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SALVAR ELEMENTO',
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
    _consumo1Controller.dispose();
    _consumo2Controller.dispose();
    _consumo3Controller.dispose();
    _tomaController.dispose();
    _posicaoController.dispose();
    _tipoController.dispose();
    _mypressController.dispose();
    super.dispose();
  }
} 