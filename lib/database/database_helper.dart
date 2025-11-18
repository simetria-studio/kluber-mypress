import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/visita_model.dart';
import '../models/prensa_model.dart';
import '../models/elemento_model.dart';
import '../models/problema_model.dart';
import '../models/comentario_elemento_model.dart';
import '../models/anexo_comentario_model.dart';
import '../models/temperatura_elemento_model.dart';
import '../models/temperatura_prensa_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('visitas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
      onOpen: (db) async {
        await _verificarECriarTabelas(db);
      },
    );

    return db;
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        // Verifica se a coluna já existe
        var columns = await db.rawQuery('PRAGMA table_info(visitas)');
        bool hasEnviadoColumn = columns.any((column) => column['name'] == 'enviado');
        
        if (!hasEnviadoColumn) {
          // Adiciona a coluna enviado na tabela visitas
          await db.execute('ALTER TABLE visitas ADD COLUMN enviado INTEGER DEFAULT 0');
          // Atualiza registros existentes
          await db.execute('UPDATE visitas SET enviado = 0 WHERE enviado IS NULL');
        }
      } catch (e) {
        print('Erro durante upgrade do banco: $e');
        // Se falhar ao adicionar a coluna, tenta recriar a tabela
        await db.execute('''
          CREATE TABLE IF NOT EXISTS visitas_temp(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data_visita TEXT,
            cliente TEXT,
            contato_cliente TEXT,
            contato_kluber TEXT,
            enviado INTEGER DEFAULT 0
          )
        ''');
        
        // Copia dados existentes
        await db.execute('''
          INSERT INTO visitas_temp(id, data_visita, cliente, contato_cliente, contato_kluber)
          SELECT id, data_visita, cliente, contato_cliente, contato_kluber FROM visitas
        ''');
        
        // Remove tabela antiga
        await db.execute('DROP TABLE visitas');
        
        // Renomeia a nova tabela
        await db.execute('ALTER TABLE visitas_temp RENAME TO visitas');
      }
    }
    
    if (oldVersion < 3) {
      try {
        // Migração da tabela problemas: mudança de visita_id para prensa_id
        var columns = await db.rawQuery('PRAGMA table_info(problemas)');
        bool hasPrensaIdColumn = columns.any((column) => column['name'] == 'prensa_id');
        bool hasVisitaIdColumn = columns.any((column) => column['name'] == 'visita_id');
        
        if (!hasPrensaIdColumn && hasVisitaIdColumn) {
          // Adiciona a nova coluna prensa_id
          await db.execute('ALTER TABLE problemas ADD COLUMN prensa_id INTEGER');
          
          // Remove a coluna antiga visita_id
          await db.execute('''
            CREATE TABLE IF NOT EXISTS problemas_temp(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              problema_redutor_principal TEXT,
              comentario_redutor_principal TEXT,
              lubrificante_redutor_principal TEXT,
              problema_temperatura TEXT,
              comentario_temperatura TEXT,
              problema_tambor_principal TEXT,
              comentario_tambor_principal TEXT,
              graxa_rolamentos_zonas_quentes TEXT,
              graxa_tambor_principal TEXT,
              prensa_id INTEGER,
              FOREIGN KEY (prensa_id) REFERENCES prensas (id)
            )
          ''');
          
          // Copia dados existentes (sem a coluna visita_id)
          await db.execute('''
            INSERT INTO problemas_temp(
              id, problema_redutor_principal, comentario_redutor_principal,
              lubrificante_redutor_principal, problema_temperatura, comentario_temperatura,
              problema_tambor_principal, comentario_tambor_principal,
              graxa_rolamentos_zonas_quentes, graxa_tambor_principal, prensa_id
            )
            SELECT 
              id, problema_redutor_principal, comentario_redutor_principal,
              lubrificante_redutor_principal, problema_temperatura, comentario_temperatura,
              problema_tambor_principal, comentario_tambor_principal,
              graxa_rolamentos_zonas_quentes, graxa_tambor_principal, prensa_id
            FROM problemas
          ''');
          
          // Remove tabela antiga
          await db.execute('DROP TABLE problemas');
          
          // Renomeia a nova tabela
          await db.execute('ALTER TABLE problemas_temp RENAME TO problemas');
        }
      } catch (e) {
        print('Erro durante migração da tabela problemas: $e');
      }
    }
    
    if (oldVersion < 4) {
      try {
        // Adicionar colunas consumo_oleo e contaminacao na tabela elementos
        var columns = await db.rawQuery('PRAGMA table_info(elementos)');
        bool hasConsumoOleoColumn = columns.any((column) => column['name'] == 'consumo_oleo');
        bool hasContaminacaoColumn = columns.any((column) => column['name'] == 'contaminacao');
        
        if (!hasConsumoOleoColumn) {
          await db.execute('ALTER TABLE elementos ADD COLUMN consumo_oleo TEXT');
        }
        
        if (!hasContaminacaoColumn) {
          await db.execute('ALTER TABLE elementos ADD COLUMN contaminacao TEXT');
        }
      } catch (e) {
        print('Erro durante migração da tabela elementos: $e');
      }
    }
    
    if (oldVersion < 5) {
      try {
        // Adicionar coluna comentario na tabela prensas
        var columns = await db.rawQuery('PRAGMA table_info(prensas)');
        bool hasComentarioColumn = columns.any((column) => column['name'] == 'comentario');
        
        if (!hasComentarioColumn) {
          await db.execute('ALTER TABLE prensas ADD COLUMN comentario TEXT');
        }
      } catch (e) {
        print('Erro durante migração da tabela prensas: $e');
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_visita TEXT,
        cliente TEXT,
        contato_cliente TEXT,
        contato_kluber TEXT,
        enviado INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prensas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_prensa TEXT,
        fabricante TEXT,
        comprimento REAL,
        espressura REAL,
        largura REAL,
        produto TEXT,
        velocidade REAL,
        produto_cinta TEXT,
        produto_corrente TEXT,
        produto_bendroads TEXT,
        torque REAL,
        comentario TEXT,
        visita_id INTEGER,
        FOREIGN KEY (visita_id) REFERENCES visitas (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS elementos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consumo1 REAL,
        consumo2 REAL,
        consumo3 REAL,
        toma TEXT,
        posicao TEXT,
        tipo TEXT,
        prensa_id INTEGER,
        consumo_oleo TEXT,
        contaminacao TEXT,
        FOREIGN KEY (prensa_id) REFERENCES prensas (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS problemas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        problema_redutor_principal TEXT,
        comentario_redutor_principal TEXT,
        lubrificante_redutor_principal TEXT,
        problema_temperatura TEXT,
        comentario_temperatura TEXT,
        problema_tambor_principal TEXT,
        comentario_tambor_principal TEXT,
        graxa_rolamentos_zonas_quentes TEXT,
        graxa_tambor_principal TEXT,
        prensa_id INTEGER,
        FOREIGN KEY (prensa_id) REFERENCES prensas (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comentarios_elementos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comentario TEXT NOT NULL,
        mypress_elemento_id INTEGER NOT NULL,
        FOREIGN KEY (mypress_elemento_id) REFERENCES elementos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anexos_comentarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        url TEXT NOT NULL,
        base64 TEXT NOT NULL,
        mypress_comentario_id INTEGER NOT NULL,
        FOREIGN KEY (mypress_comentario_id) REFERENCES comentarios_elementos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS temperaturas_elementos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_registro TEXT NOT NULL,
        zona1 REAL,
        zona2 REAL,
        zona3 REAL,
        zona4 REAL,
        zona5 REAL,
        elemento_id INTEGER NOT NULL,
        FOREIGN KEY (elemento_id) REFERENCES elementos (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _verificarECriarTabelas(Database db) async {
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    );

    final tableNames = tables.map((t) => t['name'] as String).toList();

    if (!tableNames.contains('visitas')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS visitas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data_visita TEXT,
          cliente TEXT,
          contato_cliente TEXT,
          contato_kluber TEXT,
          enviado INTEGER DEFAULT 0
        )
      ''');
    } else {
      try {
        // Verifica se a coluna enviado existe
        var columns = await db.rawQuery('PRAGMA table_info(visitas)');
        bool hasEnviadoColumn = columns.any((column) => column['name'] == 'enviado');
        
        if (!hasEnviadoColumn) {
          // Tenta adicionar a coluna
          await db.execute('ALTER TABLE visitas ADD COLUMN enviado INTEGER DEFAULT 0');
          // Atualiza registros existentes
          await db.execute('UPDATE visitas SET enviado = 0 WHERE enviado IS NULL');
        }
      } catch (e) {
        print('Erro ao verificar/adicionar coluna enviado: $e');
        // Se falhar, tenta recriar a tabela preservando os dados
        await db.execute('''
          CREATE TABLE IF NOT EXISTS visitas_temp(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data_visita TEXT,
            cliente TEXT,
            contato_cliente TEXT,
            contato_kluber TEXT,
            enviado INTEGER DEFAULT 0
          )
        ''');
        
        // Copia dados existentes
        await db.execute('''
          INSERT INTO visitas_temp(id, data_visita, cliente, contato_cliente, contato_kluber)
          SELECT id, data_visita, cliente, contato_cliente, contato_kluber FROM visitas
        ''');
        
        // Remove tabela antiga
        await db.execute('DROP TABLE visitas');
        
        // Renomeia a nova tabela
        await db.execute('ALTER TABLE visitas_temp RENAME TO visitas');
      }
    }

    if (!tableNames.contains('prensas')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prensas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo_prensa TEXT,
          fabricante TEXT,
          comprimento REAL,
          espressura REAL,
          largura REAL,
          produto TEXT,
          velocidade REAL,
          produto_cinta TEXT,
          produto_corrente TEXT,
          produto_bendroads TEXT,
          torque REAL,
          comentario TEXT,
          visita_id INTEGER,
          FOREIGN KEY (visita_id) REFERENCES visitas (id)
        )
      ''');
    } else {
      try {
        // Verifica se a coluna largura existe
        var columns = await db.rawQuery('PRAGMA table_info(prensas)');
        bool hasLarguraColumn = columns.any((column) => column['name'] == 'largura');
        bool hasComentarioColumn = columns.any((column) => column['name'] == 'comentario');
        
        if (!hasLarguraColumn) {
          // Tenta adicionar a coluna largura
          await db.execute('ALTER TABLE prensas ADD COLUMN largura REAL');
        }
        
        if (!hasComentarioColumn) {
          // Tenta adicionar a coluna comentario
          await db.execute('ALTER TABLE prensas ADD COLUMN comentario TEXT');
        }
      } catch (e) {
        print('Erro ao verificar/adicionar colunas na tabela prensas: $e');
      }
    }

    if (!tableNames.contains('elementos')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS elementos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          consumo1 REAL,
          consumo2 REAL,
          consumo3 REAL,
          toma TEXT,
          posicao TEXT,
          tipo TEXT,
          prensa_id INTEGER,
          consumo_oleo TEXT,
          contaminacao TEXT,
          FOREIGN KEY (prensa_id) REFERENCES prensas (id)
        )
      ''');
    } else {
      try {
        // Verifica se as colunas consumo_oleo e contaminacao existem
        var columns = await db.rawQuery('PRAGMA table_info(elementos)');
        bool hasConsumoOleoColumn = columns.any((column) => column['name'] == 'consumo_oleo');
        bool hasContaminacaoColumn = columns.any((column) => column['name'] == 'contaminacao');
        
        if (!hasConsumoOleoColumn) {
          await db.execute('ALTER TABLE elementos ADD COLUMN consumo_oleo TEXT');
        }
        
        if (!hasContaminacaoColumn) {
          await db.execute('ALTER TABLE elementos ADD COLUMN contaminacao TEXT');
        }
      } catch (e) {
        print('Erro ao verificar/adicionar colunas consumo_oleo e contaminacao: $e');
      }
    }

    if (!tableNames.contains('problemas')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS problemas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problema_redutor_principal TEXT,
          comentario_redutor_principal TEXT,
          lubrificante_redutor_principal TEXT,
          problema_temperatura TEXT,
          comentario_temperatura TEXT,
          problema_tambor_principal TEXT,
          comentario_tambor_principal TEXT,
          graxa_rolamentos_zonas_quentes TEXT,
          graxa_tambor_principal TEXT,
          prensa_id INTEGER,
          FOREIGN KEY (prensa_id) REFERENCES prensas (id)
        )
      ''');
    }

    if (!tableNames.contains('comentarios_elementos')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comentarios_elementos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          comentario TEXT,
          mypress_elemento_id INTEGER,
          FOREIGN KEY (mypress_elemento_id) REFERENCES elementos (id) ON DELETE CASCADE
        )
      ''');
    }

    if (!tableNames.contains('anexos_comentarios')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS anexos_comentarios(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT,
          tipo TEXT,
          url TEXT,
          base64 TEXT,
          mypress_comentario_id INTEGER,
          FOREIGN KEY (mypress_comentario_id) REFERENCES comentarios_elementos (id) ON DELETE CASCADE
        )
      ''');
    }

    if (!tableNames.contains('temperaturas_prensa')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS temperaturas_prensa(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data_registro TEXT,
          zona1 REAL,
          zona2 REAL,
          zona3 REAL,
          zona4 REAL,
          zona5 REAL,
          prensa_id INTEGER NOT NULL,
          FOREIGN KEY (prensa_id) REFERENCES prensas (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<int> createVisita(Visita visita) async {
    final db = await instance.database;
    return await db.insert('visitas', visita.toMap());
  }

  Future<List<Visita>> getAllVisitas() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('visitas');
    return List.generate(maps.length, (i) => Visita.fromMap(maps[i]));
  }

  Future<int> createPrensa(Prensa prensa) async {
    final db = await instance.database;
    final id = await db.insert('prensas', prensa.toMap());
    return id;
  }

  Future<void> updatePrensa(Prensa prensa) async {
    final db = await instance.database;
    await db.update(
      'prensas',
      prensa.toMap(),
      where: 'id = ?',
      whereArgs: [prensa.id],
    );
  }

  Future<List<Prensa>> getPrensasByVisita(int visitaId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prensas',
      where: 'visita_id = ?',
      whereArgs: [visitaId],
    );
    return List.generate(maps.length, (i) => Prensa.fromMap(maps[i]));
  }

  Future<int> createElemento(Elemento elemento) async {
    final db = await instance.database;
    return await db.insert('elementos', elemento.toMap());
  }

  Future<void> criarElementosPadrao(int prensaId) async {
    final db = await instance.database;
    
    // Primeiro, buscar a prensa para verificar o fabricante
    final prensasResult = await db.query(
      'prensas',
      where: 'id = ?',
      whereArgs: [prensaId],
    );
    
    if (prensasResult.isEmpty) {
      throw Exception('Prensa não encontrada');
    }
    
    final prensa = prensasResult.first;
    final fabricante = prensa['fabricante'] as String;
    
    // Verificar se já existem elementos padrão para esta prensa
    final existingElements = await db.query(
      'elementos',
      where: 'prensa_id = ?',
      whereArgs: [prensaId],
    );
    
    // Se já existem elementos padrão, lançar exceção informativa
    if (existingElements.isNotEmpty) {
      throw Exception('Elementos padrão já existem para esta prensa');
    }
    
    // Se for Dieffenbacher, criar todos os elementos padrão
    if (fabricante == 'Dieffenbacher') {
      final elementosDieffenbacher = [
        // 1. Cinta Superior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Superior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
        // 2. Cinta Inferior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Inferior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
        // 3. Corrente Superior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Superior',
          tipo: 'Corrente',
          prensaId: prensaId,
        ),
        // 4. Corrente Inferior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Inferior',
          tipo: 'Corrente',
          prensaId: prensaId,
        ),
        // 5. Bend rods
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'N/A',
          tipo: 'Bend rods',
          prensaId: prensaId,
        ),
      ];
      
      // Inserir todos os elementos para Dieffenbacher
      for (final elemento in elementosDieffenbacher) {
        await db.insert('elementos', elemento.toMap());
      }
    } else if (fabricante == 'Siempelkamp') {
      // Para Siempelkamp, criar apenas Cinta Superior, Cinta Inferior, Corrente Superior e Corrente Inferior
      final elementosSiempelkamp = [
        // 1. Cinta Superior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Superior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
        // 2. Cinta Inferior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Inferior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
        // 3. Corrente Superior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Superior',
          tipo: 'Corrente',
          prensaId: prensaId,
        ),
        // 4. Corrente Inferior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Inferior',
          tipo: 'Corrente',
          prensaId: prensaId,
        ),
      ];
      
      // Inserir os 4 elementos para Siempelkamp
      for (final elemento in elementosSiempelkamp) {
        await db.insert('elementos', elemento.toMap());
      }
    } else if (fabricante == 'Kusters') {
      // Para Kusters, criar apenas Cinta Superior e Cinta Inferior
      final elementosKusters = [
        // 1. Cinta Superior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Superior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
        // 2. Cinta Inferior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Inferior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
      ];
      
      // Inserir apenas os dois elementos para Kusters
      for (final elemento in elementosKusters) {
        await db.insert('elementos', elemento.toMap());
      }
    } else {
      // Para outros fabricantes, criar elementos na ordem específica
      final elementosPadrao = [
        // 1. Cinta Superior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Superior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
        // 2. Cinta Inferior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Inferior',
          tipo: 'Cinta metálica',
          prensaId: prensaId,
        ),
        // 3. Corrente Superior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Superior',
          tipo: 'Corrente',
          prensaId: prensaId,
        ),
        // 4. Corrente Inferior
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'Inferior',
          tipo: 'Corrente',
          prensaId: prensaId,
        ),
        // 5. Bend rods
        Elemento(
          consumo1: 1.0,
          consumo2: 1.0,
          consumo3: 1.0,
          toma: '2.0',
          posicao: 'N/A', // Bend rods não tem posição
          tipo: 'Bend rods',
          prensaId: prensaId,
        ),
      ];
      
      // Inserir todos os elementos padrão na ordem
      for (final elemento in elementosPadrao) {
        await db.insert('elementos', elemento.toMap());
      }
    }
  }

  Future<List<Elemento>> getElementsByPrensa(int prensaId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'elementos',
      where: 'prensa_id = ?',
      whereArgs: [prensaId],
      orderBy: 'id ASC', // Garantir ordem de criação
    );
    return List.generate(maps.length, (i) => Elemento.fromMap(maps[i]));
  }

  Future<int> createProblema(Problema problema) async {
    final db = await instance.database;
    return await db.insert('problemas', problema.toMap());
  }

  Future<List<Problema>> getProblemasByVisita(int visitaId) async {
    final db = await instance.database;
    print('Buscando problemas para a visita $visitaId');
    final List<Map<String, dynamic>> maps = await db.query(
      'problemas',
      where: 'visita_id = ?',
      whereArgs: [visitaId],
    );
    print('Problemas encontrados: $maps');
    return List.generate(maps.length, (i) => Problema.fromMap(maps[i]));
  }

  Future<List<Problema>> getProblemasByPrensa(int prensaId) async {
    final db = await instance.database;
    print('Buscando problemas para a prensa $prensaId');
    final List<Map<String, dynamic>> maps = await db.query(
      'problemas',
      where: 'prensa_id = ?',
      whereArgs: [prensaId],
    );
    print('Problemas encontrados: $maps');
    return List.generate(maps.length, (i) => Problema.fromMap(maps[i]));
  }

  Future<int> createComentarioElemento(ComentarioElemento comentario) async {
    final db = await instance.database;
    return await db.insert('comentarios_elementos', comentario.toMap());
  }

  Future<List<ComentarioElemento>> getComentariosByElemento(
      int elementoId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comentarios_elementos',
      where: 'mypress_elemento_id = ?',
      whereArgs: [elementoId],
    );
    return List.generate(
        maps.length, (i) => ComentarioElemento.fromMap(maps[i]));
  }

  Future<int> createAnexoComentario(AnexoComentario anexo) async {
    final db = await instance.database;
    return await db.insert('anexos_comentarios', anexo.toMap());
  }

  Future<List<AnexoComentario>> getAnexosByComentario(int comentarioId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'anexos_comentarios',
      where: 'mypress_comentario_id = ?',
      whereArgs: [comentarioId],
    );
    return List.generate(maps.length, (i) => AnexoComentario.fromMap(maps[i]));
  }

  Future<int> deleteAnexoComentario(int anexoId) async {
    final db = await instance.database;
    return await db.delete(
      'anexos_comentarios',
      where: 'id = ?',
      whereArgs: [anexoId],
    );
  }

  Future<int> updateElemento(Elemento elemento) async {
    final db = await instance.database;
    return await db.update(
      'elementos',
      elemento.toMap(),
      where: 'id = ?',
      whereArgs: [elemento.id],
    );
  }

  Future<int> deleteElemento(int elementoId) async {
    final db = await instance.database;

    try {
      // Usar transação para garantir que todas as operações sejam executadas ou nenhuma
      return await db.transaction((txn) async {
        // Primeiro, excluir os anexos dos comentários
        await txn.rawDelete('''
          DELETE FROM anexos_comentarios 
          WHERE mypress_comentario_id IN (
            SELECT id FROM comentarios_elementos 
            WHERE mypress_elemento_id = ?
          )
        ''', [elementoId]);

        // Depois, excluir os comentários
        await txn.delete(
          'comentarios_elementos',
          where: 'mypress_elemento_id = ?',
          whereArgs: [elementoId],
        );

        // Por fim, excluir o elemento
        return await txn.delete(
          'elementos',
          where: 'id = ?',
          whereArgs: [elementoId],
        );
      });
    } catch (e) {
      print('Erro ao excluir elemento: $e');
      rethrow;
    }
  }

  Future<int> createTemperaturaElemento(TemperaturaElemento temperatura) async {
    print('DatabaseHelper.createTemperaturaElemento iniciado');
    print('Dados da temperatura: ${temperatura.toMap()}');
    final db = await instance.database;
    print('Banco de dados obtido');
    try {
      final id = await db.insert('temperaturas_elementos', temperatura.toMap());
      print('Temperatura inserida com sucesso. ID: $id');
      return id;
    } catch (e) {
      print('Erro ao inserir temperatura: $e');
      rethrow;
    }
  }

  Future<List<TemperaturaElemento>> getTemperaturasByElemento(
      int elementoId) async {
    final db = await instance.database;
    print('Buscando temperaturas para o elemento $elementoId');
    final List<Map<String, dynamic>> maps = await db.query(
      'temperaturas_elementos',
      where: 'elemento_id = ?',
      whereArgs: [elementoId],
      orderBy: 'data_registro DESC',
    );
    print('Temperaturas encontradas: $maps');
    return List.generate(
        maps.length, (i) => TemperaturaElemento.fromMap(maps[i]));
  }

  Future<int> deleteTemperaturaElemento(int temperaturaId) async {
    final db = await instance.database;
    return await db.delete(
      'temperaturas_elementos',
      where: 'id = ?',
      whereArgs: [temperaturaId],
    );
  }

  Future<int> updateTemperaturaElemento(TemperaturaElemento temperatura) async {
    final db = await instance.database;
    return await db.update(
      'temperaturas_elementos',
      temperatura.toMap(),
      where: 'id = ?',
      whereArgs: [temperatura.id],
    );
  }

  Future<int> updateProblema(Problema problema) async {
    final db = await instance.database;
    return await db.update(
      'problemas',
      problema.toMap(),
      where: 'id = ?',
      whereArgs: [problema.id],
    );
  }

  Future<List<Visita>> getVisitasNaoEnviadas() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visitas',
      where: 'enviado = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Visita.fromMap(maps[i]));
  }

  Future<void> marcarVisitaComoEnviada(int visitaId) async {
    final db = await instance.database;
    await db.update(
      'visitas',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [visitaId],
    );
  }

  Future<Visita> getVisita(int visitaId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visitas',
      where: 'id = ?',
      whereArgs: [visitaId],
    );

    if (maps.isEmpty) {
      throw Exception('Visita não encontrada');
    }

    return Visita.fromMap(maps.first);
  }

  Future<int> deleteVisita(int visitaId) async {
    final db = await instance.database;
    
    // Primeiro, buscar todas as prensas relacionadas à visita
    final prensas = await getPrensasByVisita(visitaId);
    
    // Para cada prensa, excluir elementos, temperaturas e problemas relacionados
    for (var prensa in prensas) {
      // Excluir temperaturas da prensa
      await db.delete(
        'temperaturas_prensa',
        where: 'prensa_id = ?',
        whereArgs: [prensa.id],
      );
      
      // Excluir problemas da prensa
      await db.delete(
        'problemas',
        where: 'prensa_id = ?',
        whereArgs: [prensa.id],
      );
      
      // Buscar elementos da prensa
      final elementos = await getElementsByPrensa(prensa.id!);
      
      // Para cada elemento, excluir comentários e anexos
      for (var elemento in elementos) {
        // Buscar comentários do elemento
        final comentarios = await getComentariosByElemento(elemento.id!);
        
        // Para cada comentário, excluir anexos
        for (var comentario in comentarios) {
          await db.delete(
            'anexos_comentarios',
            where: 'mypress_comentario_id = ?',
            whereArgs: [comentario.id],
          );
        }
        
        // Excluir comentários do elemento
        await db.delete(
          'comentarios_elementos',
          where: 'mypress_elemento_id = ?',
          whereArgs: [elemento.id],
        );
        
        // Excluir temperaturas do elemento
        await db.delete(
          'temperaturas_elementos',
          where: 'elemento_id = ?',
          whereArgs: [elemento.id],
        );
      }
      
      // Excluir elementos da prensa
      await db.delete(
        'elementos',
        where: 'prensa_id = ?',
        whereArgs: [prensa.id],
      );
    }
    
    // Excluir prensas da visita
    await db.delete(
      'prensas',
      where: 'visita_id = ?',
      whereArgs: [visitaId],
    );
    
    // Finalmente, excluir a visita
    return await db.delete(
      'visitas',
      where: 'id = ?',
      whereArgs: [visitaId],
    );
  }

  Future<int> createTemperaturaPrensa(TemperaturaPrensa temperatura) async {
    print('DatabaseHelper.createTemperaturaPrensa iniciado');
    print('Dados da temperatura: ${temperatura.toMap()}');
    final db = await instance.database;
    print('Banco de dados obtido');
    try {
      final id = await db.insert('temperaturas_prensa', temperatura.toMap());
      print('Temperatura inserida com sucesso. ID: $id');
      return id;
    } catch (e) {
      print('Erro ao inserir temperatura: $e');
      rethrow;
    }
  }

  Future<List<TemperaturaPrensa>> getTemperaturasByPrensa(int prensaId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'temperaturas_prensa',
      where: 'prensa_id = ?',
      whereArgs: [prensaId],
      orderBy: 'data_registro DESC',
    );
    return List.generate(maps.length, (i) => TemperaturaPrensa.fromMap(maps[i]));
  }

  Future<int> deleteTemperaturaPrensa(int temperaturaId) async {
    final db = await instance.database;
    return await db.delete(
      'temperaturas_prensa',
      where: 'id = ?',
      whereArgs: [temperaturaId],
    );
  }

  Future<int> updateTemperaturaPrensa(TemperaturaPrensa temperatura) async {
    final db = await instance.database;
    return await db.update(
      'temperaturas_prensa',
      temperatura.toMap(),
      where: 'id = ?',
      whereArgs: [temperatura.id],
    );
  }

  Future<List<Prensa>> getAllPrensas() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('prensas');
    return List.generate(maps.length, (i) => Prensa.fromMap(maps[i]));
  }

  Future<int> deletePrensa(int prensaId) async {
    final db = await instance.database;
    
    try {
      // Usar transação para garantir que todas as operações sejam executadas ou nenhuma
      return await db.transaction((txn) async {
        // Primeiro, excluir as temperaturas da prensa
        await txn.delete(
          'temperaturas_prensa',
          where: 'prensa_id = ?',
          whereArgs: [prensaId],
        );

        // Depois, excluir os elementos da prensa
        await txn.delete(
          'elementos',
          where: 'prensa_id = ?',
          whereArgs: [prensaId],
        );

        // Por fim, excluir a prensa
        return await txn.delete(
          'prensas',
          where: 'id = ?',
          whereArgs: [prensaId],
        );
      });
    } catch (e) {
      print('Erro ao excluir prensa: $e');
      rethrow;
    }
  }

  Future<int> deleteProblema(int id) async {
    final db = await instance.database;
    return await db.delete(
      'problemas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
