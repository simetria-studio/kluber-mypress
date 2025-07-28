import 'package:flutter/material.dart';
import '../models/prensa_model.dart';
import '../models/temperatura_prensa_model.dart';
import '../database/database_helper.dart';
import 'cadastro_prensa_screen.dart';
import '../models/elemento_model.dart';
import 'selecionar_elemento_screen.dart';
import '../models/problema_model.dart';
import 'cadastro_temperatura_screen.dart';

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

  // Variáveis para inspeção de graxa
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
    _carregarProblemaExistente();
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

  Future<void> _carregarProblemaExistente() async {
    try {
      final problemas = await DatabaseHelper.instance.getProblemasByVisita(widget.visitaId);
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
    } catch (e) {
      print('Erro ao carregar problema existente: $e');
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
                    const SizedBox(height: 24),
                    
                    // Formulário de Inspeção de Graxa
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inspeção de Graxa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Redutor Principal
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
                                const Text(
                                  'Redutor Principal',
                                  style: TextStyle(
                                    color: Color(0xFFFABA00),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                DropdownButtonFormField<String>(
                                  value: _lubrificanteSelecionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Lubrificante do Redutor Principal',
                                    labelStyle: TextStyle(color: Colors.white),
                                    prefixIcon:
                                        Icon(Icons.oil_barrel, color: Color(0xFFFABA00)),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                                    ),
                                    border: UnderlineInputBorder(),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Color(0xFFFABA00)),
                                  dropdownColor: Colors.grey[900],
                                  style: const TextStyle(color: Colors.white),
                                  items: _tiposLubrificantes.map((String lubrificante) {
                                    return DropdownMenuItem<String>(
                                      value: lubrificante,
                                      child: Text(lubrificante),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _lubrificanteSelecionado = newValue;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Text(
                                      'Problema no redutor principal',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: _problemaRedutorPrincipal,
                                      onChanged: (bool value) {
                                        setState(() {
                                          _problemaRedutorPrincipal = value;
                                        });
                                      },
                                      activeColor: const Color(0xFFFABA00),
                                    ),
                                  ],
                                ),
                                if (_problemaRedutorPrincipal)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: TextFormField(
                                      controller: _comentarioRedutorController,
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Descreva o problema no redutor principal...',
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        filled: true,
                                        fillColor: Colors.grey[900],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color:
                                                const Color(0xFFFABA00).withOpacity(0.3),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color:
                                                const Color(0xFFFABA00).withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFABA00),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_problemaRedutorPrincipal &&
                                            (value?.isEmpty ?? true)) {
                                          return 'Por favor, descreva o problema';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Zona Quente
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
                                const Text(
                                  'Rolamento da zona quente',
                                  style: TextStyle(
                                    color: Color(0xFFFABA00),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                DropdownButtonFormField<String>(
                                  value: _graxaRolamentosSelecionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Graxa dos rolamentos das zonas quentes',
                                    labelStyle: TextStyle(color: Colors.white),
                                    prefixIcon:
                                        Icon(Icons.oil_barrel, color: Color(0xFFFABA00)),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                                    ),
                                    border: UnderlineInputBorder(),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Color(0xFFFABA00)),
                                  dropdownColor: Colors.grey[900],
                                  style: const TextStyle(color: Colors.white),
                                  items: _tiposGraxaRolamentos.map((String graxa) {
                                    return DropdownMenuItem<String>(
                                      value: graxa,
                                      child: Text(graxa),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _graxaRolamentosSelecionada = newValue;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Text(
                                      'Problema na zona quente',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: _problemaTemperatura,
                                      onChanged: (bool value) {
                                        setState(() {
                                          _problemaTemperatura = value;
                                        });
                                      },
                                      activeColor: const Color(0xFFFABA00),
                                    ),
                                  ],
                                ),
                                if (_problemaTemperatura)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: TextFormField(
                                      controller: _comentarioTemperaturaController,
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'Descreva o problema de temperatura...',
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        filled: true,
                                        fillColor: Colors.grey[900],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color:
                                                const Color(0xFFFABA00).withOpacity(0.3),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color:
                                                const Color(0xFFFABA00).withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFABA00),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_problemaTemperatura &&
                                            (value?.isEmpty ?? true)) {
                                          return 'Por favor, descreva o problema';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
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
                                const Text(
                                  'Rolamento da zona quente',
                                  style: TextStyle(
                                    color: Color(0xFFFABA00),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                DropdownButtonFormField<String>(
                                  value: _graxaTamborSelecionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Graxa do Tambor Principal',
                                    labelStyle: TextStyle(color: Colors.white),
                                    prefixIcon:
                                        Icon(Icons.oil_barrel, color: Color(0xFFFABA00)),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFFABA00)),
                                    ),
                                    border: UnderlineInputBorder(),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Color(0xFFFABA00)),
                                  dropdownColor: Colors.grey[900],
                                  style: const TextStyle(color: Colors.white),
                                  items: _tiposGraxaTambor.map((String graxa) {
                                    return DropdownMenuItem<String>(
                                      value: graxa,
                                      child: Text(graxa),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _graxaTamborSelecionada = newValue;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Text(
                                      'Problema no Tambor Principal',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: _problemaTamborPrincipal,
                                      onChanged: (bool value) {
                                        setState(() {
                                          _problemaTamborPrincipal = value;
                                        });
                                      },
                                      activeColor: const Color(0xFFFABA00),
                                    ),
                                  ],
                                ),
                                if (_problemaTamborPrincipal)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: TextFormField(
                                      controller: _comentarioTamborController,
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Descreva o problema no tambor principal...',
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        filled: true,
                                        fillColor: Colors.grey[900],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color:
                                                const Color(0xFFFABA00).withOpacity(0.3),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color:
                                                const Color(0xFFFABA00).withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFABA00),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_problemaTamborPrincipal &&
                                            (value?.isEmpty ?? true)) {
                                          return 'Por favor, descreva o problema';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Botão Salvar
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isSavingProblema ? null : _salvarProblema,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFABA00),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSavingProblema
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'SALVAR INSPEÇÃO DE GRAXA',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                                visitaId: widget.visitaId,
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

  Widget _buildProblemasList(int visitaId) {
    return FutureBuilder<List<Problema>>(
      future: DatabaseHelper.instance.getProblemasByVisita(visitaId),
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
                    'Inspeção de Graxa Relatados',
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
                          'Inspeção de Graxa',
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
                      'Redutor Principal',
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

  Future<void> _salvarProblema() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSavingProblema = true;
      });

      try {
        final problemas = await DatabaseHelper.instance.getProblemasByVisita(widget.visitaId);
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
          myPressVisitaId: widget.visitaId,
        );

        if (problemaExistente != null) {
          await DatabaseHelper.instance.updateProblema(problema);
        } else {
          await DatabaseHelper.instance.createProblema(problema);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inspeção de graxa salva com sucesso!'),
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

  @override
  void dispose() {
    _comentarioRedutorController.dispose();
    _comentarioTemperaturaController.dispose();
    _comentarioTamborController.dispose();
    super.dispose();
  }
}
