import 'package:flutter/material.dart';
import '../models/visita_model.dart';
import '../models/problema_model.dart';
import '../models/elemento_model.dart';
import '../database/database_helper.dart';
import '../helpers/aplicacao_prensa_helper.dart';
import '../helpers/unidade_medida_constants.dart';
import '../services/api_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'cadastro_visita_screen.dart';

class VisitasPendentesScreen extends StatefulWidget {
  const VisitasPendentesScreen({super.key});

  @override
  State<VisitasPendentesScreen> createState() => _VisitasPendentesScreenState();
}

class _VisitasPendentesScreenState extends State<VisitasPendentesScreen> {
  bool _isLoading = false;
  List<Visita> _visitasPendentes = [];
  int _currentIndex = 3; // Índice 3 para a aba de visitas pendentes

  @override
  void initState() {
    super.initState();
    _carregarVisitasPendentes();
  }

  Future<void> _carregarVisitasPendentes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final visitas = await DatabaseHelper.instance.getVisitasNaoEnviadas();
      setState(() {
        _visitasPendentes = visitas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar visitas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _normalizarTipoAplicacao(String tipo) {
    switch (tipo) {
      case 'Cinta metálica':
        return 'cinta';
      case 'Corrente':
        return 'corrente';
      case 'Bend rods':
        return 'bend_rods';
      default:
        return tipo.toLowerCase().replaceAll(' ', '_');
    }
  }

  Map<String, dynamic> _montarAplicacoesPrensa(
    List<Elemento> elementos, {
    String? fabricante,
  }) {
    final Map<String, Map<String, dynamic>> aplicacoes = {};

    for (final elemento in elementos) {
      if (!AplicacaoPrensaHelper.permite(fabricante, elemento.tipo)) {
        continue;
      }

      final tipo = _normalizarTipoAplicacao(elemento.tipo);
      aplicacoes.putIfAbsent(tipo, () {
        return {
          'consumo_oleo': null,
          'contaminacao': null,
        };
      });

      if ((elemento.consumoOleo ?? '').isNotEmpty) {
        aplicacoes[tipo]!['consumo_oleo'] = elemento.consumoOleo;
      }
      if ((elemento.contaminacao ?? '').isNotEmpty) {
        aplicacoes[tipo]!['contaminacao'] = elemento.contaminacao;
      }
    }

    return aplicacoes;
  }

  Future<Map<String, dynamic>> _montarDadosVisita(Visita visita) async {
    final prensas = await DatabaseHelper.instance.getPrensasByVisita(visita.id!);

    List<Problema> problemas = [];
    for (var prensa in prensas) {
      final problemasPrensa =
          await DatabaseHelper.instance.getProblemasByPrensa(prensa.id!);
      problemas.addAll(problemasPrensa);
    }

    final prensasFormatadas = await Future.wait(
      prensas.map((prensa) async {
        final temperaturas =
            await DatabaseHelper.instance.getTemperaturasByPrensa(prensa.id!);
        final elementos =
            await DatabaseHelper.instance.getElementsByPrensa(prensa.id!);
        final elementosPermitidos = elementos
            .where((elemento) => AplicacaoPrensaHelper.permite(
                  prensa.fabricante,
                  elemento.tipo,
                ))
            .toList();

        final elementosFormatados = await Future.wait(
          elementosPermitidos.map((elemento) async {
            final elementoMap = Map<String, dynamic>.from(elemento.toMap());
            elementoMap.remove('consumo_oleo');
            elementoMap.remove('contaminacao');

            final comentarios =
                await DatabaseHelper.instance.getComentariosByElemento(
              elemento.id!,
            );

            final comentariosFormatados = await Future.wait(
              comentarios.map((comentario) async {
                final anexos = await DatabaseHelper.instance
                    .getAnexosByComentario(comentario.id!);
                return {
                  'comentario': comentario.toMap(),
                  'anexos': anexos.map((a) => a.toMap()).toList(),
                };
              }),
            );

            return {
              'elemento': elementoMap,
              'comentarios': comentariosFormatados,
            };
          }),
        );

        final prensaMap = Map<String, dynamic>.from(prensa.toMap());
        if (!AplicacaoPrensaHelper.permite(
          prensa.fabricante,
          AplicacaoPrensaHelper.bendRods,
        )) {
          prensaMap['produto_bendroads'] = 'N/A';
        }
        if (!AplicacaoPrensaHelper.permite(
          prensa.fabricante,
          AplicacaoPrensaHelper.corrente,
        )) {
          prensaMap['produto_corrente'] = 'N/A';
        }

        return {
          'prensa': prensaMap,
          'temperaturas': temperaturas.map((t) => t.toMap()).toList(),
          'aplicacoes_prensa': {
            'prensa_id': prensa.id,
            ..._montarAplicacoesPrensa(
              elementosPermitidos,
              fabricante: prensa.fabricante,
            ),
          },
          'elementos': elementosFormatados,
        };
      }),
    );

    return {
      'request': {
        'visita': visita.toMap(),
        'prensas': prensasFormatadas,
        'problemas': problemas.map((p) => p.toMap()).toList(),
        'unidades': UnidadeMedidaConstants.paraReporte,
      }
    };
  }

  Future<void> _enviarVisita(Visita visita) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dadosVisita = await _montarDadosVisita(visita);

      print('Enviando visita: $dadosVisita');

      // Enviar para a API e aguardar resposta
      await ApiService.enviarVisita(dadosVisita);

      // Se chegou aqui, a API retornou sucesso
      await DatabaseHelper.instance.marcarVisitaComoEnviada(visita.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarVisitasPendentes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar visita: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enviarTodasVisitas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final visita in _visitasPendentes) {
        final dadosVisita = await _montarDadosVisita(visita);

        print('Enviando visita: $dadosVisita');

        // Enviar para a API e aguardar resposta
        await ApiService.enviarVisita(dadosVisita);

        // Se chegou aqui, a API retornou sucesso
        await DatabaseHelper.instance.marcarVisitaComoEnviada(visita.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas as visitas foram enviadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarVisitasPendentes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar visitas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _excluirVisita(Visita visita) async {
    // Mostrar diálogo de confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Excluir Visita',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        content: Text(
          'Tem certeza que deseja excluir a visita de ${visita.cliente}?\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await DatabaseHelper.instance.deleteVisita(visita.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visita excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarVisitasPendentes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir visita: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Visitas Pendentes',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
        actions: [
          if (_visitasPendentes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: _enviarTodasVisitas,
              tooltip: 'Enviar todas as visitas',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFABA00)),
            )
          : _visitasPendentes.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma visita pendente de envio',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visitasPendentes.length,
                  itemBuilder: (context, index) {
                    final visita = _visitasPendentes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFFFABA00).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          visita.cliente,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Data: ${visita.dataVisita}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Contato: ${visita.contatoCliente}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _excluirVisita(visita),
                              tooltip: 'Excluir visita',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cloud_upload_outlined,
                                color: Color(0xFFFABA00),
                              ),
                              onPressed: () => _enviarVisita(visita),
                              tooltip: 'Enviar visita',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastroVisitaScreen(),
            ),
          ).then((_) => _carregarVisitasPendentes());
        },
      ),
    );
  }
}
