import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../database/database_helper.dart';
import 'selecionar_elemento_screen.dart';

class CadastroPrensaScreen extends StatefulWidget {
  final int visitaId;

  const CadastroPrensaScreen({
    super.key,
    required this.visitaId,
  });

  @override
  State<CadastroPrensaScreen> createState() => _CadastroPrensaScreenState();
}

class _CadastroPrensaScreenState extends State<CadastroPrensaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fabricanteController = TextEditingController();
  final _comprimentoController = TextEditingController();
  final _espessuraController = TextEditingController();
  final _produtoController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _produtoCintaController = TextEditingController();
  final _produtoCorrenteController = TextEditingController();
  final _produtoBendroadsController = TextEditingController();

  final List<String> _tiposPrensas = [
    'Dieffenbacher',
    'Siempelkamp',
    'Kusters'
  ];
  String? _tipoPrensaSelecionado;

  final List<String> _tiposProdutos = ['MDF', 'HDF', 'MDP', 'OSB'];
  String? _produtoSelecionado;

  void _salvarPrensa() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prensa = Prensa(
          tipoPrensa: _tipoPrensaSelecionado!,
          fabricante: _fabricanteController.text,
          comprimento: double.parse(_comprimentoController.text),
          espessura: double.parse(_espessuraController.text),
          produto: _produtoSelecionado!,
          velocidade: double.parse(_velocidadeController.text),
          produtoCinta: _produtoCintaController.text,
          produtoCorrente: _produtoCorrenteController.text,
          produtoBendroads: _produtoBendroadsController.text,
          visitaId: widget.visitaId,
        );

        final prensaId = await DatabaseHelper.instance.createPrensa(prensa);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prensa cadastrada com sucesso!')),
          );

          // Adicionando um pequeno delay para garantir que o SnackBar seja exibido
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelecionarElementoScreen(
                  prensaId: prensaId,
                  visitaId: widget.visitaId,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Erro ao cadastrar prensa: ${e.toString()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao cadastrar prensa: ${e.toString()}')),
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
          'Cadastrar Prensa',
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
                  value: _tipoPrensaSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Prensa',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.precision_manufacturing,
                        color: Color(0xFFFABA00)),
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
                  items: _tiposPrensas.map((String tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _tipoPrensaSelecionado = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o tipo de prensa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fabricanteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Fabricante',
                    prefixIcon: Icon(Icons.factory, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _comprimentoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Comprimento',
                    prefixIcon:
                        Icon(Icons.straighten, color: Color(0xFFFABA00)),
                    suffixText: 'm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _espessuraController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Espessura',
                    prefixIcon: Icon(Icons.height, color: Color(0xFFFABA00)),
                    suffixText: 'mm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _produtoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Produto',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.inventory, color: Color(0xFFFABA00)),
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
                  items: _tiposProdutos.map((String produto) {
                    return DropdownMenuItem<String>(
                      value: produto,
                      child: Text(produto),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _produtoSelecionado = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o produto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _velocidadeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Velocidade',
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'm/min',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _produtoCintaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Produto Cinta',
                    prefixIcon:
                        Icon(Icons.inventory_2, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _produtoCorrenteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Produto Corrente',
                    prefixIcon: Icon(Icons.link, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _produtoBendroadsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Produto Bendroads',
                    prefixIcon: Icon(Icons.category, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _salvarPrensa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SALVAR PRENSA',
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
    _fabricanteController.dispose();
    _comprimentoController.dispose();
    _espessuraController.dispose();
    _produtoController.dispose();
    _velocidadeController.dispose();
    _produtoCintaController.dispose();
    _produtoCorrenteController.dispose();
    _produtoBendroadsController.dispose();
    super.dispose();
  }
}
