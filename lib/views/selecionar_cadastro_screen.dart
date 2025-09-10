import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../models/temperatura_prensa_model.dart';
import '../database/database_helper.dart';
import 'cadastro_prensa_screen.dart';
import '../models/elemento_model.dart';
import 'selecionar_elemento_screen.dart';
import '../models/problema_model.dart';
import 'cadastro_temperatura_screen.dart';
import 'cadastro_prensa_temperatura_screen.dart';

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
    setState(() {
      _isLoading = true;
    });

    try {
      final prensas = await DatabaseHelper.instance.getPrensasByVisita(widget.visitaId);

      // Carregar elementos para cada prensa
      final elementosPorPrensa = <int, List<Elemento>>{};
      for (var prensa in prensas) {
        if (prensa.id != null) {
          final elementos = await DatabaseHelper.instance.getElementsByPrensa(prensa.id!);
          elementosPorPrensa[prensa.id!] = elementos;
        }
      }

      if (mounted) {
        setState(() {
          _prensas = prensas;
          _elementosPorPrensa = elementosPorPrensa;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
                      title: 'Nova Prensa e Temperaturas',
                      description: 'Adicione uma nova prensa com temperaturas para esta visita',
                      icon: Icons.precision_manufacturing,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CadastroPrensaTemperaturaScreen(visitaId: widget.visitaId),
                          ),
                        );
                        if (result == true) {
                          _carregarDados();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    

                    const SizedBox(height: 24),
                    if (_prensas.isEmpty)
                      Center(
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
                    else ...[
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
                          final prensa = _prensas[index];
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
                                          color: const Color(0xFFFABA00)
                                              .withOpacity(0.1),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                        icon: const Icon(
                                          Icons.thermostat,
                                          color: Color(0xFFFABA00),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CadastroTemperaturaScreen(
                                                prensaId: prensa.id!,
                                              ),
                                            ),
                                          ).then((value) {
                                            if (value == true) {
                                              setState(() {});
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.settings,
                                          color: Color(0xFFFABA00),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SelecionarElementoScreen(
                                                prensaId: prensa.id!,
                                              ),
                                            ),
                                          ).then((value) {
                                            if (value == true) {
                                              _carregarDados();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Color(0xFFFABA00),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CadastroPrensaScreen(
                                                visitaId: widget.visitaId,
                                                prensa: prensa,
                                              ),
                                            ),
                                          ).then((value) {
                                            if (value == true) {
                                              _carregarDados();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmarExclusao(prensa),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  FutureBuilder<List<TemperaturaPrensa>>(
                                    future: DatabaseHelper.instance.getTemperaturasByPrensa(prensa.id!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFABA00),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }

                                      final temperaturas = snapshot.data ?? [];

                                      if (temperaturas.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[850],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.grey,
                                                size: 16,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Nenhuma temperatura registrada',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: temperaturas.take(3).map((temp) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Data: ${temp?.dataRegistro ?? '-'}',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            color: Color(0xFFFABA00),
                                                            size: 16,
                                                          ),
                                                          constraints: const BoxConstraints(),
                                                          padding: const EdgeInsets.all(8),
                                                          onPressed: () => _editarTemperatura(temp!, prensa.id!),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                            size: 16,
                                                          ),
                                                          constraints: const BoxConstraints(),
                                                          padding: const EdgeInsets.all(8),
                                                          onPressed: () => _confirmarExclusaoTemperatura(temp!),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    _buildTemperaturaItem('Z1', temp?.zona1),
                                                    _buildTemperaturaItem('Z2', temp?.zona2),
                                                    _buildTemperaturaItem('Z3', temp?.zona3),
                                                    _buildTemperaturaItem('Z4', temp?.zona4),
                                                    _buildTemperaturaItem('Z5', temp?.zona5),
                                                  ],
                                                ),
                                                if (temperaturas.last != temp)
                                                  const Divider(height: 8, color: Colors.grey),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    _buildProblemasList(widget.visitaId),
                  ],
                ),
              ),
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

  Future<List<Problema>> _getProblemasByVisita(int visitaId) async {
    final prensas = await DatabaseHelper.instance.getPrensasByVisita(visitaId);
    List<Problema> problemas = [];
    for (var prensa in prensas) {
      final problemasPrensa = await DatabaseHelper.instance.getProblemasByPrensa(prensa.id!);
      problemas.addAll(problemasPrensa);
    }
    return problemas;
  }

  Widget _buildProblemasList(int visitaId) {
    return FutureBuilder<List<Problema>>(
      future: _getProblemasByVisita(visitaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFABA00)),
          );
        }

        if (snapshot.hasError) {
          print('Erro ao carregar problemas: ${snapshot.error}');
          return Center(
            child: Text(
              'Erro ao carregar problemas: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final problemas = snapshot.data ?? [];
     

        if (problemas.isEmpty) {
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
                  const Text(
                    'Demais Aplicações Relatados',
                    style: TextStyle(
                      color: Color(0xFFFABA00),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Nenhum problema registrado',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: problemas.map((problema) {
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
                          'Demais Aplicações',
                          style: TextStyle(
                            color: Color(0xFFFABA00),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [

                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              onPressed: () => _confirmarExclusaoProblema(problema),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProblemaItem(
                      'Lubrificante do Redutor Principal',
                      problema.problemaRedutorPrincipal == '1',
                      problema.comentarioRedutorPrincipal,
                      problema.lubrificanteRedutorPrincipal,
                    ),
                    const Divider(color: Colors.grey),
                    _buildProblemaItem(
                      'Temperatura',
                      problema.problemaTemperatura == '1',
                      problema.comentarioTemperatura,
                      null,
                    ),
                    const Divider(color: Colors.grey),
                    _buildProblemaItem(
                      'Rolamento da zona quente',
                      problema.problemaTamborPrincipal == '1',
                      problema.comentarioTamborPrincipal,
                      problema.graxaTamborPrincipal,
                    ),
                    if (problema.graxaRolamentosZonasQuentes != null) ...[
                      const Divider(color: Colors.grey),
                      _buildProblemaItem(
                        'Graxa Rolamentos Zonas Quentes',
                        true,
                        null,
                        problema.graxaRolamentosZonasQuentes,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProblemaItem(
      String titulo, bool temProblema, String? comentario, String? produto) {
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
        if (produto != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              'Produto: $produto',
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



  Widget _buildTemperaturaItem(String zona, double? temperatura) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$zona:',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                temperatura?.toStringAsFixed(1) ?? '-',
                style: TextStyle(
                  color: temperatura != null ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (temperatura != null)
                const Text(
                  '°C',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarExclusao(Prensa prensa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Excluir Prensa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente excluir a prensa ${prensa.tipoPrensa}?\nEsta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
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
                await DatabaseHelper.instance.deletePrensa(prensa.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prensa excluída com sucesso!'),
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
                      content: Text('Erro ao excluir prensa: ${e.toString()}'),
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

  void _confirmarExclusaoProblema(Problema problema) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Problema'),
          content: const Text('Você tem certeza que deseja excluir este problema?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () async {
                await DatabaseHelper.instance.deleteProblema(problema.id!);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  void _editarTemperatura(TemperaturaPrensa temperatura, int prensaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroTemperaturaScreen(
          prensaId: prensaId,
          temperatura: temperatura,
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {});
      }
    });
  }

  void _confirmarExclusaoTemperatura(TemperaturaPrensa temperatura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Excluir Temperatura',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente excluir esta temperatura?\nEsta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
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
                                 await DatabaseHelper.instance.deleteTemperaturaPrensa(temperatura.id!);
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
                      content: Text('Erro ao excluir temperatura: ${e.toString()}'),
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


}
