import 'package:flutter/material.dart';
import 'package:mypress/views/cadastro_visita_screen.dart';
import '../models/elemento_model.dart';
import '../models/comentario_elemento_model.dart';
import '../database/database_helper.dart';
import '../models/temperatura_elemento_model.dart';
import 'cadastro_elemento_screen.dart';
import 'cadastro_comentario_elemento_screen.dart';
import 'cadastro_anexo_screen.dart';
import 'dart:convert';
import '../models/anexo_comentario_model.dart';
import 'editar_elemento_screen.dart';
import 'temperatura_elemento_screen.dart';
import 'cadastro_temperatura_screen.dart';
import 'editar_temperatura_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class SelecionarElementoScreen extends StatefulWidget {
  final int prensaId;
  final int visitaId;

  const SelecionarElementoScreen({
    super.key,
    required this.prensaId,
    required this.visitaId,
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

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
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
                  _buildOptionCard(
                    context,
                    title: 'Novo Elemento',
                    description: 'Adicione um novo elemento para esta prensa',
                    icon: Icons.add_circle_outline,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CadastroElementoScreen(prensaId: widget.prensaId),
                        ),
                      );
                      if (result == true) {
                        _carregarDados();
                      }
                    },
                  ),
                  if (_elementos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Elementos Cadastrados',
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
                                            'Elemento ${elemento.id}',
                                            style: const TextStyle(
                                              color: Color(0xFFFABA00),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            elemento.tipo,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
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
                                        Expanded(
                                          child: _buildInfoItem(
                                            icon: Icons.precision_manufacturing,
                                            label: 'MyPress',
                                            value: elemento.mypress,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildInfoItem(
                                            icon:
                                                Icons.settings_input_component,
                                            label: 'Toma',
                                            value: elemento.toma,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(color: Colors.grey),
                                    const SizedBox(height: 16),

                                    // Consumos
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildConsumoItem(
                                            'Consumo 1', elemento.consumo1),
                                        _buildConsumoItem(
                                            'Consumo 2', elemento.consumo2),
                                        _buildConsumoItem(
                                            'Consumo 3', elemento.consumo3),
                                      ],
                                    ),

                                    // Adicione a seção de temperaturas aqui
                                    const SizedBox(height: 16),
                                    _buildTemperaturasList(elemento),

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
                  ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finalizarCadastro,
        backgroundColor: const Color(0xFFFABA00),
        icon: const Icon(Icons.check, color: Colors.black),
        label: const Text(
          'Finalizar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            '${value.toStringAsFixed(2)}\ng/h',
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

  Widget _buildTemperaturasList(Elemento elemento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFFABA00), height: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Temperaturas:',
              style: TextStyle(
                color: Color(0xFFFABA00),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFFFABA00),
                size: 24,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CadastroTemperaturaScreen(
                      elemento: elemento,
                    ),
                  ),
                ).then((value) {
                  if (value == true) {
                    _carregarDados();
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<TemperaturaElemento>>(
          future:
              DatabaseHelper.instance.getTemperaturasByElemento(elemento.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFABA00)),
              );
            }

            final temperaturas = snapshot.data ?? [];

            if (temperaturas.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFABA00).withOpacity(0.3),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Nenhuma temperatura registrada',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: temperaturas.length,
              itemBuilder: (context, index) {
                final temperatura = temperaturas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Data: ${temperatura.dataRegistro}',
                              style: const TextStyle(
                                color: Color(0xFFFABA00),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFFFABA00),
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () =>
                                    _editarTemperatura(temperatura),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () =>
                                    _confirmarExclusaoTemperatura(temperatura),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      _buildTemperaturaItem('Zona 1', temperatura.zona1),
                      _buildTemperaturaItem('Zona 2', temperatura.zona2),
                      _buildTemperaturaItem('Zona 3', temperatura.zona3),
                      _buildTemperaturaItem('Zona 4', temperatura.zona4),
                      _buildTemperaturaItem('Zona 5', temperatura.zona5),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTemperaturaItem(String zona, double? temperatura) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            zona,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            temperatura != null ? '${temperatura.toStringAsFixed(1)}°C' : '-',
            style: TextStyle(
              color: temperatura != null ? Colors.white : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _editarTemperatura(TemperaturaElemento temperatura) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarTemperaturaScreen(
          temperatura: temperatura,
          elemento:
              _elementos.firstWhere((e) => e.id == temperatura.elementoId),
        ),
      ),
    ).then((value) {
      if (value == true) {
        _carregarDados();
      }
    });
  }

  void _confirmarExclusaoTemperatura(TemperaturaElemento temperatura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Excluir Temperatura',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja excluir este registro de temperatura?',
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
                    .deleteTemperaturaElemento(temperatura.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Temperatura excluída com sucesso!'),
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
                          Text('Erro ao excluir temperatura: ${e.toString()}'),
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
