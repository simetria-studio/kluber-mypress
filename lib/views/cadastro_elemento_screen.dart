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

  // Adicione esta lista de tipos de elementos
  final List<String> _tiposElementos = [
    'Bend rods',
    'Cinta metálica',
    'Corrente'
  ];
  String? _tipoElementoSelecionado;

  // Adicione esta lista de posições
  final List<String> _posicoes = ['Superior', 'Inferior'];
  String? _posicaoSelecionada;

  @override
  void initState() {
    super.initState();
    _consumo2Controller.addListener(_calcularSoma);
    _consumo3Controller.addListener(_calcularSoma);
  }

  void _calcularSoma() {
    try {
      final consumo2 = double.tryParse(_consumo2Controller.text) ?? 0;
      final consumo3 = double.tryParse(_consumo3Controller.text) ?? 0;
      final soma = consumo2 + consumo3;
      _tomaController.text = soma.toString();
    } catch (e) {
      _tomaController.text = '';
    }
  }

  void _salvarElemento() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Verificar se os campos obrigatórios estão preenchidos
        if (_tipoElementoSelecionado == null) {
          throw Exception('Por favor, selecione o tipo do elemento');
        }

        if (_tipoElementoSelecionado != 'Bend rods' && _posicaoSelecionada == null) {
          throw Exception('Por favor, selecione a posição');
        }

        final elemento = Elemento(
          consumo1: double.parse(_consumo1Controller.text),
          consumo2: double.parse(_consumo2Controller.text),
          consumo3: double.parse(_consumo3Controller.text),
          toma: _tomaController.text,
          posicao: _posicaoSelecionada ?? 'N/A', // Usar 'N/A' como valor padrão para Bend rods
          tipo: _tipoElementoSelecionado!,
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
        print(e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
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
                DropdownButtonFormField<String>(
                  value: _tipoElementoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.category, color: Color(0xFFFABA00)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFFFABA00)),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  items: _tiposElementos.map((String tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _tipoElementoSelecionado = newValue;
                      if (newValue != 'Bend rods') {
                        _posicaoSelecionada = null;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o tipo do elemento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Visibility(
                  visible: _tipoElementoSelecionado != 'Bend rods',
                  child: DropdownButtonFormField<String>(
                    value: _posicaoSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Posição',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.place, color: Color(0xFFFABA00)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFABA00)),
                      ),
                      border: UnderlineInputBorder(),
                    ),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFFFABA00)),
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    items: _posicoes.map((String posicao) {
                      return DropdownMenuItem<String>(
                        value: posicao,
                        child: Text(posicao),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _posicaoSelecionada = newValue;
                      });
                    },
                    validator: (value) {
                      if (_tipoElementoSelecionado != 'Bend rods' && (value == null || value.isEmpty)) {
                        return 'Por favor, selecione a posição';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consumo1Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Consumo Nominal',
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'g/h',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consumo2Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Consumo Real',
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'g/h',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consumo3Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Consumo Real Adicional',
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'g/h',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tomaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Soma',
                    prefixIcon: Icon(Icons.settings_input_component,
                        color: Color(0xFFFABA00)),
                  ),
                  enabled: false,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
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
    _consumo2Controller.removeListener(_calcularSoma);
    _consumo3Controller.removeListener(_calcularSoma);
    _consumo1Controller.dispose();
    _consumo2Controller.dispose();
    _consumo3Controller.dispose();
    _tomaController.dispose();
    _posicaoController.dispose();
    _tipoController.dispose();
    super.dispose();
  }
}
