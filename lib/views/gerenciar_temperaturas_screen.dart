import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../models/temperatura_prensa_model.dart';
import '../database/database_helper.dart';
import 'cadastro_temperatura_screen.dart';

class GerenciarTemperaturasScreen extends StatefulWidget {
  const GerenciarTemperaturasScreen({super.key});

  @override
  State<GerenciarTemperaturasScreen> createState() =>
      _GerenciarTemperaturasScreenState();
}

class _GerenciarTemperaturasScreenState extends State<GerenciarTemperaturasScreen> {
  List<Prensa> _prensas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPrensas();
  }

  Future<void> _carregarPrensas() async {
    try {
      final prensas = await DatabaseHelper.instance.getAllPrensas();
      setState(() {
        _prensas = prensas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar prensas: ${e.toString()}')),
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
          'Gerenciar Temperaturas',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFABA00)),
            )
          : _prensas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Color(0xFFFABA00),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma prensa cadastrada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _prensas.length,
                  itemBuilder: (context, index) {
                    final prensa = _prensas[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                              builder: (context) => CadastroTemperaturaScreen(
                                prensaId: prensa.id!,
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _carregarPrensas();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
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
                                      color: const Color(0xFFFABA00)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.factory,
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
                                          'Prensa ${prensa.id}',
                                          style: const TextStyle(
                                            color: Color(0xFFFABA00),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${prensa.tipoPrensa} - ${prensa.fabricante}',
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
                              const SizedBox(height: 16),
                              FutureBuilder<List<TemperaturaPrensa>>(
                                future: DatabaseHelper.instance
                                    .getTemperaturasByPrensa(prensa.id!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFFFABA00)),
                                    );
                                  }

                                  final temperaturas = snapshot.data ?? [];

                                  if (temperaturas.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
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

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Últimas temperaturas:',
                                        style: TextStyle(
                                          color: Color(0xFFFABA00),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...temperaturas.take(3).map(
                                            (temperatura) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Data: ${temperatura?.dataRegistro ?? '-'}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Z1: ${temperatura?.zona1?.toStringAsFixed(1) ?? '-'}°C',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 