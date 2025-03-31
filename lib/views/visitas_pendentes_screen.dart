import 'package:flutter/material.dart';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

class VisitasPendentesScreen extends StatefulWidget {
  const VisitasPendentesScreen({super.key});

  @override
  State<VisitasPendentesScreen> createState() => _VisitasPendentesScreenState();
}

class _VisitasPendentesScreenState extends State<VisitasPendentesScreen> {
  bool _isLoading = false;
  List<Visita> _visitasPendentes = [];

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

  Future<void> _enviarVisita(Visita visita) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar todos os dados relacionados à visita
      final prensas =
          await DatabaseHelper.instance.getPrensasByVisita(visita.id!);
      final problemas =
          await DatabaseHelper.instance.getProblemasByVisita(visita.id!);

      // Preparar dados para envio
      final dadosVisita = {
        'visita': visita.toMap(),
        'prensas': await Future.wait(
          prensas.map((prensa) async {
            final elementos =
                await DatabaseHelper.instance.getElementsByPrensa(prensa.id!);
            return {
              'prensa': prensa.toMap(),
              'elementos': await Future.wait(
                elementos.map((elemento) async {
                  final comentarios = await DatabaseHelper.instance
                      .getComentariosByElemento(elemento.id!);
                  final temperaturas = await DatabaseHelper.instance
                      .getTemperaturasByElemento(elemento.id!);
                  return {
                    'elemento': elemento.toMap(),
                    'comentarios': await Future.wait(
                      comentarios.map((comentario) async {
                        final anexos = await DatabaseHelper.instance
                            .getAnexosByComentario(comentario.id!);
                        return {
                          'comentario': comentario.toMap(),
                          'anexos': anexos.map((a) => a.toMap()).toList(),
                        };
                      }),
                    ),
                    'temperaturas': temperaturas.map((t) => t.toMap()).toList(),
                  };
                }),
              ),
            };
          }),
        ),
        'problemas': problemas.map((p) => p.toMap()).toList(),
      };

      // Enviar para a API e aguardar resposta
      final response = await ApiService.enviarVisita(dadosVisita);

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
        // Buscar todos os dados relacionados à visita
        final prensas =
            await DatabaseHelper.instance.getPrensasByVisita(visita.id!);
        final problemas =
            await DatabaseHelper.instance.getProblemasByVisita(visita.id!);

        // Preparar dados para envio
        final dadosVisita = {
          'visita': visita.toMap(),
          'prensas': await Future.wait(
            prensas.map((prensa) async {
              final elementos =
                  await DatabaseHelper.instance.getElementsByPrensa(prensa.id!);
              return {
                'prensa': prensa.toMap(),
                'elementos': await Future.wait(
                  elementos.map((elemento) async {
                    final comentarios = await DatabaseHelper.instance
                        .getComentariosByElemento(elemento.id!);
                    final temperaturas = await DatabaseHelper.instance
                        .getTemperaturasByElemento(elemento.id!);
                    return {
                      'elemento': elemento.toMap(),
                      'comentarios': await Future.wait(
                        comentarios.map((comentario) async {
                          final anexos = await DatabaseHelper.instance
                              .getAnexosByComentario(comentario.id!);
                          return {
                            'comentario': comentario.toMap(),
                            'anexos': anexos.map((a) => a.toMap()).toList(),
                          };
                        }),
                      ),
                      'temperaturas':
                          temperaturas.map((t) => t.toMap()).toList(),
                    };
                  }),
                ),
              };
            }),
          ),
          'problemas': problemas.map((p) => p.toMap()).toList(),
        };

        // Enviar para a API e aguardar resposta
        final response = await ApiService.enviarVisita(dadosVisita);

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
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Color(0xFFFABA00),
                          ),
                          onPressed: () => _enviarVisita(visita),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
