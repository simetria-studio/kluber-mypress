import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import 'selecionar_cadastro_screen.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';
import '../models/usuario_kluber_model.dart';
import 'cadastro_prensa_temperatura_screen.dart';



class CadastroVisitaScreen extends StatefulWidget {
  const CadastroVisitaScreen({super.key});

  @override
  State<CadastroVisitaScreen> createState() => _CadastroVisitaScreenState();
}

class _CadastroVisitaScreenState extends State<CadastroVisitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _contatoClienteController = TextEditingController();
  final _contatoKluberController = TextEditingController();
  final _searchClienteController = TextEditingController();
  DateTime _dataVisita = DateTime.now();
  List<Cliente> _clientes = [];
  List<Cliente> _filteredClientes = [];
  bool _isLoadingClientes = true;
  bool _isSearching = false;
  final _clienteService = ClienteService();
  Cliente? _selectedCliente;
  List<UsuarioKluber> _usuariosKluber = [];
  bool _isLoadingUsuarios = true;
  UsuarioKluber? _selectedUsuario;
  Timer? _debounceTimer;
  DateTime? _ultimaAtualizacao;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
    _carregarUsuarios();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchClienteController.dispose();
    // Não parar o timer aqui pois ele deve continuar rodando em background
    // _clienteService.stopAutoUpdate(); // Somente se necessário
    super.dispose();
  }



  // Função de busca local instantânea
  void _searchClientes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredClientes = _clientes;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Debounce mínimo para busca local instantânea
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      try {
        // Busca local ultra-rápida
        final resultados = await _clienteService.searchClientes(query);
        
        if (mounted) {
          setState(() {
            _filteredClientes = resultados;
            _isSearching = false;
          });
        }
      } catch (e) {
        print('Erro na busca: $e');
        if (mounted) {
          setState(() {
            _isSearching = false;
            // Em caso de erro, mostrar dados do cache local
            _filteredClientes = _clientes.where((cliente) {
              final searchLower = query.toLowerCase();
              return cliente.razaoSocial.toLowerCase().contains(searchLower) ||
                     cliente.nomeFantasia.toLowerCase().contains(searchLower) ||
                     cliente.codigoCliente.toLowerCase().contains(searchLower) ||
                     cliente.email.toLowerCase().contains(searchLower);
            }).toList();
          });
        }
      }
    });
  }

  // Função para limpar a busca e resetar valores
  void _clearSearch() {
    _searchClienteController.clear();
    setState(() {
      _filteredClientes = _clientes;
      _isSearching = false;
    });
  }

  // Função para formatar a data da última atualização
  String _formatarUltimaAtualizacao() {
    if (_ultimaAtualizacao == null) return 'Nunca atualizado';
    
    final agora = DateTime.now();
    final diferenca = agora.difference(_ultimaAtualizacao!);
    
    if (diferenca.inMinutes < 1) {
      return 'Atualizado agora';
    } else if (diferenca.inMinutes < 60) {
      return 'Atualizado há ${diferenca.inMinutes}min';
    } else if (diferenca.inHours < 24) {
      return 'Atualizado há ${diferenca.inHours}h';
    } else {
      return 'Atualizado em ${DateFormat('dd/MM às HH:mm').format(_ultimaAtualizacao!)}';
    }
  }

  // Função para destacar termos de busca no texto (versão simplificada)
  TextSpan _buildHighlightedText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final queryTerms = query.toLowerCase().split(' ').where((term) => term.trim().isNotEmpty).toList();
    final textLower = text.toLowerCase();
    
    List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final term in queryTerms) {
      final index = textLower.indexOf(term.toLowerCase(), lastIndex);
      if (index != -1) {
        // Adicionar texto antes do match
        if (index > lastIndex) {
          spans.add(TextSpan(
            text: text.substring(lastIndex, index),
            style: baseStyle,
          ));
        }

        // Adicionar texto destacado
        spans.add(TextSpan(
          text: text.substring(index, index + term.length),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFFABA00).withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ));

        lastIndex = index + term.length;
      }
    }

    // Adicionar texto restante
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans.isNotEmpty ? TextSpan(children: spans) : TextSpan(text: text, style: baseStyle);
  }

  Future<void> _carregarClientes() async {
    try {
      final clientes = await _clienteService.getClientes();
      final ultimaAtualizacao = await _clienteService.getUltimaAtualizacao();
      
      setState(() {
        _clientes = clientes;
        _filteredClientes = clientes;
        _ultimaAtualizacao = ultimaAtualizacao;
        _isLoadingClientes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingClientes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar clientes: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _carregarUsuarios() async {
    try {
      final usuarios = await _clienteService.getUsuariosKluber();
      setState(() {
        _usuariosKluber = usuarios;
        _isLoadingUsuarios = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsuarios = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuários: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataVisita,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFABA00),
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataVisita = picked;
      });
    }
  }

  void _salvarVisita() async {
    if (_formKey.currentState!.validate()) {
      final visita = Visita(
        dataVisita: _dataVisita,
        cliente: _clienteController.text,
        contatoCliente: _contatoClienteController.text,
        contatoKluber: _contatoKluberController.text,
      );

      try {
        final visitaId = await DatabaseHelper.instance.createVisita(visita);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visita cadastrada com sucesso!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CadastroPrensaTemperaturaScreen(visitaId: visitaId),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao cadastrar visita')),
          );
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
          'Cadastrar Visita',
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
                // Data da Visita
                const Text(
                  'Data da Visita',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFABA00).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFFABA00),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_dataVisita),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFFFABA00),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                                 // Campo de Cliente com SearchableDropdown
                 InkWell(
                   onTap: () {
                     // Resetar estado da busca ao abrir o modal
                     _clearSearch();
                     
                     showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                                                     Row(
                                     mainAxisAlignment:
                                         MainAxisAlignment.spaceBetween,
                                     children: [
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           const Text(
                                             'Selecionar Cliente',
                                             style: TextStyle(
                                               color: Colors.white,
                                               fontSize: 20,
                                               fontWeight: FontWeight.bold,
                                             ),
                                           ),
                                           const SizedBox(height: 4),
                                           Row(
                                             children: [
                                               Icon(
                                                 Icons.sync,
                                                 size: 14,
                                                 color: Colors.grey[400],
                                               ),
                                               const SizedBox(width: 4),
                                               Text(
                                                 _formatarUltimaAtualizacao(),
                                                 style: TextStyle(
                                                   color: Colors.grey[400],
                                                   fontSize: 12,
                                                 ),
                                               ),
                                             ],
                                           ),
                                                                                   ],
                                        ),
                                                                                 Row(
                                           children: [
                                             PopupMenuButton<String>(
                                               icon: const Icon(
                                                 Icons.more_vert,
                                                 color: Colors.grey,
                                               ),
                                               onSelected: (value) async {
                                                 if (value == 'refresh') {
                                                   // Forçar atualização manual
                                                   setState(() {
                                                     _isLoadingClientes = true;
                                                   });
                                                   
                                                   await _clienteService.forceUpdate();
                                                   await _carregarClientes();
                                                   
                                                   if (mounted) {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                       const SnackBar(
                                                         content: Text('Dados atualizados!'),
                                                         backgroundColor: Color(0xFFFABA00),
                                                         duration: Duration(seconds: 2),
                                                       ),
                                                     );
                                                   }
                                                 } else if (value == 'clear') {
                                                   // Confirmar antes de limpar cache
                                                   final confirmar = await showDialog<bool>(
                                                     context: context,
                                                     builder: (context) => AlertDialog(
                                                       backgroundColor: Colors.grey[900],
                                                       title: const Text(
                                                         'Limpar Cache',
                                                         style: TextStyle(color: Colors.white),
                                                       ),
                                                       content: const Text(
                                                         'Isso irá remover todos os dados salvos localmente. Deseja continuar?',
                                                         style: TextStyle(color: Colors.grey),
                                                       ),
                                                       actions: [
                                                         TextButton(
                                                           onPressed: () => Navigator.pop(context, false),
                                                           child: const Text('Cancelar'),
                                                         ),
                                                         TextButton(
                                                           onPressed: () => Navigator.pop(context, true),
                                                           child: const Text(
                                                             'Limpar',
                                                             style: TextStyle(color: Colors.red),
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   );
                                                   
                                                   if (confirmar == true) {
                                                     await _clienteService.clearCache();
                                                     await _carregarClientes();
                                                     
                                                     if (mounted) {
                                                       ScaffoldMessenger.of(context).showSnackBar(
                                                         const SnackBar(
                                                           content: Text('Cache limpo com sucesso!'),
                                                           backgroundColor: Colors.green,
                                                           duration: Duration(seconds: 2),
                                                         ),
                                                       );
                                                     }
                                                   }
                                                 }
                                               },
                                               itemBuilder: (context) => [
                                                 const PopupMenuItem(
                                                   value: 'refresh',
                                                   child: Row(
                                                     children: [
                                                       Icon(Icons.refresh, color: Color(0xFFFABA00)),
                                                       SizedBox(width: 8),
                                                       Text('Atualizar dados'),
                                                     ],
                                                   ),
                                                 ),
                                                 const PopupMenuItem(
                                                   value: 'clear',
                                                   child: Row(
                                                     children: [
                                                       Icon(Icons.clear_all, color: Colors.red),
                                                       SizedBox(width: 8),
                                                       Text('Limpar cache'),
                                                     ],
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             IconButton(
                                               onPressed: () => Navigator.pop(context),
                                               icon: const Icon(
                                                 Icons.close,
                                                 color: Colors.white,
                                               ),
                                             ),
                                           ],
                                         ),
                                      ],
                                    ),
                                   const SizedBox(height: 16),
                                   TextField(
                                     controller: _searchClienteController,
                                    style: const TextStyle(color: Colors.white),
                                                                         decoration: InputDecoration(
                                       hintText: 'Busca instantânea por nome, código ou email...',
                                      hintStyle: TextStyle(color: Colors.grey[400]),
                                      prefixIcon: _isSearching
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Padding(
                                                padding: EdgeInsets.all(14),
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFFABA00),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.search,
                                              color: Color(0xFFFABA00),
                                            ),
                                                                             suffixIcon: _searchClienteController.text.isNotEmpty
                                           ? IconButton(
                                               icon: const Icon(
                                                 Icons.clear,
                                                 color: Colors.grey,
                                               ),
                                               onPressed: _clearSearch,
                                             )
                                           : null,
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFABA00),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      _searchClientes(value);
                                    },
                                  ),
                                                                                                           if (_searchClienteController.text.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Column(
                                          children: [
                                            Text(
                                              _isSearching 
                                                  ? 'Buscando...'
                                                  : '${_filteredClientes.length} cliente(s) encontrado(s)',
                                              style: TextStyle(
                                                color: _isSearching ? const Color(0xFFFABA00) : Colors.grey[400],
                                                fontSize: 12,
                                                fontWeight: _isSearching ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                                                                         Row(
                                               mainAxisAlignment: MainAxisAlignment.center,
                                               children: [
                                                 Icon(
                                                   _isSearching ? Icons.hourglass_empty : Icons.flash_on,
                                                   size: 12,
                                                   color: _isSearching ? const Color(0xFFFABA00) : Colors.grey[500],
                                                 ),
                                                 const SizedBox(width: 4),
                                                 Text(
                                                   _isSearching 
                                                       ? 'Processando busca...'
                                                       : 'Busca local instantânea',
                                                   style: TextStyle(
                                                     color: _isSearching ? const Color(0xFFFABA00) : Colors.grey[500],
                                                     fontSize: 10,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             const SizedBox(height: 4),
                                             Row(
                                               mainAxisAlignment: MainAxisAlignment.center,
                                               children: [
                                                 Icon(
                                                   Icons.schedule,
                                                   size: 10,
                                                   color: Colors.grey[600],
                                                 ),
                                                 const SizedBox(width: 2),
                                                 Text(
                                                   'Dados atualizados automaticamente a cada hora',
                                                   style: TextStyle(
                                                     color: Colors.grey[600],
                                                     fontSize: 9,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                          ],
                                        ),
                                      ),
                                ],
                              ),
                            ),
                                                         Expanded(
                               child: _isSearching && _searchClienteController.text.isNotEmpty
                                   ? Center(
                                       child: Column(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           const CircularProgressIndicator(
                                             valueColor: AlwaysStoppedAnimation<Color>(
                                               Color(0xFFFABA00),
                                             ),
                                           ),
                                           const SizedBox(height: 16),
                                           Text(
                                             'Buscando clientes...',
                                             style: TextStyle(
                                               color: Colors.grey[400],
                                               fontSize: 16,
                                             ),
                                           ),
                                           const SizedBox(height: 8),
                                           Row(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                               Icon(
                                                 Icons.flash_on,
                                                 size: 16,
                                                 color: Colors.grey[500],
                                               ),
                                               const SizedBox(width: 4),
                                               Text(
                                                 'Busca instantânea ativa',
                                                 style: TextStyle(
                                                   color: Colors.grey[500],
                                                   fontSize: 12,
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ],
                                       ),
                                     )
                                   : _filteredClientes.isEmpty && _searchClienteController.text.isNotEmpty && !_isSearching
                                       ? Center(
                                           child: Column(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                               Icon(
                                                 Icons.search_off,
                                                 size: 64,
                                                 color: Colors.grey[600],
                                               ),
                                               const SizedBox(height: 16),
                                               Text(
                                                 'Nenhum cliente encontrado',
                                                 style: TextStyle(
                                                   color: Colors.grey[400],
                                                   fontSize: 16,
                                                 ),
                                               ),
                                               const SizedBox(height: 8),
                                               Text(
                                                 'Tente buscar por nome, código ou email',
                                                 style: TextStyle(
                                                   color: Colors.grey[600],
                                                   fontSize: 14,
                                                 ),
                                               ),
                                               const SizedBox(height: 8),
                                               Row(
                                                 mainAxisAlignment: MainAxisAlignment.center,
                                                 children: [
                                                   Icon(
                                                     Icons.search,
                                                     size: 16,
                                                     color: Colors.grey[600],
                                                   ),
                                                   const SizedBox(width: 4),
                                                   Text(
                                                     'Busca local nos dados carregados',
                                                     style: TextStyle(
                                                       color: Colors.grey[600],
                                                       fontSize: 12,
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                             ],
                                           ),
                                         )
                                       : ListView.builder(
                                           itemCount: _filteredClientes.length,
                                           itemBuilder: (context, index) {
                                             final cliente = _filteredClientes[index];
                                             return Card(
                                               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                               color: Colors.grey[850],
                                               shape: RoundedRectangleBorder(
                                                 borderRadius: BorderRadius.circular(12),
                                               ),
                                               child: ListTile(
                                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                 leading: CircleAvatar(
                                                   backgroundColor: const Color(0xFFFABA00),
                                                   child: Text(
                                                     cliente.razaoSocial.isNotEmpty 
                                                         ? cliente.razaoSocial[0].toUpperCase()
                                                         : '?',
                                                     style: const TextStyle(
                                                       color: Colors.black,
                                                       fontWeight: FontWeight.bold,
                                                     ),
                                                   ),
                                                 ),
                                                 title: RichText(
                                                   text: _buildHighlightedText(
                                                     cliente.razaoSocial,
                                                     _searchClienteController.text,
                                                     const TextStyle(color: Colors.white, fontSize: 16),
                                                   ),
                                                 ),
                                                 subtitle: Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     const SizedBox(height: 4),
                                                     RichText(
                                                       text: _buildHighlightedText(
                                                         'Código: ${cliente.codigoCliente}',
                                                         _searchClienteController.text,
                                                         TextStyle(color: Colors.grey[400], fontSize: 14),
                                                       ),
                                                     ),
                                                     if (cliente.nomeFantasia.isNotEmpty && cliente.nomeFantasia != cliente.razaoSocial)
                                                       RichText(
                                                         text: _buildHighlightedText(
                                                           cliente.nomeFantasia,
                                                           _searchClienteController.text,
                                                           TextStyle(color: Colors.grey[400], fontSize: 12),
                                                         ),
                                                       ),
                                                     if (cliente.email.isNotEmpty)
                                                       RichText(
                                                         text: _buildHighlightedText(
                                                           cliente.email,
                                                           _searchClienteController.text,
                                                           TextStyle(color: Colors.grey[500], fontSize: 12),
                                                         ),
                                                       ),
                                                   ],
                                                 ),
                                                 trailing: const Icon(
                                                   Icons.arrow_forward_ios,
                                                   color: Color(0xFFFABA00),
                                                   size: 16,
                                                 ),
                                                 onTap: () {
                                                   setState(() {
                                                     _selectedCliente = cliente;
                                                     _clienteController.text = cliente.codigoCliente;
                                                   });
                                                   Navigator.pop(context);
                                                 },
                                               ),
                                             );
                                           },
                                         ),
                             ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFABA00).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.business,
                          color: Color(0xFFFABA00),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCliente?.razaoSocial ??
                                'Selecione um cliente',
                            style: TextStyle(
                              color: _selectedCliente != null
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFFABA00),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Contato do Cliente
                TextFormField(
                  controller: _contatoClienteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Contato do Cliente',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.person, color: Color(0xFFFABA00)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o contato do cliente';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Campo de Contato Kluber
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Selecionar Contato Kluber',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar usuário...',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Color(0xFFFABA00),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _usuariosKluber =
                                            _usuariosKluber.where((usuario) {
                                          return usuario.nomeUsuarioCompleto
                                              .toLowerCase()
                                              .contains(value.toLowerCase());
                                        }).toList();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _usuariosKluber.length,
                                itemBuilder: (context, index) {
                                  final usuario = _usuariosKluber[index];
                                  return ListTile(
                                    title: Text(
                                      usuario.nomeUsuarioCompleto,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Usuário: ${usuario.nomeUsuario}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedUsuario = usuario;
                                        _contatoKluberController.text =
                                            usuario.nomeUsuario;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFABA00).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Color(0xFFFABA00),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedUsuario?.nomeUsuarioCompleto ??
                                'Selecione um contato Kluber',
                            style: TextStyle(
                              color: _selectedUsuario != null
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFFABA00),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _salvarVisita,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABA00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SALVAR',
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
}
