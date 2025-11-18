import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../models/temperatura_prensa_model.dart';
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
  final _larguraController = TextEditingController();
  final _produtoController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _produtoCintaController = TextEditingController();
  final _produtoCorrenteController = TextEditingController();
  final _produtoBendroadsController = TextEditingController();
  
  // Controllers para Temperaturas das Zonas
  final _zona1Controller = TextEditingController();
  final _zona2Controller = TextEditingController();
  final _zona3Controller = TextEditingController();
  final _zona4Controller = TextEditingController();
  final _zona5Controller = TextEditingController();
  
  // Controller para Comentário
  final _comentarioController = TextEditingController();

  final List<String> _fabricantes = [
    'Dieffenbacher',
    'Siempelkamp',
    'Kusters',
    'Outro'
  ];
  String? _fabricanteSelecionado;

  final List<String> _tiposProdutos = ['MDF', 'MDF1', 'MDF2', 'MDP', 'MDP 1', 'MDP 2', 'OSB', 'HDF', 'OUTROS'];
  String? _produtoSelecionado;

  final List<String> _tiposProdutosCinta = [
    'Hotemp Super N',
    'Hotemp Super N Plus',
    'Klubersynh CP 2-260',
    'Outro',
    'N/A'
  ];
  String? _produtoCintaSelecionado;

  final List<String> _tiposProdutosCorrente = [
    'Hotemp Super CH 2-100',
    'Klubersynh CP 2-100',
    'Hotemp Super N',
    'Hotemp Super N Plus',
    'Klubersynh CP 2-260',
    'Outro',
    'N/A'
  ];
  String? _produtoCorrenteSelecionado;

  final List<String> _tiposProdutosBendroads = [
    'Hotemp Super CH 2-100',
    'Klubersynh CP 2-100',
    'Outro',
    'N/A'
  ];
  String? _produtoBendroadsSelecionado;

  @override
  void initState() {
    super.initState();
    if (widget.prensa != null) {
      _fabricanteSelecionado = widget.prensa!.fabricante;
      _comprimentoController.text = widget.prensa!.comprimento?.toString() ?? '';
      _espressuraController.text = widget.prensa!.espressura.toString();
      _larguraController.text = widget.prensa!.largura?.toString() ?? '';
      _produtoSelecionado = widget.prensa!.produto;
      _velocidadeController.text = widget.prensa!.velocidade.toString();
      _produtoCintaSelecionado = widget.prensa!.produtoCinta;
      _produtoCorrenteSelecionado = widget.prensa!.produtoCorrente;
      _produtoBendroadsSelecionado = widget.prensa!.produtoBendroads;
      _comentarioController.text = widget.prensa!.comentario ?? '';
      
      // Carregar temperaturas se existirem
      _carregarTemperaturas();
    }
  }

  Future<void> _carregarTemperaturas() async {
    if (widget.prensa?.id != null) {
      try {
        final temperaturas = await DatabaseHelper.instance.getTemperaturasByPrensa(widget.prensa!.id!);
        if (temperaturas.isNotEmpty) {
          final temperatura = temperaturas.first;
          setState(() {
            _zona1Controller.text = temperatura.zona1?.toString() ?? '';
            _zona2Controller.text = temperatura.zona2?.toString() ?? '';
            _zona3Controller.text = temperatura.zona3?.toString() ?? '';
            _zona4Controller.text = temperatura.zona4?.toString() ?? '';
            _zona5Controller.text = temperatura.zona5?.toString() ?? '';
          });
        }
      } catch (e) {
        print('Erro ao carregar temperaturas: $e');
      }
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
          comprimento: _comprimentoController.text.isNotEmpty 
              ? double.parse(_comprimentoController.text) 
              : null,
          espressura: double.parse(_espressuraController.text),
          largura: _larguraController.text.isNotEmpty 
              ? double.parse(_larguraController.text) 
              : null,
          produto: _produtoSelecionado!,
          velocidade: double.parse(_velocidadeController.text),
          produtoCinta: _produtoCintaSelecionado!,
          produtoCorrente: _produtoCorrenteSelecionado!,
          produtoBendroads: _produtoBendroadsSelecionado!,
          torque: null,
          comentario: _comentarioController.text.isNotEmpty ? _comentarioController.text : null,
        );

        if (widget.prensa != null) {
          await DatabaseHelper.instance.updatePrensa(prensa);
          // Salvar temperaturas
          await _salvarTemperaturas(widget.prensa!.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prensa atualizada com sucesso!')),
            );
            Navigator.pop(context, true);
          }
        } else {
          final prensaId = await DatabaseHelper.instance.createPrensa(prensa);
          // Salvar temperaturas
          await _salvarTemperaturas(prensaId);
          
          // Se for Kusters, criar elementos automaticamente e não navegar para seleção
          if (_fabricanteSelecionado == 'Kusters') {
            try {
              await DatabaseHelper.instance.criarElementosPadrao(prensaId);
            } catch (e) {
              print('Erro ao criar elementos padrão para Kusters: $e');
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prensa cadastrada com sucesso!')),
              );
              Navigator.pop(context, true);
            }
          } else {
            // Para outros fabricantes, navegar para seleção de elementos
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
                    ),
                  ),
                );
              }
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
                    labelText: 'Comprimento - m',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon:
                        Icon(Icons.straighten, color: Color(0xFFFABA00)),
                    suffixText: 'm',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _larguraController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Largura - m',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.swap_horiz, color: Color(0xFFFABA00)),
                    suffixText: 'm',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                  controller: _espressuraController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Espessura - mm',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.height, color: Color(0xFFFABA00)),
                    suffixText: 'mm',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _velocidadeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Velocidade - m/min',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                    suffixText: 'm/min',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),

                // Produtos de Lubrificação
                _buildSectionHeader('Produtos de Lubrificação', Icons.opacity),
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

                // Campo de Comentário
                TextFormField(
                  controller: _comentarioController,
                  decoration: const InputDecoration(
                    labelText: 'Comentário',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.comment, color: Color(0xFFFABA00)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 32),

                // Temperaturas das Zonas
                _buildSectionHeader('Temperaturas das Zonas', Icons.thermostat),
                const SizedBox(height: 16),

                // Zona 1
                TextFormField(
                  controller: _zona1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Zona 1 (°C)',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Zona 2
                TextFormField(
                  controller: _zona2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Zona 2 (°C)',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Zona 3
                TextFormField(
                  controller: _zona3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Zona 3 (°C)',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Zona 4
                TextFormField(
                  controller: _zona4Controller,
                  decoration: const InputDecoration(
                    labelText: 'Zona 4 (°C)',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Zona 5
                TextFormField(
                  controller: _zona5Controller,
                  decoration: const InputDecoration(
                    labelText: 'Zona 5 (°C)',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
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

  Future<void> _salvarTemperaturas(int prensaId) async {
    // Só salva se pelo menos uma temperatura foi preenchida
    if (_zona1Controller.text.isNotEmpty || 
        _zona2Controller.text.isNotEmpty || 
        _zona3Controller.text.isNotEmpty || 
        _zona4Controller.text.isNotEmpty || 
        _zona5Controller.text.isNotEmpty) {
      
      final temperatura = TemperaturaPrensa(
        zona1: _zona1Controller.text.isNotEmpty ? double.tryParse(_zona1Controller.text) : null,
        zona2: _zona2Controller.text.isNotEmpty ? double.tryParse(_zona2Controller.text) : null,
        zona3: _zona3Controller.text.isNotEmpty ? double.tryParse(_zona3Controller.text) : null,
        zona4: _zona4Controller.text.isNotEmpty ? double.tryParse(_zona4Controller.text) : null,
        zona5: _zona5Controller.text.isNotEmpty ? double.tryParse(_zona5Controller.text) : null,
        prensaId: prensaId,
        dataRegistro: DateTime.now().toString().split(' ')[0], // Formato YYYY-MM-DD
      );

      // Verificar se já existe temperatura para essa prensa
      final temperaturasExistentes = await DatabaseHelper.instance.getTemperaturasByPrensa(prensaId);
      
      if (temperaturasExistentes.isNotEmpty) {
        // Atualizar temperatura existente
        final temperaturaExistente = temperaturasExistentes.first;
        final temperaturaAtualizada = TemperaturaPrensa(
          id: temperaturaExistente.id,
          zona1: temperatura.zona1,
          zona2: temperatura.zona2,
          zona3: temperatura.zona3,
          zona4: temperatura.zona4,
          zona5: temperatura.zona5,
          prensaId: prensaId,
          dataRegistro: temperatura.dataRegistro,
        );
        await DatabaseHelper.instance.updateTemperaturaPrensa(temperaturaAtualizada);
      } else {
        // Criar nova temperatura
        await DatabaseHelper.instance.createTemperaturaPrensa(temperatura);
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFABA00), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFABA00),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fabricanteController.dispose();
    _comprimentoController.dispose();
    _espressuraController.dispose();
    _larguraController.dispose();
    _produtoController.dispose();
    _velocidadeController.dispose();
    _produtoCintaController.dispose();
    _produtoCorrenteController.dispose();
    _produtoBendroadsController.dispose();
    _zona1Controller.dispose();
    _zona2Controller.dispose();
    _zona3Controller.dispose();
    _zona4Controller.dispose();
    _zona5Controller.dispose();
    _comentarioController.dispose();
    super.dispose();
  }
}
