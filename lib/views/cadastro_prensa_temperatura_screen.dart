import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../models/temperatura_prensa_model.dart';
import '../database/database_helper.dart';
import 'selecionar_elemento_screen.dart';

class CadastroPrensaTemperaturaScreen extends StatefulWidget {
  final int visitaId;
  final Prensa? prensa;
  final TemperaturaPrensa? temperatura;

  const CadastroPrensaTemperaturaScreen({
    super.key,
    required this.visitaId,
    this.prensa,
    this.temperatura,
  });

  @override
  State<CadastroPrensaTemperaturaScreen> createState() => _CadastroPrensaTemperaturaScreenState();
}

class _CadastroPrensaTemperaturaScreenState extends State<CadastroPrensaTemperaturaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para Prensa
  final _fabricanteController = TextEditingController();
  final _comprimentoController = TextEditingController();
  final _espressuraController = TextEditingController();
  final _larguraController = TextEditingController();
  final _produtoController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _produtoCintaController = TextEditingController();
  final _produtoCorrenteController = TextEditingController();
  final _produtoBendroadsController = TextEditingController();

  // Controllers para Temperatura
  final _zona1Controller = TextEditingController();
  final _zona2Controller = TextEditingController();
  final _zona3Controller = TextEditingController();
  final _zona4Controller = TextEditingController();
  final _zona5Controller = TextEditingController();

  // Dropdowns para Prensa
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

  bool _isLoading = false;
  bool _showTemperaturaSection = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
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
    }

    if (widget.temperatura != null) {
      _zona1Controller.text = widget.temperatura!.zona1?.toString() ?? '';
      _zona2Controller.text = widget.temperatura!.zona2?.toString() ?? '';
      _zona3Controller.text = widget.temperatura!.zona3?.toString() ?? '';
      _zona4Controller.text = widget.temperatura!.zona4?.toString() ?? '';
      _zona5Controller.text = widget.temperatura!.zona5?.toString() ?? '';
    }
  }

  Future<void> _salvarPrensaETemperatura() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Salvar Prensa
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
        );

        int prensaId;
        if (widget.prensa != null) {
          await DatabaseHelper.instance.updatePrensa(prensa);
          prensaId = widget.prensa!.id!;
        } else {
          prensaId = await DatabaseHelper.instance.createPrensa(prensa);
        }

        // Salvar Temperatura
        if (_showTemperaturaSection) {
          final temperatura = TemperaturaPrensa(
            id: widget.temperatura?.id,
            dataRegistro: widget.temperatura?.dataRegistro ?? DateTime.now().toIso8601String(),
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
            prensaId: prensaId,
          );

          if (widget.temperatura != null) {
            await DatabaseHelper.instance.updateTemperaturaPrensa(temperatura);
          } else {
            await DatabaseHelper.instance.createTemperaturaPrensa(temperatura);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.prensa != null 
                ? 'Prensa e temperaturas atualizadas com sucesso!'
                : 'Prensa e temperaturas cadastradas com sucesso!'
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar para seleção de elementos
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SelecionarElementoScreen(
                prensaId: prensaId,
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: ${e.toString()}'),
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
        title: Text(
          widget.prensa != null ? 'Editar Prensa e Temperaturas' : 'Cadastrar Prensa e Temperaturas',
          style: const TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
        actions: [
          IconButton(
            icon: Icon(
              _showTemperaturaSection ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFFABA00),
            ),
            onPressed: () {
              setState(() {
                _showTemperaturaSection = !_showTemperaturaSection;
              });
            },
            tooltip: _showTemperaturaSection ? 'Ocultar temperaturas' : 'Mostrar temperaturas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFABA00)),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seção da Prensa
                      _buildSectionHeader('Dados da Prensa', Icons.settings),
                      const SizedBox(height: 16),
                      
                      // Fabricante
                      DropdownButtonFormField<String>(
                        value: _fabricanteSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Fabricante',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.factory, color: Color(0xFFFABA00)),
                        ),
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

                      // Dimensões
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _comprimentoController,
                              decoration: const InputDecoration(
                                labelText: 'Comprimento - m',
                                labelStyle: TextStyle(color: Colors.white),
                                prefixIcon: Icon(Icons.straighten, color: Color(0xFFFABA00)),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _larguraController,
                              decoration: const InputDecoration(
                                labelText: 'Largura - m',
                                labelStyle: TextStyle(color: Colors.white),
                                prefixIcon: Icon(Icons.straighten, color: Color(0xFFFABA00)),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Espessura
                      TextFormField(
                        controller: _espressuraController,
                        decoration: const InputDecoration(
                          labelText: 'Espessura - mm',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.height, color: Color(0xFFFABA00)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a espessura';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Produto
                      DropdownButtonFormField<String>(
                        value: _produtoSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Produto',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.inventory, color: Color(0xFFFABA00)),
                        ),
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

                      // Velocidade
                      TextFormField(
                        controller: _velocidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Velocidade',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a velocidade';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Produtos de Lubrificação
                      _buildSectionHeader('Produtos de Lubrificação', Icons.opacity),
                      const SizedBox(height: 16),

                      // Produto Cinta
                      DropdownButtonFormField<String>(
                        value: _produtoCintaSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Produto Cinta',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.opacity, color: Color(0xFFFABA00)),
                        ),
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

                      // Produto Corrente
                      DropdownButtonFormField<String>(
                        value: _produtoCorrenteSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Produto Corrente',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.opacity, color: Color(0xFFFABA00)),
                        ),
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

                      // Produto Bendroads
                      DropdownButtonFormField<String>(
                        value: _produtoBendroadsSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Produto Bendroads',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.opacity, color: Color(0xFFFABA00)),
                        ),
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

                      // Seção de Temperaturas
                      if (_showTemperaturaSection) ...[
                        const SizedBox(height: 32),
                        _buildSectionHeader('Temperaturas das Zonas', Icons.thermostat),
                        const SizedBox(height: 16),

                        // Zona 1
                        TextFormField(
                          controller: _zona1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Zona 1 (°C)',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.thermostat, color: Color(0xFFFABA00)),
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
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                        ),
                      ],

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _salvarPrensaETemperatura,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFABA00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.prensa != null ? 'ATUALIZAR' : 'SALVAR E CONTINUAR',
                            style: const TextStyle(
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFABA00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFABA00).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFABA00), size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFABA00),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
    super.dispose();
  }
} 