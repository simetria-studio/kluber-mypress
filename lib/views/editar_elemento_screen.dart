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
    _posicaoController.addListener(_checkChanges);
    _tipoController.addListener(_checkChanges);
  }

  void _carregarDadosElemento() {
    _consumo1Controller.text = widget.elemento.consumo1.toString();
    _consumo2Controller.text = widget.elemento.consumo2.toString();
    _consumo3Controller.text = widget.elemento.consumo3.toString();
    _tomaController.text = widget.elemento.toma;
    _posicaoController.text = widget.elemento.posicao;
    _tipoController.text = widget.elemento.tipo;
  }

  void _checkChanges() {
    final hasChanges =
        _consumo1Controller.text != widget.elemento.consumo1.toString() ||
            _consumo2Controller.text != widget.elemento.consumo2.toString() ||
            _consumo3Controller.text != widget.elemento.consumo3.toString() ||
            _tomaController.text != widget.elemento.toma ||
            _posicaoController.text != widget.elemento.posicao ||
            _tipoController.text != widget.elemento.tipo;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _salvarElemento() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final elementoAtualizado = Elemento(
          id: widget.elemento.id,
          consumo1: double.parse(_consumo1Controller.text),
          consumo2: double.parse(_consumo2Controller.text),
          consumo3: double.parse(_consumo3Controller.text),
          toma: _tomaController.text,
          posicao: _posicaoController.text,
          tipo: _tipoController.text,
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
                        TextFormField(
                          controller: _consumo1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo 1',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o consumo 1';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo2Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo 2',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o consumo 2';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _consumo3Controller,
                          decoration: const InputDecoration(
                            labelText: 'Consumo 3',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o consumo 3';
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
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira a soma';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _posicaoController,
                          decoration: const InputDecoration(
                            labelText: 'Posição',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira a posição';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tipoController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o tipo';
                            }
                            return null;
                          },
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
    _posicaoController.dispose();
    _tipoController.dispose();
    super.dispose();
  }
}
