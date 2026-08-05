import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../models/cliente_model.dart';
import '../models/usuario_kluber_model.dart';
import '../helpers/url_helper.dart';

class ClienteService {
  static const String _clientesKey = 'cached_clientes';
  static const String _usuariosKey = 'cached_usuarios_kluber';
  static const String _lastUpdateKey = 'last_clientes_update';

  // A resposta de clientes trafega sem Content-Length e ocasionalmente chega
  // com bytes faltando, o que quebra o parsing. Nesse caso vale retentar.
  static const int _maxTentativas = 3;
  
  // Singleton pattern para garantir uma única instância
  static final ClienteService _instance = ClienteService._internal();
  factory ClienteService() => _instance;
  ClienteService._internal();
  
  Timer? _autoUpdateTimer;

  Future<List<Cliente>> getClientes() async {
    // Inicializar timer de atualização automática na primeira chamada
    _initAutoUpdate();

    final clientes = await _baixarClientes();
    if (clientes != null && clientes.isNotEmpty) {
      return clientes;
    }

    print('📝 Usando cache local');
    return await _getClientesCache();
  }

  /// Baixa os clientes do servidor, retentando quando o corpo da resposta
  /// chega corrompido. Retorna `null` quando não foi possível obter a lista.
  Future<List<Cliente>?> _baixarClientes() async {
    for (int tentativa = 1; tentativa <= _maxTentativas; tentativa++) {
      try {
        final response = await http.post(
          Uri.parse(UrlHelper.clientesUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Accept-Charset': 'utf-8',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          print('⚠️ Status ${response.statusCode} ao carregar clientes');
          return null;
        }

        if (response.bodyBytes.isEmpty) {
          print('⚠️ Resposta vazia do servidor');
          return null;
        }

        // Decodifica a partir dos bytes: quando a resposta vem sem charset,
        // response.body cai em latin-1 e corrompe os acentos.
        final corpo = utf8.decode(response.bodyBytes, allowMalformed: true);

        final List<dynamic> data = json.decode(corpo);
        print('📊 Clientes recebidos do servidor: ${data.length} registros');

        if (data.isEmpty) {
          print('⚠️ Lista de clientes vazia retornada do servidor');
          return null;
        }

        final List<Cliente> clientes = [];
        int erros = 0;

        for (int i = 0; i < data.length; i++) {
          try {
            clientes.add(Cliente.fromJson(data[i]));
          } catch (e) {
            erros++;
            print('⚠️ Erro ao processar cliente ${i + 1}: $e');
          }
        }

        if (erros > 0) {
          print('⚠️ $erros clientes com erro foram ignorados');
        }

        if (clientes.isEmpty) {
          print('❌ Nenhum cliente válido foi processado');
          return null;
        }

        await _salvarClientesCache(clientes);
        await _salvarUltimaAtualizacao();
        print('✅ Cache atualizado: ${clientes.length} clientes salvos');
        return clientes;
      } catch (e) {
        // Corpo truncado ou conexão encerrada no meio do envio. A leitura é
        // idempotente, então vale repetir antes de cair no cache.
        print('❌ Falha ao baixar clientes '
            '(tentativa $tentativa/$_maxTentativas): $e');
        if (tentativa == _maxTentativas) {
          return null;
        }
        await Future.delayed(Duration(milliseconds: 500 * tentativa));
      }
    }

    return null;
  }

  // Método otimizado para busca local ultra-rápida
  Future<List<Cliente>> searchClientes(String query) async {
    if (query.trim().isEmpty) {
      return await getClientes();
    }

    try {
      // Busca apenas local (mais rápida e confiável)
      final localResults = await _searchClientesLocal(query);
      print('Busca local executada com ${localResults.length} resultados');
      return localResults;
    } catch (e) {
      print('Erro na busca local: $e');
      return [];
    }
  }

  // Método de busca local como fallback
  Future<List<Cliente>> _searchClientesLocal(String query) async {
    final clientesCache = await _getClientesCache();
    if (query.trim().isEmpty) {
      return clientesCache;
    }

    final normalizedQuery = _normalizeText(query.toLowerCase());
    final queryTerms = normalizedQuery.split(' ').where((term) => term.isNotEmpty).toList();

    final List<ClienteWithScore> clientesWithScore = [];

    for (final cliente in clientesCache) {
      int score = 0;
      
      // Normalizar campos do cliente
      final razaoSocialNorm = _normalizeText(cliente.razaoSocial.toLowerCase());
      final nomeFantasiaNorm = _normalizeText(cliente.nomeFantasia.toLowerCase());
      final codigoClienteNorm = _normalizeText(cliente.codigoCliente.toLowerCase());
      final emailNorm = _normalizeText(cliente.email.toLowerCase());

      for (final term in queryTerms) {
        // Código do cliente (maior prioridade)
        if (codigoClienteNorm == term) {
          score += 100;
        } else if (codigoClienteNorm.contains(term)) {
          score += 80;
        }

        // Razão social
        if (razaoSocialNorm.startsWith(term)) {
          score += 70;
        } else if (razaoSocialNorm.contains(term)) {
          score += 50;
        }

        // Nome fantasia
        if (nomeFantasiaNorm.startsWith(term)) {
          score += 65;
        } else if (nomeFantasiaNorm.contains(term)) {
          score += 45;
        }

        // Email
        if (emailNorm.contains(term)) {
          score += 20;
        }
      }

      if (score > 0) {
        clientesWithScore.add(ClienteWithScore(cliente, score));
      }
    }

    // Ordenar por score
    clientesWithScore.sort((a, b) => b.score.compareTo(a.score));
        return clientesWithScore.map((c) => c.cliente).toList();
  }

  // ========== MÉTODOS DE ATUALIZAÇÃO AUTOMÁTICA ==========
  
  void _initAutoUpdate() {
    // Se já existe um timer, não criar outro
    if (_autoUpdateTimer?.isActive == true) return;
    
    print('Iniciando sistema de atualização automática de clientes...');
    
    // Timer que executa a cada 1 hora (3600 segundos)
    _autoUpdateTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _atualizarClientesAutomaticamente(),
    );
    
    print('Timer de atualização automática iniciado - execução a cada 1 hora');
  }

  Future<void> _atualizarClientesAutomaticamente() async {
    print('🔄 Iniciando atualização automática de clientes...');

    final clientes = await _baixarClientes();
    if (clientes == null) {
      print('💾 Mantendo cache atual');
    }
  }

  Future<void> _salvarUltimaAtualizacao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getUltimaAtualizacao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('Erro ao obter última atualização: $e');
    }
    return null;
  }

  void stopAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = null;
    print('Timer de atualização automática cancelado');
  }

  bool get isAutoUpdateActive => _autoUpdateTimer?.isActive == true;

  // Método para forçar atualização manual
  Future<void> forceUpdate() async {
    print('🔄 Forçando atualização manual de clientes...');
    await _atualizarClientesAutomaticamente();
  }

  // Método para limpar cache em caso de corrupção
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clientesKey);
      await prefs.remove(_lastUpdateKey);
      print('🗑️ Cache de clientes limpo com sucesso');
    } catch (e) {
      print('❌ Erro ao limpar cache: $e');
    }
  }

  // Método para verificar integridade do cache
  Future<bool> isCacheValid() async {
    try {
      final clientes = await _getClientesCache();
      return clientes.isNotEmpty;
    } catch (e) {
      print('❌ Cache corrompido: $e');
      return false;
    }
  }

  // ========== FIM DOS MÉTODOS DE ATUALIZAÇÃO AUTOMÁTICA ==========

  // Função para normalizar texto
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '');
  }

  Future<List<UsuarioKluber>> getUsuariosKluber() async {
    try {
      final response = await http.post(
        Uri.parse(UrlHelper.usuariosKluberUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final usuarios =
            data.map((json) => UsuarioKluber.fromJson(json)).toList();
        await _salvarUsuariosCache(usuarios);
        return usuarios;
      } else {
        return await _getUsuariosCache();
      }
    } catch (e) {
      return await _getUsuariosCache();
    }
  }

  Future<void> _salvarClientesCache(List<Cliente> clientes) async {
    final prefs = await SharedPreferences.getInstance();
    final clientesJson = clientes.map((c) => c.toJson()).toList();
    await prefs.setString(_clientesKey, json.encode(clientesJson));
  }

  Future<List<Cliente>> _getClientesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientesString = prefs.getString(_clientesKey);

      if (clientesString != null && clientesString.isNotEmpty) {
        try {
          final List<dynamic> clientesJson = json.decode(clientesString);
          
          // Processar cada cliente do cache individualmente
          final List<Cliente> clientes = [];
          int erros = 0;
          
          for (int i = 0; i < clientesJson.length; i++) {
            try {
              final cliente = Cliente.fromJson(clientesJson[i]);
              clientes.add(cliente);
            } catch (e) {
              erros++;
              print('⚠️ Erro ao processar cliente ${i + 1} do cache: $e');
            }
          }
          
          if (erros > 0) {
            print('⚠️ ${erros} clientes com erro ignorados do cache');
          }
          
          if (clientes.isNotEmpty) {
            print('📱 ${clientes.length} clientes carregados do cache local');
            return clientes;
          } else {
            print('❌ Cache local vazio ou corrompido');
            return [];
          }
          
        } catch (e) {
          print('❌ Erro ao decodificar cache local: $e');
          // Limpar cache corrompido
          await prefs.remove(_clientesKey);
          print('🗑️ Cache corrompido removido');
          return [];
        }
      } else {
        print('📭 Cache local vazio');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao acessar cache local: $e');
      return [];
    }
  }

  Future<void> _salvarUsuariosCache(List<UsuarioKluber> usuarios) async {
    final prefs = await SharedPreferences.getInstance();
    final usuariosJson = usuarios.map((u) => u.toJson()).toList();
    await prefs.setString(_usuariosKey, json.encode(usuariosJson));
  }

  Future<List<UsuarioKluber>> _getUsuariosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuariosString = prefs.getString(_usuariosKey);

      if (usuariosString != null) {
        final List<dynamic> usuariosJson = json.decode(usuariosString);
        return usuariosJson
            .map((json) => UsuarioKluber.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// Classe auxiliar para ordenação por relevância
class ClienteWithScore {
  final Cliente cliente;
  final int score;

  ClienteWithScore(this.cliente, this.score);
}
