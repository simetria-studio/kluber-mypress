import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import '../widgets/custom_bottom_nav.dart';
import 'cadastro_visita_screen.dart';
import 'selecionar_cadastro_screen.dart';
import '../models/prensa_model.dart';
import '../models/elemento_model.dart';
import '../models/problema_model.dart';

class ListaVisitasScreen extends StatefulWidget {
  const ListaVisitasScreen({super.key});

  @override
  State<ListaVisitasScreen> createState() => _ListaVisitasScreenState();
}

class _ListaVisitasScreenState extends State<ListaVisitasScreen> {
  List<Visita> _visitas = [];
  bool _isLoading = true;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _carregarVisitas();
  }

  Future<void> _carregarVisitas() async {
    try {
      final visitas = await DatabaseHelper.instance.getAllVisitas();
      setState(() {
        _visitas = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar visitas')),
        );
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
          'Todas as Visitas',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFABA00)),
            )
          : _visitas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma visita cadastrada',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarVisitas,
                  color: const Color(0xFFFABA00),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _visitas.length,
                    itemBuilder: (context, index) {
                      final visita = _visitas[index];
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelecionarCadastroScreen(
                                    visitaId: visita.id!),
                              ),
                            ).then((_) => _carregarVisitas());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business,
                                      color: Color(0xFFFABA00),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        visita.cliente,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.copy,
                                        color: Color(0xFFFABA00),
                                      ),
                                      onPressed: () => _duplicarVisita(visita),
                                      tooltip: 'Duplicar visita',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFFFABA00),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(visita.dataVisita),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Color(0xFFFABA00),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Contato: ${visita.contatoCliente}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CadastroVisitaScreen()),
          ).then((_) => _carregarVisitas());
        },
      ),
    );
  }

  Future<void> _duplicarVisita(Visita visita) async {
    try {
      final novaVisita = Visita(
        dataVisita: DateTime.now(),
        cliente: visita.cliente,
        contatoCliente: visita.contatoCliente,
        contatoKluber: visita.contatoKluber,
      );

      final novaVisitaId =
          await DatabaseHelper.instance.createVisita(novaVisita);

      final prensas =
          await DatabaseHelper.instance.getPrensasByVisita(visita.id!);
      for (var prensa in prensas) {
        final novaPrensa = Prensa(
          visitaId: novaVisitaId,
          tipoPrensa: prensa.tipoPrensa,
          fabricante: prensa.fabricante,
          comprimento: prensa.comprimento,
          espressura: prensa.espressura,
          produto: prensa.produto,
          velocidade: prensa.velocidade,
          produtoCinta: prensa.produtoCinta,
          produtoCorrente: prensa.produtoCorrente,
          produtoBendroads: prensa.produtoBendroads,
          torque: prensa.torque,
        );

        final novaPrensaId =
            await DatabaseHelper.instance.createPrensa(novaPrensa);

        final elementos =
            await DatabaseHelper.instance.getElementsByPrensa(prensa.id!);
        for (var elemento in elementos) {
          final novoElemento = Elemento(
            consumo1: elemento.consumo1,
            consumo2: elemento.consumo2,
            consumo3: elemento.consumo3,
            toma: elemento.toma,
            posicao: elemento.posicao,
            tipo: elemento.tipo,

            prensaId: novaPrensaId,
          );
          await DatabaseHelper.instance.createElemento(novoElemento);
        }
      }

      final problemas =
          await DatabaseHelper.instance.getProblemasByVisita(visita.id!);
      for (var problema in problemas) {
        final novoProblema = Problema(
          problemaRedutorPrincipal: problema.problemaRedutorPrincipal,
          comentarioRedutorPrincipal: problema.comentarioRedutorPrincipal,
          lubrificanteRedutorPrincipal: problema.lubrificanteRedutorPrincipal,
          problemaTemperatura: problema.problemaTemperatura,
          comentarioTemperatura: problema.comentarioTemperatura,
          problemaTamborPrincipal: problema.problemaTamborPrincipal,
          comentarioTamborPrincipal: problema.comentarioTamborPrincipal,
          myPressVisitaId: novaVisitaId,
          graxaRolamentosZonasQuentes: problema.graxaRolamentosZonasQuentes,
          graxaTamborPrincipal: problema.graxaTamborPrincipal,
        );
        await DatabaseHelper.instance.createProblema(novoProblema);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita duplicada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarVisitas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao duplicar visita: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
