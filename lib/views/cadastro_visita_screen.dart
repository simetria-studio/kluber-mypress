import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import 'selecionar_cadastro_screen.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';
import '../models/usuario_kluber_model.dart';

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
  DateTime _dataVisita = DateTime.now();
  List<Cliente> _clientes = [];
  bool _isLoadingClientes = true;
  final _clienteService = ClienteService();
  Cliente? _selectedCliente;
  List<UsuarioKluber> _usuariosKluber = [];
  bool _isLoadingUsuarios = true;
  UsuarioKluber? _selectedUsuario;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
    _carregarUsuarios();
  }

  Future<void> _carregarClientes() async {
    try {
      final clientes = await _clienteService.getClientes();
      setState(() {
        _clientes = clientes;
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
                  SelecionarCadastroScreen(visitaId: visitaId),
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
                                        'Selecionar Cliente',
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
                                      hintText: 'Buscar cliente...',
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
                                        // Filtrar a lista de clientes
                                        _clientes = _clientes.where((cliente) {
                                          return cliente.razaoSocial
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
                                itemCount: _clientes.length,
                                itemBuilder: (context, index) {
                                  final cliente = _clientes[index];
                                  return ListTile(
                                    title: Text(
                                      cliente.razaoSocial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Código: ${cliente.codigoCliente}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedCliente = cliente;
                                        _clienteController.text =
                                            cliente.codigoCliente;
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

  @override
  void dispose() {
    _clienteController.dispose();
    _contatoClienteController.dispose();
    _contatoKluberController.dispose();
    super.dispose();
  }
}
