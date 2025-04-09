import 'package:flutter/material.dart';
import '../models/problema_model.dart';
import '../database/database_helper.dart';

class CadastroProblemaScreen extends StatefulWidget {
  final int visitaId;
  final Problema? problema;

  const CadastroProblemaScreen({
    super.key,
    required this.visitaId,
    this.problema,
  });

  @override
  State<CadastroProblemaScreen> createState() => _CadastroProblemaScreenState();
}

class _CadastroProblemaScreenState extends State<CadastroProblemaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _problemaRedutorPrincipal = false;
  bool _problemaTemperatura = false;
  bool _problemaTamborPrincipal = false;

  final _comentarioRedutorController = TextEditingController();
  final _comentarioTemperaturaController = TextEditingController();
  final _comentarioTamborController = TextEditingController();
  bool _isLoading = false;

  final List<String> _tiposLubrificantes = [
    'Klubersynth GH 6',
    'Klubersynhth GEM 4',
    'Kluberoil GEM 1',
    'Klubersynth MEG 4'
  ];
  String? _lubrificanteSelecionado;

  final List<String> _tiposGraxaRolamentos = [
    'klubersynth BH 72-422',
    'klubertemp HB 53-391',
    'klubertemp GR AR 555'
  ];
  String? _graxaRolamentosSelecionada;

  final List<String> _tiposGraxaTambor = ['Kluberlub PHB 71-461'];
  String? _graxaTamborSelecionada;

  @override
  void initState() {
    super.initState();
    if (widget.problema != null) {
      _problemaRedutorPrincipal =
          widget.problema!.problemaRedutorPrincipal == 1;
      _problemaTemperatura = widget.problema!.problemaTemperatura == 1;
      _problemaTamborPrincipal = widget.problema!.problemaTamborPrincipal == 1;
      _comentarioRedutorController.text =
          widget.problema!.comentarioRedutorPrincipal ?? '';
      _comentarioTemperaturaController.text =
          widget.problema!.comentarioTemperatura ?? '';
      _comentarioTamborController.text =
          widget.problema!.comentarioTamborPrincipal ?? '';
      _lubrificanteSelecionado = widget.problema!.lubrificanteRedutorPrincipal;
      _graxaRolamentosSelecionada =
          widget.problema!.graxaRolamentosZonasQuentes;
      _graxaTamborSelecionada = widget.problema!.graxaTamborPrincipal;
    }
  }

  Future<void> _salvarProblema() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final problema = Problema(
          id: widget.problema?.id,
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

        print('Salvando problema: ${problema.toMap()}');
        if (widget.problema != null) {
          await DatabaseHelper.instance.updateProblema(problema);
          print('Problema atualizado com sucesso');
        } else {
          final id = await DatabaseHelper.instance.createProblema(problema);
          print('Problema criado com ID: $id');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Problema salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('Erro ao salvar problema: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar problema: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
          'Inspeção de Graxa',
          style: TextStyle(color: Color(0xFFFABA00)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFABA00)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        'Zona Quente',
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
                        'Tambor Principal',
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
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _salvarProblema,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SALVAR PROBLEMAS',
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _comentarioRedutorController.dispose();
    _comentarioTemperaturaController.dispose();
    _comentarioTamborController.dispose();
    super.dispose();
  }
}
