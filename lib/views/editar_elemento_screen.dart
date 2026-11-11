import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/elemento_model.dart';
import '../models/prensa_model.dart';
import '../models/comentario_elemento_model.dart';
import '../models/anexo_comentario_model.dart';
import '../database/database_helper.dart';
import '../helpers/aplicacao_prensa_helper.dart';
import '../helpers/lubrificante_produto_helper.dart';
import '../helpers/number_parse_helper.dart';
import '../helpers/unidade_medida_constants.dart';

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
  final _comentarioController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  String? _tipoElementoSelecionado;
  String? _posicaoSelecionada;
  String? _fabricantePrensa;
  Prensa? _prensa;
  String? _lubrificanteSelecionado;

  File? _anexoFile;
  String? _anexoNome;

  List<String> get _opcoesLubrificante =>
      LubrificanteProdutoHelper.opcoesPorTipo(
        _tipoElementoSelecionado ?? widget.elemento.tipo,
      );

  @override
  void initState() {
    super.initState();
    _carregarDadosElemento();
    _consumo1Controller.addListener(_checkChanges);
    _consumo2Controller.addListener(_checkChanges);
    _consumo3Controller.addListener(_checkChanges);
    _tomaController.addListener(_checkChanges);
    _comentarioController.addListener(_checkChanges);

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

    _tipoElementoSelecionado = widget.elemento.tipo;
    _posicaoSelecionada =
        widget.elemento.posicao != 'N/A' ? widget.elemento.posicao : null;
  }

  Future<void> _carregarFabricantePrensa() async {
    try {
      final prensas = await DatabaseHelper.instance.getAllPrensas();
      final prensa =
          prensas.firstWhere((p) => p.id == widget.elemento.prensaId);
      final lubrificanteAtual = _lubrificanteDaPrensa(prensa);

      setState(() {
        _prensa = prensa;
        _fabricantePrensa = prensa.fabricante;
        _lubrificanteSelecionado = LubrificanteProdutoHelper.valorNaLista(
          lubrificanteAtual,
          _opcoesLubrificante,
        );
      });
    } catch (e) {
      print('Erro ao carregar fabricante da prensa: $e');
    }
  }

  String _lubrificanteDaPrensa(Prensa prensa) {
    switch (widget.elemento.tipo) {
      case 'Corrente':
        return prensa.produtoCorrente;
      case 'Bend rods':
        return prensa.produtoBendroads;
      default:
        return prensa.produtoCinta;
    }
  }

  void _checkChanges() {
    final lubrificanteOriginal = _prensa != null
        ? LubrificanteProdutoHelper.normalizar(_lubrificanteDaPrensa(_prensa!))
        : '';
    final hasChanges =
        _consumo1Controller.text != widget.elemento.consumo1.toString() ||
            _consumo2Controller.text != widget.elemento.consumo2.toString() ||
            _consumo3Controller.text != widget.elemento.consumo3.toString() ||
            _tomaController.text != widget.elemento.toma ||
            (_lubrificanteSelecionado ?? '') != lubrificanteOriginal ||
            _comentarioController.text.trim().isNotEmpty ||
            _anexoFile != null;

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

  Future<void> _selecionarAnexo() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFABA00)),
                title:
                    const Text('Câmera', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo =
                      await picker.pickImage(source: ImageSource.camera);
                  await _processarAnexo(photo);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFFFABA00)),
                title: const Text('Galeria',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  await _processarAnexo(image);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processarAnexo(XFile? imageFile) async {
    if (imageFile == null) return;

    try {
      final File originalFile = File(imageFile.path);
      final String originalName = p.basename(imageFile.path);
      final String targetPath = originalFile.path.replaceAll(
        '.${originalFile.path.split('.').last}',
        '_compressed.jpg',
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.path,
        targetPath,
        quality: 70,
        format: CompressFormat.jpeg,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedFile != null) {
        setState(() {
          _anexoFile = File(compressedFile.path);
          _anexoNome = originalName.contains('.')
              ? '${p.basenameWithoutExtension(originalName)}.jpg'
              : '$originalName.jpg';
        });
        _checkChanges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar anexo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removerAnexo() {
    setState(() {
      _anexoFile = null;
      _anexoNome = null;
    });
    _checkChanges();
  }

  Future<void> _salvarElemento() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
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

        final comentarioTexto = _comentarioController.text.trim();
        final temFoto = _anexoFile != null;

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

        if (_prensa != null && _lubrificanteSelecionado != null) {
          final prensaAtualizada = Prensa(
            id: _prensa!.id,
            visitaId: _prensa!.visitaId,
            tipoPrensa: _prensa!.tipoPrensa,
            fabricante: _prensa!.fabricante,
            comprimento: _prensa!.comprimento,
            espressura: _prensa!.espressura,
            largura: _prensa!.largura,
            produto: _prensa!.produto,
            velocidade: _prensa!.velocidade,
            produtoCinta: widget.elemento.tipo == 'Cinta metálica'
                ? _lubrificanteSelecionado!
                : _prensa!.produtoCinta,
            produtoCorrente: widget.elemento.tipo == 'Corrente'
                ? _lubrificanteSelecionado!
                : _prensa!.produtoCorrente,
            produtoBendroads: widget.elemento.tipo == 'Bend rods'
                ? _lubrificanteSelecionado!
                : _prensa!.produtoBendroads,
            torque: _prensa!.torque,
            comentario: _prensa!.comentario,
          );
          await DatabaseHelper.instance.updatePrensa(prensaAtualizada);
          _prensa = prensaAtualizada;
        }

        if ((comentarioTexto.isNotEmpty || temFoto) &&
            widget.elemento.id != null) {
          final comentarioId =
              await DatabaseHelper.instance.createComentarioElemento(
            ComentarioElemento(
              comentario:
                  comentarioTexto.isNotEmpty ? comentarioTexto : 'Foto',
              elementoId: widget.elemento.id!,
            ),
          );

          if (temFoto) {
            final bytes = await _anexoFile!.readAsBytes();
            final base64Image = base64Encode(bytes);
            final extension = _anexoFile!.path.split('.').last.toLowerCase();
            final mimeType =
                extension == 'jpg' || extension == 'jpeg'
                    ? 'image/jpeg'
                    : 'image/$extension';
            final nomeAnexo = _anexoNome ?? p.basename(_anexoFile!.path);

            await DatabaseHelper.instance.createAnexoComentario(
              AnexoComentario(
                nome: nomeAnexo,
                tipo: mimeType,
                url: _anexoFile!.path,
                base64: base64Image,
                comentarioId: comentarioId,
              ),
            );
          }
        }

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
                        DropdownButtonFormField<String>(
                          value: _lubrificanteSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Lubrificante',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon:
                                Icon(Icons.opacity, color: Color(0xFFFABA00)),
                          ),
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          items: _opcoesLubrificante.map((String produto) {
                            return DropdownMenuItem<String>(
                              value: produto,
                              child: Text(produto),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _lubrificanteSelecionado = newValue;
                            });
                            _checkChanges();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, selecione o lubrificante';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo1Controller,
                          decoration: InputDecoration(
                            labelText: 'Consumo Nominal',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(Icons.speed,
                                color: Color(0xFFFABA00)),
                            suffixText: UnidadeMedidaConstants.consumo,
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
                          decoration: InputDecoration(
                            labelText: 'Consumo Real',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(Icons.speed,
                                color: Color(0xFFFABA00)),
                            suffixText: UnidadeMedidaConstants.consumo,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFABA00)),
                            ),
                            border: const UnderlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText: 'Consumo adicional',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(Icons.speed,
                                color: Color(0xFFFABA00)),
                            suffixText: UnidadeMedidaConstants.consumo,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFABA00)),
                            ),
                            border: const UnderlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText: 'Soma',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(
                                Icons.settings_input_component,
                                color: Color(0xFFFABA00)),
                            suffixText: UnidadeMedidaConstants.consumo,
                          ),
                          style: const TextStyle(color: Colors.white),
                          enabled: false,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _comentarioController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Comentários',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            alignLabelWithHint: true,
                            prefixIcon: const Icon(
                              Icons.comment,
                              color: Color(0xFFFABA00),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFABA00)),
                            ),
                            border: const UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selecionarAnexo,
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Foto',
                              labelStyle: TextStyle(color: Colors.white),
                              prefixIcon: Icon(
                                Icons.photo_camera,
                                color: Color(0xFFFABA00),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFFABA00)),
                              ),
                              border: UnderlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _anexoNome ?? 'Selecionar foto',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _anexoNome != null
                                          ? Colors.white
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                                if (_anexoFile != null)
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white70, size: 20),
                                    onPressed: _removerAnexo,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                else
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Color(0xFFFABA00),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_anexoFile != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _anexoFile!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
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
    _posicaoController.dispose();
    _tipoController.dispose();
    _comentarioController.dispose();

    _consumo2Controller.removeListener(_calcularSoma);
    _consumo3Controller.removeListener(_calcularSoma);

    super.dispose();
  }
}
