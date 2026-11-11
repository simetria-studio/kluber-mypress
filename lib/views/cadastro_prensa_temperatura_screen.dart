import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../models/temperatura_prensa_model.dart';
import '../database/database_helper.dart';
import '../helpers/espessura_constants.dart';
import '../helpers/campo_info_helper.dart';
import '../helpers/number_parse_helper.dart';
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
  State<CadastroPrensaTemperaturaScreen> createState() =>
      _CadastroPrensaTemperaturaScreenState();
}

class _CadastroPrensaTemperaturaScreenState
    extends State<CadastroPrensaTemperaturaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para Prensa
  final _fabricanteController = TextEditingController();
  final _comprimentoController = TextEditingController();
  final _larguraController = TextEditingController();
  final _produtoController = TextEditingController();
  final _velocidadeController = TextEditingController();

  // Controllers para Temperatura
  final _zona1Controller = TextEditingController();
  final _zona2Controller = TextEditingController();
  final _zona3Controller = TextEditingController();
  final _zona4Controller = TextEditingController();
  final _zona5Controller = TextEditingController();

  // Controller para Comentário
  final _comentarioController = TextEditingController();

  // Dropdowns para Prensa
  final List<String> _fabricantes = [
    'Dieffenbacher',
    'Siempelkamp',
    'Kusters',
    'Outro'
  ];
  String? _fabricanteSelecionado;

  final List<String> _tiposProdutos = [
    'MDF',
    'MDF1',
    'MDF2',
    'MDP',
    'MDP 1',
    'MDP 2',
    'OSB',
    'HDF',
    'OUTROS'
  ];
  String? _produtoSelecionado;

  String? _espessuraSelecionada;

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
      _comprimentoController.text =
          widget.prensa!.comprimento?.toString() ?? '';
      _espessuraSelecionada =
          EspessuraConstants.opcaoDeValor(widget.prensa!.espressura);
      _larguraController.text = widget.prensa!.largura?.toString() ?? '';
      _produtoSelecionado = widget.prensa!.produto;
      _velocidadeController.text = widget.prensa!.velocidade.toString();
      _comentarioController.text = widget.prensa!.comentario ?? '';
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
        // Preserva produtos de lubrificação já salvos em Selecionar Elementos
        String produtoCinta = 'N/A';
        String produtoCorrente = 'N/A';
        String produtoBendroads = 'N/A';
        if (widget.prensa?.id != null) {
          final prensas = await DatabaseHelper.instance.getAllPrensas();
          final atuais =
              prensas.where((p) => p.id == widget.prensa!.id).toList();
          if (atuais.isNotEmpty) {
            produtoCinta = atuais.first.produtoCinta;
            produtoCorrente = atuais.first.produtoCorrente;
            produtoBendroads = atuais.first.produtoBendroads;
          }
        }

        // Salvar Prensa
        final prensa = Prensa(
          id: widget.prensa?.id,
          visitaId: widget.visitaId,
          tipoPrensa: _fabricanteSelecionado!,
          fabricante: _fabricanteSelecionado!,
          comprimento: _comprimentoController.text.isNotEmpty
              ? NumberParseHelper.parse(_comprimentoController.text)
              : null,
          espressura: NumberParseHelper.parse(_espessuraSelecionada!),
          largura: _larguraController.text.isNotEmpty
              ? NumberParseHelper.parse(_larguraController.text)
              : null,
          produto: _produtoSelecionado!,
          velocidade: NumberParseHelper.parse(_velocidadeController.text),
          produtoCinta: produtoCinta,
          produtoCorrente: produtoCorrente,
          produtoBendroads: produtoBendroads,
          torque: null,
          comentario: null,
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
            dataRegistro: widget.temperatura?.dataRegistro ??
                DateTime.now().toIso8601String(),
                zona1: _zona1Controller.text.isNotEmpty
                ? NumberParseHelper.parse(_zona1Controller.text)
                : null,
            zona2: _zona2Controller.text.isNotEmpty
                ? NumberParseHelper.parse(_zona2Controller.text)
                : null,
            zona3: _zona3Controller.text.isNotEmpty
                ? NumberParseHelper.parse(_zona3Controller.text)
                : null,
            zona4: _zona4Controller.text.isNotEmpty
                ? NumberParseHelper.parse(_zona4Controller.text)
                : null,
            zona5: _zona5Controller.text.isNotEmpty
                ? NumberParseHelper.parse(_zona5Controller.text)
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
                  : 'Prensa e temperaturas cadastradas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          if (widget.prensa != null) {
            Navigator.pop(context, true);
            return;
          }

          // Navegar para seleção de elementos (fluxo de novo cadastro)
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
          widget.prensa != null
              ? 'Editar Prensa e Temperaturas'
              : 'Cadastrar Prensa e Temperaturas',
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
            tooltip: _showTemperaturaSection
                ? 'Ocultar temperaturas'
                : 'Mostrar temperaturas',
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
                      // Dados da Prensa: Fabricante, Comprimento, Velocidade
                      _buildSectionHeader(
                        'Dados da Prensa',
                        Icons.settings,
                        infoMensagem: CampoInfoHelper.dadosPrensa,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _fabricanteSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Fabricante',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon:
                              Icon(Icons.factory, color: Color(0xFFFABA00)),
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
                      TextFormField(
                        controller: _comprimentoController,
                        decoration: const InputDecoration(
                          labelText: 'Comprimento da prensa - m',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.straighten,
                              color: Color(0xFFFABA00)),
                          suffixText: 'm',
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return NumberParseHelper.validateRequired(
                            value,
                            field: 'comprimento',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _velocidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Velocidade - mm/s',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon:
                              Icon(Icons.speed, color: Color(0xFFFABA00)),
                          suffixText: 'mm/s',
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) => NumberParseHelper.validateRequired(
                          value,
                          field: 'velocidade',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Foto Engrenagem – Dados da Chapa: Produto, Largura, Espessura
                      _buildSectionHeader(
                        'Foto Engrenagem – Dados da Chapa',
                        Icons.layers,
                        infoMensagem: CampoInfoHelper.dadosChapa,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _produtoSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Produto',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon:
                              Icon(Icons.inventory, color: Color(0xFFFABA00)),
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
                      TextFormField(
                        controller: _larguraController,
                        decoration: const InputDecoration(
                          labelText: 'Largura da chapa - mm',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.straighten,
                              color: Color(0xFFFABA00)),
                          suffixText: 'mm',
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return NumberParseHelper.validateRequired(
                            value,
                            field: 'largura',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _espessuraSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Espessura da chapa - mm',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon:
                              Icon(Icons.height, color: Color(0xFFFABA00)),
                        ),
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        items:
                            EspessuraConstants.opcoes.map((String espessura) {
                          return DropdownMenuItem<String>(
                            value: espessura,
                            child: Text('$espessura mm'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _espessuraSelecionada = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecione a espessura';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Seção de Temperaturas
                      if (_showTemperaturaSection) ...[
                        _buildSectionHeader(
                          'Temperaturas da Prensa',
                          Icons.thermostat,
                          infoMensagem: CampoInfoHelper.temperaturasZonas,
                        ),
                        const SizedBox(height: 16),

                        // Zona 1
                        TextFormField(
                          controller: _zona1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Zona 1 (°C)',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.thermostat,
                                color: Color(0xFFFABA00)),
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
                            prefixIcon: Icon(Icons.thermostat,
                                color: Color(0xFFFABA00)),
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
                            prefixIcon: Icon(Icons.thermostat,
                                color: Color(0xFFFABA00)),
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
                            prefixIcon: Icon(Icons.thermostat,
                                color: Color(0xFFFABA00)),
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
                            prefixIcon: Icon(Icons.thermostat,
                                color: Color(0xFFFABA00)),
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
                            widget.prensa != null
                                ? 'ATUALIZAR'
                                : 'SALVAR E CONTINUAR',
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

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    String? infoMensagem,
  }) {
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
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFABA00),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (infoMensagem != null)
            CampoInfoHelper.botao(
              context,
              titulo: title,
              mensagem: infoMensagem,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fabricanteController.dispose();
    _comprimentoController.dispose();
    _larguraController.dispose();
    _produtoController.dispose();
    _velocidadeController.dispose();
    _zona1Controller.dispose();
    _zona2Controller.dispose();
    _zona3Controller.dispose();
    _zona4Controller.dispose();
    _zona5Controller.dispose();
    _comentarioController.dispose();
    super.dispose();
  }
}
