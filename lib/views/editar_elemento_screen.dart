import 'package:flutter/material.dart';
import '../models/elemento_model.dart';
import '../database/database_helper.dart';

class EditarElementoScreen extends StatefulWidget {
  final Elemento elemento;

  const EditarElementoScreen({
    super.key,
    required this.elemento,
  });

  @override
  State<EditarElementoScreen> createState() => _EditarElementoScreenState();
}

class _EditarElementoScreenState extends State<EditarElementoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumo1Controller = TextEditingController();
  final _consumo2Controller = TextEditingController();
  final _consumo3Controller = TextEditingController();
  final _tomaController = TextEditingController();
  final _posicaoController = TextEditingController();
  final _tipoController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Lista de tipos de elementos
  final List<String> _tiposElementos = [
    'Bend rods',
    'Cinta metálica',
    'Corrente'
  ];
  String? _tipoElementoSelecionado;

  // Lista de posições - será ajustada dinamicamente baseada no fabricante
  List<String> _posicoes = ['Superior', 'Inferior'];
  String? _posicaoSelecionada;
  
  // Variável para armazenar o fabricante da prensa
  String? _fabricantePrensa;

  @override
  void initState() {
    super.initState();
    _carregarDadosElemento();
    print('entrou no initstate');
    // Monitorar mudanças
        _consumo1Controller.addListener(_checkChanges);
    _consumo2Controller.addListener(_checkChanges);
    _consumo3Controller.addListener(_checkChanges);
    _tomaController.addListener(_checkChanges);

    // Adicionar listeners para cálculo automático da soma
    _consumo2Controller.addListener(_calcularSoma);
    _consumo3Controller.addListener(_calcularSoma);
    
    _carregarFabricantePrensa();
  }

  void _carregarDadosElemento() {
    _consumo1Controller.text = widget.elemento.consumo1.toString();
    _consumo2Controller.text = widget.elemento.consumo2.toString();
    _consumo3Controller.text = widget.elemento.consumo3.toString();
    _tomaController.text = widget.elemento.toma;
    _posicaoController.text = widget.elemento.posicao;
    _tipoController.text = widget.elemento.tipo;
    
    // Carregar valores para os dropdowns
    _tipoElementoSelecionado = widget.elemento.tipo;
    _posicaoSelecionada = widget.elemento.posicao != 'N/A' ? widget.elemento.posicao : null;
  }

  Future<void> _carregarFabricantePrensa() async {
    try {
      // Buscar a prensa para obter o fabricante
      final prensas = await DatabaseHelper.instance.getAllPrensas();
      final prensa = prensas.firstWhere((p) => p.id == widget.elemento.prensaId);
      
      setState(() {
        _fabricantePrensa = prensa.fabricante;
        
        // Se for Dieffenbacher, ajustar as posições
        if (prensa.fabricante == 'Dieffenbacher') {
          _posicoes = ['Superior'];
        } else {
          _posicoes = ['Superior', 'Inferior'];
        }
      });
    } catch (e) {
      print('Erro ao carregar fabricante da prensa: $e');
      // Em caso de erro, manter as posições padrão
      setState(() {
        _posicoes = ['Superior', 'Inferior'];
      });
    }
  }

  void _checkChanges() {
    final hasChanges =
        _consumo1Controller.text != widget.elemento.consumo1.toString() ||
            _consumo2Controller.text != widget.elemento.consumo2.toString() ||
            _consumo3Controller.text != widget.elemento.consumo3.toString() ||
            _tomaController.text != widget.elemento.toma ||
            _posicaoSelecionada != (widget.elemento.posicao != 'N/A' ? widget.elemento.posicao : null) ||
            _tipoElementoSelecionado != widget.elemento.tipo;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
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

  Future<void> _salvarElemento() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Verificar se os campos obrigatórios estão preenchidos
        if (_tipoElementoSelecionado == null) {
          throw Exception('Por favor, selecione o tipo do elemento');
        }

        if (_tipoElementoSelecionado != 'Bend rods' && _posicaoSelecionada == null) {
          throw Exception('Por favor, selecione a posição');
        }

        // Para Dieffenbacher, sempre exigir posição
        if (_fabricantePrensa == 'Dieffenbacher' && _posicaoSelecionada == null) {
          throw Exception('Por favor, selecione a posição');
        }

        final elementoAtualizado = Elemento(
          id: widget.elemento.id,
          consumo1: double.parse(_consumo1Controller.text),
          consumo2: double.parse(_consumo2Controller.text),
          consumo3: double.parse(_consumo3Controller.text),
          toma: _tomaController.text,
          posicao: _posicaoSelecionada ?? 'N/A', // Usar 'N/A' como valor padrão para Bend rods
          tipo: _tipoElementoSelecionado!,
          prensaId: widget.elemento.prensaId,
        );

        await DatabaseHelper.instance.updateElemento(elementoAtualizado);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Elemento atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar elemento: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Descartar alterações?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Você tem alterações não salvas. Deseja descartar essas alterações?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Descartar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Excluir Elemento',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja excluir este elemento? Esta ação não pode ser desfeita e todos os comentários associados também serão excluídos.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance
                    .deleteElemento(widget.elemento.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Elemento excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Fecha o diálogo
                  Navigator.pop(context, true); // Volta para a tela anterior
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Erro ao excluir elemento: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Editar Elemento',
            style: TextStyle(color: Color(0xFFFABA00)),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save, color: Color(0xFFFABA00)),
                onPressed: _isLoading ? null : _salvarElemento,
                tooltip: 'Salvar alterações',
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmarExclusao,
              tooltip: 'Excluir elemento',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFABA00)))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          visible: _tipoElementoSelecionado != 'Bend rods' || _fabricantePrensa == 'Dieffenbacher',
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
                              // Para Dieffenbacher, sempre exigir posição
                              if (_fabricantePrensa == 'Dieffenbacher' && (value == null || value.isEmpty)) {
                                return 'Por favor, selecione a posição';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo Nominal',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                            suffixText: 'l/D',
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o consumo nominal';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo2Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo Real',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                            suffixText: 'l/D',
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o consumo real';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo3Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo Real Adicional',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.speed, color: Color(0xFFFABA00)),
                            suffixText: 'l/D',
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o consumo real adicional';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tomaController,
                          decoration: const InputDecoration(
                            labelText: 'Soma',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.settings_input_component, color: Color(0xFFFABA00)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          enabled: false,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _salvarElemento,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFABA00),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
                                    'Salvar',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
    
    // Remover listeners de cálculo da soma
    _consumo2Controller.removeListener(_calcularSoma);
    _consumo3Controller.removeListener(_calcularSoma);
    
    super.dispose();
  }
}
