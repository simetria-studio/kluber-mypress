import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cliente_model.dart';
import '../services/cliente_service.dart';

/// Bottom sheet autocontido para seleção de clientes.
/// Carrega o cache imediatamente e não depende do setState da tela pai.
class ClientePickerSheet extends StatefulWidget {
  const ClientePickerSheet({
    super.key,
    required this.onSelected,
    this.clientesIniciais = const [],
    this.ultimaAtualizacao,
  });

  final ValueChanged<Cliente> onSelected;
  final List<Cliente> clientesIniciais;
  final DateTime? ultimaAtualizacao;

  static Future<Cliente?> show(
    BuildContext context, {
    List<Cliente> clientesIniciais = const [],
    DateTime? ultimaAtualizacao,
  }) {
    return showModalBottomSheet<Cliente>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClientePickerSheet(
        clientesIniciais: clientesIniciais,
        ultimaAtualizacao: ultimaAtualizacao,
        onSelected: (cliente) => Navigator.pop(context, cliente),
      ),
    );
  }

  @override
  State<ClientePickerSheet> createState() => _ClientePickerSheetState();
}

class _ClientePickerSheetState extends State<ClientePickerSheet> {
  final _clienteService = ClienteService();
  final _searchController = TextEditingController();
  final _debounce = <Timer?>[];

  List<Cliente> _clientes = [];
  List<Cliente> _filtrados = [];
  bool _isLoading = true;
  bool _isSearching = false;
  DateTime? _ultimaAtualizacao;

  @override
  void initState() {
    super.initState();
    _clientes = List.of(widget.clientesIniciais);
    _filtrados = List.of(widget.clientesIniciais);
    _ultimaAtualizacao = widget.ultimaAtualizacao;
    _isLoading = _clientes.isEmpty;
    _carregar();
  }

  @override
  void dispose() {
    for (final timer in _debounce) {
      timer?.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final clientes = forceRefresh
          ? await _clienteService.forceUpdate()
          : await _clienteService.getClientes();
      final ultima = await _clienteService.getUltimaAtualizacao();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        if (_searchController.text.trim().isEmpty) {
          _filtrados = clientes;
        }
        _ultimaAtualizacao = ultima;
        _isLoading = false;
      });
      if (_searchController.text.trim().isNotEmpty) {
        await _buscar(_searchController.text);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buscar(String query) async {
    for (final timer in _debounce) {
      timer?.cancel();
    }
    _debounce.clear();

    if (query.trim().isEmpty) {
      setState(() {
        _filtrados = _clientes;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final timer = Timer(const Duration(milliseconds: 150), () async {
      try {
        final resultados = await _clienteService.searchClientes(query);
        if (!mounted) return;
        setState(() {
          _filtrados = resultados;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        final searchLower = query.toLowerCase();
        setState(() {
          _filtrados = _clientes.where((cliente) {
            return cliente.razaoSocial.toLowerCase().contains(searchLower) ||
                cliente.nomeFantasia.toLowerCase().contains(searchLower) ||
                cliente.codigoCliente.toLowerCase().contains(searchLower) ||
                cliente.email.toLowerCase().contains(searchLower);
          }).toList();
          _isSearching = false;
        });
      }
    });
    _debounce.add(timer);
  }

  String _formatarUltimaAtualizacao() {
    if (_ultimaAtualizacao == null) {
      if (_clientes.isNotEmpty) return 'Cache local (${_clientes.length})';
      return 'Nunca atualizado';
    }

    final agora = DateTime.now();
    final diferenca = agora.difference(_ultimaAtualizacao!);
    if (diferenca.inMinutes < 1) return 'Atualizado agora';
    if (diferenca.inMinutes < 60) {
      return 'Atualizado há ${diferenca.inMinutes}min';
    }
    if (diferenca.inHours < 24) {
      return 'Atualizado há ${diferenca.inHours}h';
    }
    return 'Atualizado em ${DateFormat('dd/MM às HH:mm').format(_ultimaAtualizacao!)}';
  }

  TextSpan _highlight(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) return TextSpan(text: text, style: baseStyle);

    final term = query.toLowerCase().trim();
    final textLower = text.toLowerCase();
    final index = textLower.indexOf(term);
    if (index < 0) return TextSpan(text: text, style: baseStyle);

    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, index), style: baseStyle),
        TextSpan(
          text: text.substring(index, index + term.length),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFFABA00).withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: text.substring(index + term.length), style: baseStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            Icon(Icons.sync, size: 14, color: Colors.grey[400]),
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
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) async {
                            if (value == 'refresh') {
                              await _carregar(forceRefresh: true);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dados atualizados!'),
                                  backgroundColor: Color(0xFFFABA00),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else if (value == 'clear') {
                              final confirmar = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text(
                                    'Limpar Cache',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Isso removerá os dados locais de clientes. Continuar?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Limpar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmar == true) {
                                await _clienteService.clearCache();
                                await _carregar(forceRefresh: true);
                              }
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'refresh',
                              child: Text('Atualizar agora'),
                            ),
                            PopupMenuItem(
                              value: 'clear',
                              child: Text('Limpar cache'),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Busca instantânea por nome, código ou email',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFABA00),
                              ),
                            ),
                          )
                        : const Icon(Icons.search, color: Color(0xFFFABA00)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _buscar('');
                            },
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
                    setState(() {});
                    _buscar(value);
                  },
                ),
                if (_searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _isSearching
                          ? 'Buscando...'
                          : '${_filtrados.length} cliente(s) encontrado(s)',
                      style: TextStyle(
                        color: _isSearching
                            ? const Color(0xFFFABA00)
                            : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _filtrados.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFABA00)),
                  )
                : _filtrados.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Nenhum cliente no cache.\nToque em ⋮ e atualize.'
                              : 'Nenhum cliente encontrado',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtrados.length,
                        itemBuilder: (context, index) {
                          final cliente = _filtrados[index];
                          final query = _searchController.text;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            color: Colors.grey[850],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                                text: _highlight(
                                  cliente.razaoSocial,
                                  query,
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: _highlight(
                                      'Código: ${cliente.codigoCliente}',
                                      query,
                                      TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (cliente.nomeFantasia.isNotEmpty &&
                                      cliente.nomeFantasia !=
                                          cliente.razaoSocial)
                                    RichText(
                                      text: _highlight(
                                        cliente.nomeFantasia,
                                        query,
                                        TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (cliente.email.isNotEmpty)
                                    RichText(
                                      text: _highlight(
                                        cliente.email,
                                        query,
                                        TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFFABA00),
                                size: 16,
                              ),
                              onTap: () => widget.onSelected(cliente),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
