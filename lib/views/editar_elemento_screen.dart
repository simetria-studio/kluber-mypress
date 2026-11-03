import 'package:flutter/material.dart';
import '../models/elemento_model.dart';
import '../database/database_helper.dart';
import '../helpers/aplicacao_prensa_helper.dart';
import '../helpers/number_parse_helper.dart';

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

  String? _tipoElementoSelecionado;

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
    _posicaoSelecionada =
        widget.elemento.posicao != 'N/A' ? widget.elemento.posicao : null;
  }

  Future<void> _carregarFabricantePrensa() async {
    try {
      // Buscar a prensa para obter o fabricante
      final prensas = await DatabaseHelper.instance.getAllPrensas();
      final prensa =
          prensas.firstWhere((p) => p.id == widget.elemento.prensaId);

      setState(() {
        _fabricantePrensa = prensa.fabricante;
      });
    } catch (e) {
      print('Erro ao carregar fabricante da prensa: $e');
    }
  }

  void _checkChanges() {
    final hasChanges =
        _consumo1Controller.text != widget.elemento.consumo1.toString() ||
            _consumo2Controller.text != widget.elemento.consumo2.toString() ||
            _consumo3Controller.text != widget.elemento.consumo3.toString() ||
            _tomaController.text != widget.elemento.toma;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _calcularSoma() {
    try {
      final consumo2 =
          NumberParseHelper.tryParse(_consumo2Controller.text) ?? 0;
      final consumo3 =
          NumberParseHelper.tryParse(_consumo3Controller.text) ?? 0;
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

        if (!AplicacaoPrensaHelper.permite(
            _fabricantePrensa, _tipoElementoSelecionado!)) {
          throw Exception(
              'Esta aplicação não é permitida para $_fabricantePrensa');
        }

        final exigePosicao = AplicacaoPrensaHelper.exigePosicao(
          _fabricantePrensa,
          _tipoElementoSelecionado!,
        );
        if (exigePosicao && _posicaoSelecionada == null) {
          throw Exception('Por favor, selecione a posição');
        }

        final elementoAtualizado = Elemento(
          id: widget.elemento.id,
          consumo1: NumberParseHelper.parse(_consumo1Controller.text),
          consumo2: NumberParseHelper.parse(_consumo2Controller.text),
          consumo3: NumberParseHelper.parse(_consumo3Controller.text),
          toma: NumberParseHelper.normalize(_tomaController.text),
          posicao: exigePosicao
              ? (_posicaoSelecionada ?? widget.elemento.posicao)
              : 'N/A',
          tipo: _tipoElementoSelecionado!,
          prensaId: widget.elemento.prensaId,
          consumoOleo: widget.elemento.consumoOleo,
          contaminacao: widget.elemento.contaminacao,
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
                        TextFormField(
                          controller: _tipoController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon:
                                Icon(Icons.category, color: Color(0xFFFABA00)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            disabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            border: UnderlineInputBorder(),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Visibility(
                          visible: AplicacaoPrensaHelper.exigePosicao(
                            _fabricantePrensa,
                            _tipoElementoSelecionado ?? '',
                          ),
                          child: TextFormField(
                            controller: _posicaoController,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Posição',
                              labelStyle: TextStyle(color: Colors.white),
                              prefixIcon:
                                  Icon(Icons.place, color: Color(0xFFFABA00)),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              disabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              border: UnderlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo Nominal',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon:
                                Icon(Icons.speed, color: Color(0xFFFABA00)),
                            suffixText: 'l/D',
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) =>
                              NumberParseHelper.validateRequired(
                            value,
                            field: 'consumo nominal',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo2Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo Real',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon:
                                Icon(Icons.speed, color: Color(0xFFFABA00)),
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) =>
                              NumberParseHelper.validateRequired(
                            value,
                            field: 'consumo real',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo3Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo adicional',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon:
                                Icon(Icons.speed, color: Color(0xFFFABA00)),
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) =>
                              NumberParseHelper.validateRequired(
                            value,
                            field: 'consumo adicional',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tomaController,
                          decoration: const InputDecoration(
                            labelText: 'Soma',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.settings_input_component,
                                color: Color(0xFFFABA00)),
                            suffixText: 'l/D',
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
