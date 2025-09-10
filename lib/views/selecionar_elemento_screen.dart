import 'package:flutter/material.dart';
import 'package:mypress/views/cadastro_visita_screen.dart';
import '../models/elemento_model.dart';
import '../models/comentario_elemento_model.dart';
import '../models/problema_model.dart';
import '../database/database_helper.dart';
import 'cadastro_elemento_screen.dart';
import 'cadastro_comentario_elemento_screen.dart';
import 'cadastro_anexo_screen.dart';
import 'dart:convert';
import '../models/anexo_comentario_model.dart';
import 'editar_elemento_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class SelecionarElementoScreen extends StatefulWidget {
  final int prensaId;

  const SelecionarElementoScreen({
    super.key,
    required this.prensaId,
  });

  @override
  State<SelecionarElementoScreen> createState() =>
      _SelecionarElementoScreenState();
}

class _SelecionarElementoScreenState extends State<SelecionarElementoScreen> {
  List<Elemento> _elementos = [];
  Map<int, List<ComentarioElemento>> _comentariosPorElemento = {};
  bool _isLoading = true;
  int _currentIndex = 0;

  // Variáveis para Demais Aplicações
  final _formKey = GlobalKey<FormState>();
  bool _problemaRedutorPrincipal = false;
  bool _problemaTemperatura = false;
  bool _problemaTamborPrincipal = false;

  final _comentarioRedutorController = TextEditingController();
  final _comentarioTemperaturaController = TextEditingController();
  final _comentarioTamborController = TextEditingController();
  bool _isSavingProblema = false;

  final List<String> _tiposLubrificantes = [
    'Klubersynth GH 6',
    'Klubersynhth GEM 4',
    'Kluberoil GEM 1',
    'Klubersynth MEG 4',
    'Outros'
  ];
  String? _lubrificanteSelecionado;

  final List<String> _tiposGraxaRolamentos = [
    'klubersynth BH 72-422',
    'klubertemp HB 53-391',
    'klubertemp GR AR 555',
    'Outros'
  ];
  String? _graxaRolamentosSelecionada;

  final List<String> _tiposGraxaTambor = [
    'Kluberlub PHB 71-461',
    'Outros'
  ];
  String? _graxaTamborSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _comentarioRedutorController.dispose();
    _comentarioTemperaturaController.dispose();
    _comentarioTamborController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      // Criar elementos padrão automaticamente se não existirem
      try {
        await DatabaseHelper.instance.criarElementosPadrao(widget.prensaId);
      } catch (e) {
        // Silenciar erro se elementos já existem - isso é esperado
        if (!e.toString().contains('já existem')) {
          print('Erro ao criar elementos padrão: $e');
        }
      }

      final elementos =
          await DatabaseHelper.instance.getElementsByPrensa(widget.prensaId);

      // Carregar comentários para cada elemento
      final comentariosPorElemento = <int, List<ComentarioElemento>>{};
      for (var elemento in elementos) {
        if (elemento.id != null) {
          final comentarios = await DatabaseHelper.instance
              .getComentariosByElemento(elemento.id!);
          comentariosPorElemento[elemento.id!] = comentarios;
        }
      }

      // Carregar problemas existentes
      final problemas = await DatabaseHelper.instance.getProblemasByPrensa(widget.prensaId);
      if (problemas.isNotEmpty) {
        final problema = problemas.first;
        setState(() {
          _problemaRedutorPrincipal = problema.problemaRedutorPrincipal == '1';
          _problemaTemperatura = problema.problemaTemperatura == '1';
          _problemaTamborPrincipal = problema.problemaTamborPrincipal == '1';
          _comentarioRedutorController.text = problema.comentarioRedutorPrincipal ?? '';
          _comentarioTemperaturaController.text = problema.comentarioTemperatura ?? '';
          _comentarioTamborController.text = problema.comentarioTamborPrincipal ?? '';
          _lubrificanteSelecionado = problema.lubrificanteRedutorPrincipal;
          _graxaRolamentosSelecionada = problema.graxaRolamentosZonasQuentes;
          _graxaTamborSelecionada = problema.graxaTamborPrincipal;
        });
      }

      setState(() {
        _elementos = elementos;
        _comentariosPorElemento = comentariosPorElemento;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildComentariosList(List<ComentarioElemento> comentarios) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFFABA00), height: 1),
        const SizedBox(height: 8),
        const Text(
          'Comentários:',
          style: TextStyle(
            color: Color(0xFFFABA00),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...comentarios.map((comentario) => FutureBuilder<List<AnexoComentario>>(
              future:
                  DatabaseHelper.instance.getAnexosByComentario(comentario.id!),
              builder: (context, snapshot) {
                final anexos = snapshot.data ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFABA00).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comentario.comentario,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.attach_file,
                              color: Color(0xFFFABA00),
                              size: 20,
                            ),
                            onPressed: () => _adicionarAnexo(comentario),
                          ),
                        ],
                      ),
                      if (anexos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: anexos.map((anexo) {
                            return GestureDetector(
                              onTap: () {
                                _exibirImagemCompleta(context, anexo);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFABA00).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFABA00),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.attachment,
                                      color: Color(0xFFFABA00),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      anexo.nome,
                                      style: const TextStyle(
                                        color: Color(0xFFFABA00),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            )),
      ],
    );
  }

  void _exibirImagemCompleta(BuildContext context, AnexoComentario anexo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              title: Text(
                anexo.nome,
                style: const TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Confirmar exclusão
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text(
                          'Excluir Anexo',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Tem certeza que deseja excluir este anexo?',
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
                                    .deleteAnexoComentario(anexo.id!);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Anexo excluído com sucesso')),
                                  );
                                  // Fechar os dois diálogos
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  // Atualizar a tela
                                  setState(() {});
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Erro ao excluir anexo: ${e.toString()}')),
                                  );
                                  Navigator.pop(context);
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
                  },
                ),
              ],
            ),
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                base64Decode(anexo.base64),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Selecionar Elementos',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _buildOptionCard(
                  //   context,
                  //   title: 'Novo Elemento',
                  //   description: 'Adicione um novo elemento para esta prensa',
                  //   icon: Icons.add_circle_outline,
                  //   onTap: () async {
                  //     final result = await Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) =>
                  //             CadastroElementoScreen(prensaId: widget.prensaId),
                  //       ),
                  //     );
                  //     if (result == true) {
                  //       _carregarDados();
                  //     }
                  //   },
                  // ),

                  const SizedBox(height: 16),

                  if (_elementos.isNotEmpty) ...[
                    const Text(
                      'Aplicações da prensa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._elementos.map((elemento) => Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: const Color(0xFFFABA00).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Cabeçalho do elemento
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFABA00)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.settings,
                                        color: Color(0xFFFABA00),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            elemento.tipo,
                                            style: const TextStyle(
                                              color: Color(0xFFFABA00),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          color: Color(0xFFFABA00)),
                                      color: Colors.grey[850],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editarElemento(elemento);
                                            break;
                                          case 'delete':
                                            _confirmarExclusaoElemento(
                                                elemento);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit,
                                                  color: Color(0xFFFABA00),
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Text('Editar',
                                                  style: TextStyle(
                                                      color: Colors.grey[200])),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete,
                                                  color: Colors.red, size: 20),
                                              const SizedBox(width: 8),
                                              Text('Excluir',
                                                  style: TextStyle(
                                                      color: Colors.grey[200])),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Corpo do elemento
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Informações principais
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoItem(
                                            icon: Icons.place,
                                            label: 'Posição',
                                            value: elemento.posicao,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(color: Colors.grey),
                                    const SizedBox(height: 16),

                                    // Nominal e Consumo na mesma linha
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildConsumoItem(
                                            'Nominal', elemento.consumo1),
                                        _buildConsumoItem(
                                            'Consumo', double.tryParse(elemento.toma) ?? 0.0),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Comentários
                                    if (_comentariosPorElemento[elemento.id]
                                            ?.isNotEmpty ??
                                        false) ...[
                                      const SizedBox(height: 16),
                                      _buildComentariosList(
                                          _comentariosPorElemento[
                                              elemento.id]!),
                                    ],

                                    // Botões de ação
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.comment,
                                              size: 16,
                                              color: Color(0xFFFABA00),
                                            ),
                                            label: const Text(
                                              'Comentar',
                                              style: TextStyle(
                                                color: Color(0xFFFABA00),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFFFABA00),
                                              side: const BorderSide(
                                                  color: Color(0xFFFABA00)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 0),
                                              minimumSize: const Size(0, 32),
                                            ),
                                            onPressed: () =>
                                                _adicionarComentario(elemento),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Formulário de Demais Aplicações
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Demais Aplicações',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lubrificante do Redutor Principal
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFABA00).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.settings,
                                    color: Color(0xFFFABA00),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Lubrificante do Redutor Principal',
                                    style: TextStyle(
                                      color: Color(0xFFFABA00),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Lubrificante primeiro
                              DropdownButtonFormField<String>(
                                value: _lubrificanteSelecionado,
                                decoration: const InputDecoration(
                                  labelText: 'Lubrificante',
                                  labelStyle: TextStyle(color: Color(0xFFFABA00)),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00), width: 2),
                                  ),
                                ),
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white),
                                items: _tiposLubrificantes.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _lubrificanteSelecionado = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              // Depois comentários
                              TextFormField(
                                controller: _comentarioRedutorController,
                                decoration: const InputDecoration(
                                  labelText: 'Comentário',
                                  labelStyle: TextStyle(color: Color(0xFFFABA00)),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00), width: 2),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Temperatura
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFABA00).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.thermostat,
                                    color: Color(0xFFFABA00),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Graxa da Zona Quente',
                                    style: TextStyle(
                                      color: Color(0xFFFABA00),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Lubrificante/Graxa primeiro
                              DropdownButtonFormField<String>(
                                value: _graxaRolamentosSelecionada,
                                decoration: const InputDecoration(
                                  labelText: 'Graxa para Rolamentos',
                                  labelStyle: TextStyle(color: Color(0xFFFABA00)),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00), width: 2),
                                  ),
                                ),
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white),
                                items: _tiposGraxaRolamentos.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _graxaRolamentosSelecionada = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              // Depois comentários
                              TextFormField(
                                controller: _comentarioTemperaturaController,
                                decoration: const InputDecoration(
                                  labelText: 'Comentário',
                                  labelStyle: TextStyle(color: Color(0xFFFABA00)),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00), width: 2),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tambor Principal
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFABA00).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.rotate_right,
                                    color: Color(0xFFFABA00),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Lubrificante do Tambor Principal',
                                    style: TextStyle(
                                      color: Color(0xFFFABA00),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Lubrificante/Graxa primeiro
                              DropdownButtonFormField<String>(
                                value: _graxaTamborSelecionada,
                                decoration: const InputDecoration(
                                  labelText: 'Graxa para Tambor',
                                  labelStyle: TextStyle(color: Color(0xFFFABA00)),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00), width: 2),
                                  ),
                                ),
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white),
                                items: _tiposGraxaTambor.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _graxaTamborSelecionada = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              // Depois comentários
                              TextFormField(
                                controller: _comentarioTamborController,
                                decoration: const InputDecoration(
                                  labelText: 'Comentário',
                                  labelStyle: TextStyle(color: Color(0xFFFABA00)),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFABA00), width: 2),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botão Salvar Inspeção
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSavingProblema ? null : _salvarProblema,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFABA00),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSavingProblema
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Salvar Demais Aplicações',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botão Finalizar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finalizarCadastro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFABA00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Finalizar',
                        style: TextStyle(
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFABA00),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != 2) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        onAddVisitPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastroVisitaScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFABA00), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConsumoItem(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(2)}\nl/D',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFFABA00).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFABA00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFABA00),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFFABA00),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarExclusaoElemento(Elemento elemento) {
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
                await DatabaseHelper.instance.deleteElemento(elemento.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Elemento excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _carregarDados();
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

  void _editarElemento(Elemento elemento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarElementoScreen(
          elemento: elemento,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _carregarDados();
      }
    });
  }

  void _adicionarComentario(Elemento elemento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroComentarioElementoScreen(
          elementoId: elemento.id!,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _carregarDados();
      }
    });
  }

  void _adicionarAnexo(ComentarioElemento comentario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroAnexoScreen(
          comentarioId: comentario.id!,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _carregarDados();
      }
    });
  }

  Future<void> _salvarProblema() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSavingProblema = true;
      });

      try {
        final problemas = await DatabaseHelper.instance.getProblemasByPrensa(widget.prensaId);
        final problemaExistente = problemas.isNotEmpty ? problemas.first : null;

        final problema = Problema(
          id: problemaExistente?.id,
          problemaRedutorPrincipal: _problemaRedutorPrincipal ? '1' : '0',
          comentarioRedutorPrincipal: _comentarioRedutorController.text,
          problemaTemperatura: _problemaTemperatura ? '1' : '0',
          comentarioTemperatura: _comentarioTemperaturaController.text,
          problemaTamborPrincipal: _problemaTamborPrincipal ? '1' : '0',
          comentarioTamborPrincipal: _comentarioTamborController.text,
          lubrificanteRedutorPrincipal: _lubrificanteSelecionado,
          graxaRolamentosZonasQuentes: _graxaRolamentosSelecionada,
          graxaTamborPrincipal: _graxaTamborSelecionada,
          myPressPrensaId: widget.prensaId,
        );

        if (problemaExistente != null) {
          await DatabaseHelper.instance.updateProblema(problema);
        } else {
          await DatabaseHelper.instance.createProblema(problema);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demais Aplicações salva com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Erro ao salvar problema: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar inspeção: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSavingProblema = false;
          });
        }
      }
    }
  }

  Future<void> _finalizarCadastro() async {
    // Mostrar mensagem de sucesso
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro finalizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navegar para a tela inicial
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
