import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../database/database_helper.dart';
import 'selecionar_elemento_screen.dart';

class CadastroPrensaScreen extends StatefulWidget {
  final int visitaId;
  final Prensa? prensa;

  const CadastroPrensaScreen({
    super.key,
    required this.visitaId,
    this.prensa,
  });

  @override
  State<CadastroPrensaScreen> createState() => _CadastroPrensaScreenState();
}

class _CadastroPrensaScreenState extends State<CadastroPrensaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fabricanteController = TextEditingController();
  final _comprimentoController = TextEditingController();
  final _espressuraController = TextEditingController();
  final _produtoController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _produtoCintaController = TextEditingController();
  final _produtoCorrenteController = TextEditingController();
  final _produtoBendroadsController = TextEditingController();

  final List<String> _fabricantes = [
    'Dieffenbacher',
    'Siempelkamp',
    'Kusters'
  ];
  String? _fabricanteSelecionado;

  final List<String> _tiposProdutos = ['MDF', 'HDF', 'MDP', 'OSB'];
  String? _produtoSelecionado;

  final List<String> _tiposProdutosCinta = [
    'Hotemp Super N',
    'Hotemp Super N Plus',
    'Klubersynh CP 2-260'
  ];
  String? _produtoCintaSelecionado;

  final List<String> _tiposProdutosCorrente = [
    'Hotemp Super CH 2-100',
    'Klubersynh CP 2-100',
    'Hotemp Super N',
    'Hotemp Super N Plus',
    'Klubersynh CP 2-260'
  ];
  String? _produtoCorrenteSelecionado;

  final List<String> _tiposProdutosBendroads = [
    'Hotemp Super CH 2-100',
    'Klubersynh CP 2-100'
  ];
  String? _produtoBendroadsSelecionado;

  @override
  void initState() {
    super.initState();
    if (widget.prensa != null) {
      _fabricanteSelecionado = widget.prensa!.fabricante;
      _comprimentoController.text = widget.prensa!.comprimento.toString();
      _espressuraController.text = widget.prensa!.espressura.toString();
      _produtoSelecionado = widget.prensa!.produto;
      _velocidadeController.text = widget.prensa!.velocidade.toString();
      _produtoCintaSelecionado = widget.prensa!.produtoCinta;
      _produtoCorrenteSelecionado = widget.prensa!.produtoCorrente;
      _produtoBendroadsSelecionado = widget.prensa!.produtoBendroads;
    }
  }

  void _salvarPrensa() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prensa = Prensa(
          id: widget.prensa?.id,
          visitaId: widget.visitaId,
          tipoPrensa: _fabricanteSelecionado!,
          fabricante: _fabricanteSelecionado!,
          comprimento: double.parse(_comprimentoController.text),
          espressura: double.parse(_espressuraController.text),
          produto: _produtoSelecionado!,
          velocidade: double.parse(_velocidadeController.text),
          produtoCinta: _produtoCintaSelecionado!,
          produtoCorrente: _produtoCorrenteSelecionado!,
          produtoBendroads: _produtoBendroadsSelecionado!,
        );

        if (widget.prensa != null) {
          await DatabaseHelper.instance.updatePrensa(prensa);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prensa atualizada com sucesso!')),
            );
            Navigator.pop(context, true);
          }
        } else {
          final prensaId = await DatabaseHelper.instance.createPrensa(prensa);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prensa cadastrada com sucesso!')),
            );
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
        }
      } catch (e) {
        print('Erro ao salvar prensa: ${e.toString()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar prensa: ${e.toString()}')),
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
        title: Text(
          widget.prensa != null ? 'Editar Prensa' : 'Cadastrar Prensa',
          style: const TextStyle(color: Color(0xFFFABA00)),
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
                  value: _fabricanteSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Fabricante',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.factory, color: Color(0xFFFABA00)),
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
                  items: _fabricantes.map((String fabricante) {
                    return DropdownMenuItem<String>(
                      value: fabricante,
                      child: Text(fabricante),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _fabricanteSelecionado = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o fabricante';
                    }
                    return null;
                  },
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
                  controller: _espressuraController,
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
                DropdownButtonFormField<String>(
                  value: _produtoCintaSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Produto Cinta',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon:
                        Icon(Icons.inventory_2, color: Color(0xFFFABA00)),
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
                  items: _tiposProdutosCinta.map((String produto) {
                    return DropdownMenuItem<String>(
                      value: produto,
                      child: Text(produto),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _produtoCintaSelecionado = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o produto da cinta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _produtoCorrenteSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Produto Corrente',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.link, color: Color(0xFFFABA00)),
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
                  items: _tiposProdutosCorrente.map((String produto) {
                    return DropdownMenuItem<String>(
                      value: produto,
                      child: Text(produto),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _produtoCorrenteSelecionado = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o produto da corrente';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _produtoBendroadsSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Produto Bendroads',
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
                  items: _tiposProdutosBendroads.map((String produto) {
                    return DropdownMenuItem<String>(
                      value: produto,
                      child: Text(produto),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _produtoBendroadsSelecionado = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o produto bendroads';
                    }
                    return null;
                  },
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
    _espressuraController.dispose();
    _produtoController.dispose();
    _velocidadeController.dispose();
    _produtoCintaController.dispose();
    _produtoCorrenteController.dispose();
    _produtoBendroadsController.dispose();
    super.dispose();
  }
}
