import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';
import '../services/storage_service.dart';
import '../models/usuario_kluber_model.dart';
import 'cadastro_prensa_temperatura_screen.dart';
import '../widgets/cliente_picker_sheet.dart';



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
  final _storageService = StorageService();
  Cliente? _selectedCliente;
  List<UsuarioKluber> _usuariosKluber = [];
  List<UsuarioKluber> _usuariosKluberFiltrados = [];
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
    _clienteController.dispose();
    _contatoClienteController.dispose();
    _contatoKluberController.dispose();
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
    if (_ultimaAtualizacao == null) {
      if (_clientes.isNotEmpty) return 'Cache local (${_clientes.length})';
      return 'Nunca atualizado';
    }

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


  Future<void> _abrirSeletorCliente() async {
    final selecionado = await ClientePickerSheet.show(
      context,
      clientesIniciais: _clientes,
      ultimaAtualizacao: _ultimaAtualizacao,
    );
    if (selecionado == null || !mounted) return;
    setState(() {
      _selectedCliente = selecionado;
      _clienteController.text = selecionado.codigoCliente;
    });
    await _carregarClientes();
  }

  Future<void> _carregarUsuarios() async {
    try {
      final usuarios = await _clienteService.getUsuariosKluber();
      final nomeLogado = await _storageService.getUserName();
      UsuarioKluber? usuarioLogado;

      if (nomeLogado != null && nomeLogado.trim().isNotEmpty) {
        final nomeLower = nomeLogado.trim().toLowerCase();
        try {
          usuarioLogado = usuarios.firstWhere(
            (u) =>
                u.nomeUsuario.toLowerCase() == nomeLower ||
                u.nomeUsuarioCompleto.toLowerCase() == nomeLower,
          );
        } catch (_) {
          usuarioLogado = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _usuariosKluber = usuarios;
        _usuariosKluberFiltrados = usuarios;
        _isLoadingUsuarios = false;
        if (usuarioLogado != null) {
          _selectedUsuario = usuarioLogado;
          _contatoKluberController.text = usuarioLogado.nomeUsuarioCompleto;
        } else if (nomeLogado != null &&
            nomeLogado.trim().isNotEmpty &&
            _contatoKluberController.text.isEmpty) {
          _contatoKluberController.text = nomeLogado.trim();
        }
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
    final now = DateTime.now();
    final firstDate = DateTime(2024);
    final lastDate = DateTime(now.year + 5, 12, 31);
    var initialDate = _dataVisita;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

  void _abrirSeletorContatoKluber() {
    _usuariosKluberFiltrados = List.from(_usuariosKluber);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                          setModalState(() {
                            final query = value.toLowerCase();
                            _usuariosKluberFiltrados = _usuariosKluber
                                .where((usuario) {
                              return usuario.nomeUsuarioCompleto
                                      .toLowerCase()
                                      .contains(query) ||
                                  usuario.nomeUsuario
                                      .toLowerCase()
                                      .contains(query);
                            }).toList();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingUsuarios
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFABA00),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _usuariosKluberFiltrados.length,
                          itemBuilder: (context, index) {
                            final usuario = _usuariosKluberFiltrados[index];
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
                                      usuario.nomeUsuarioCompleto;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
                   onTap: _abrirSeletorCliente,
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
                // Campo de Contato Kluber (editável + seleção da lista)
                TextFormField(
                  controller: _contatoKluberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contato Kluber',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: 'Digite ou selecione o contato',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFFFABA00),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFFABA00),
                      ),
                      tooltip: 'Selecionar da lista',
                      onPressed: _abrirSeletorContatoKluber,
                    ),
                  ),
                  onChanged: (_) {
                    _selectedUsuario = null;
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, informe o contato Kluber';
                    }
                    return null;
                  },
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
