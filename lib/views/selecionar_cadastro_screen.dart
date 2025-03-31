import 'package:flutter/material.dart';
import 'package:mypress/views/cadastro_problema_screen.dart';
import '../models/prensa_model.dart';
import '../database/database_helper.dart';
import 'cadastro_prensa_screen.dart';
import '../models/elemento_model.dart';
import 'selecionar_elemento_screen.dart';
import '../models/problema_model.dart';

class SelecionarCadastroScreen extends StatefulWidget {
  final int visitaId;

  const SelecionarCadastroScreen({
    super.key,
    required this.visitaId,
  });

  @override
  State<SelecionarCadastroScreen> createState() =>
      _SelecionarCadastroScreenState();
}

class _SelecionarCadastroScreenState extends State<SelecionarCadastroScreen> {
  List<Prensa> _prensas = [];
  Map<int, List<Elemento>> _elementosPorPrensa = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final prensas =
          await DatabaseHelper.instance.getPrensasByVisita(widget.visitaId);

      // Carregar elementos para cada prensa
      final elementosPorPrensa = <int, List<Elemento>>{};
      for (var prensa in prensas) {
        if (prensa.id != null) {
          final elementos =
              await DatabaseHelper.instance.getElementsByPrensa(prensa.id!);
          elementosPorPrensa[prensa.id!] = elementos;
        }
      }

      setState(() {
        _prensas = prensas;
        _elementosPorPrensa = elementosPorPrensa;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar dados')),
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
          'Gerenciar Cadastros',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFABA00)),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOptionCard(
                      context,
                      title: 'Nova Prensa',
                      description: 'Adicione uma nova prensa para esta visita',
                      icon: Icons.precision_manufacturing,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CadastroPrensaScreen(visitaId: widget.visitaId),
                          ),
                        );
                        if (result == true) {
                          _carregarDados();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context,
                      title: 'Novo Problema',
                      description: 'Registre um problema identificado',
                      icon: Icons.warning_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CadastroProblemaScreen(
                                visitaId: widget.visitaId),
                          ),
                        );
                        // TODO: Implementar navegação para cadastro de problema
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Cadastro de problemas em desenvolvimento'),
                          ),
                        );
                      },
                    ),
                    if (_prensas.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Prensas Cadastradas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prensas.length,
                        itemBuilder: (context, index) {
                          return _buildPrensaCard(_prensas[index]);
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'FINALIZAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProblemasList(widget.visitaId),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPrensaCard(Prensa prensa) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFABA00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing,
                    color: Color(0xFFFABA00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prensa.tipoPrensa,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Fabricante: ${prensa.fabricante}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelecionarElementoScreen(
                          prensaId: prensa.id!,
                          visitaId: widget.visitaId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings,
                    color: Color(0xFFFABA00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  'Comprimento',
                  '${prensa.comprimento} m',
                  Icons.straighten,
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  'Espessura',
                  '${prensa.espessura} mm',
                  Icons.height,
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  'Velocidade',
                  '${prensa.velocidade} m/min',
                  Icons.speed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFFFABA00),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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

  Widget _buildProblemasList(int visitaId) {
    return FutureBuilder<List<Problema>>(
      future: DatabaseHelper.instance.getProblemasByVisita(visitaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFABA00)),
          );
        }

        final problemas = snapshot.data ?? [];

        if (problemas.isEmpty) {
          return Container();
        }

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Problemas Identificados',
                      style: TextStyle(
                        color: Color(0xFFFABA00),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFFFABA00),
                        size: 20,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: () =>
                          _editarProblema(visitaId, problemas.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProblemaItem(
                  'Redutor Principal',
                  problemas.first.problemaRedutorPrincipal == 1,
                  problemas.first.comentarioRedutorPrincipal,
                ),
                const Divider(color: Colors.grey),
                _buildProblemaItem(
                  'Temperatura',
                  problemas.first.problemaTemperatura == 1,
                  problemas.first.comentarioTemperatura,
                ),
                const Divider(color: Colors.grey),
                _buildProblemaItem(
                  'Tambor Principal',
                  problemas.first.problemaTamborPrincipal == 1,
                  problemas.first.comentarioTamborPrincipal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProblemaItem(
      String titulo, bool temProblema, String? comentario) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              temProblema ? Icons.error : Icons.check_circle,
              color: temProblema ? Colors.red : Colors.green,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (comentario != null && comentario.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              comentario,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _editarProblema(int visitaId, Problema problema) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroProblemaScreen(
          visitaId: visitaId,
          problema: problema,
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _carregarDados();
        });
      }
    });
  }
}
