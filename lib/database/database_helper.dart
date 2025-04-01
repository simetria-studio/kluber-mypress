import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/visita_model.dart';
import '../models/prensa_model.dart';
import '../models/elemento_model.dart';
import '../models/problema_model.dart';
import '../models/comentario_elemento_model.dart';
import '../models/anexo_comentario_model.dart';
import '../models/temperatura_elemento_model.dart';

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
      version: 1,
      onCreate: _createDB,
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_visita TEXT NOT NULL,
        cliente TEXT NOT NULL,
        contato_cliente TEXT NOT NULL,
        contato_kluber TEXT NOT NULL,
        enviado INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prensas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_prensa TEXT NOT NULL,
        fabricante TEXT NOT NULL,
        comprimento REAL NOT NULL,
        espessura REAL NOT NULL,
        produto TEXT NOT NULL,
        velocidade REAL NOT NULL,
        produto_cinta TEXT NOT NULL,
        produto_corrente TEXT NOT NULL,
        produto_bendroads TEXT NOT NULL,
        visita_id INTEGER NOT NULL,
        FOREIGN KEY (visita_id) REFERENCES visitas (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS elementos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consumo1 REAL NOT NULL,
        consumo2 REAL NOT NULL,
        consumo3 REAL NOT NULL,
        toma TEXT NOT NULL,
        posicao TEXT NOT NULL,
        tipo TEXT NOT NULL,
        mypress TEXT NOT NULL,
        prensa_id INTEGER NOT NULL,
        FOREIGN KEY (prensa_id) REFERENCES prensas (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS problemas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        problema_redutor_principal INTEGER NOT NULL,
        comentario_redutor_principal TEXT,
        lubrificante_redutor_principal TEXT,
        problema_temperatura INTEGER NOT NULL,
        comentario_temperatura TEXT,
        problema_tambor_principal INTEGER NOT NULL,
        comentario_tambor_principal TEXT,
        mypress_visita_id INTEGER NOT NULL,
        graxa_rolamentos_zonas_quentes TEXT,
        graxa_tambor_principal TEXT,
        FOREIGN KEY (mypress_visita_id) REFERENCES visitas (id)
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
          data_visita TEXT NOT NULL,
          cliente TEXT NOT NULL,
          contato_cliente TEXT NOT NULL,
          contato_kluber TEXT NOT NULL,
          enviado INTEGER DEFAULT 0
        )
      ''');
    }

    if (!tableNames.contains('prensas')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prensas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo_prensa TEXT NOT NULL,
          fabricante TEXT NOT NULL,
          comprimento REAL NOT NULL,
          espessura REAL NOT NULL,
          produto TEXT NOT NULL,
          velocidade REAL NOT NULL,
          produto_cinta TEXT NOT NULL,
          produto_corrente TEXT NOT NULL,
          produto_bendroads TEXT NOT NULL,
          visita_id INTEGER NOT NULL,
          FOREIGN KEY (visita_id) REFERENCES visitas (id)
        )
      ''');
    }

    if (!tableNames.contains('elementos')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS elementos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          consumo1 REAL NOT NULL,
          consumo2 REAL NOT NULL,
          consumo3 REAL NOT NULL,
          toma TEXT NOT NULL,
          posicao TEXT NOT NULL,
          tipo TEXT NOT NULL,
          mypress TEXT NOT NULL,
          prensa_id INTEGER NOT NULL,
          FOREIGN KEY (prensa_id) REFERENCES prensas (id) ON DELETE CASCADE
        )
      ''');
    }

    if (!tableNames.contains('problemas')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS problemas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problema_redutor_principal INTEGER NOT NULL,
          comentario_redutor_principal TEXT,
          lubrificante_redutor_principal TEXT,
          problema_temperatura INTEGER NOT NULL,
          comentario_temperatura TEXT,
          problema_tambor_principal INTEGER NOT NULL,
          comentario_tambor_principal TEXT,
          mypress_visita_id INTEGER NOT NULL,
          graxa_rolamentos_zonas_quentes TEXT,
          graxa_tambor_principal TEXT,
          FOREIGN KEY (mypress_visita_id) REFERENCES visitas (id)
        )
      ''');
    }

    if (!tableNames.contains('comentarios_elementos')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comentarios_elementos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          comentario TEXT NOT NULL,
          mypress_elemento_id INTEGER NOT NULL,
          FOREIGN KEY (mypress_elemento_id) REFERENCES elementos (id) ON DELETE CASCADE
        )
      ''');
    }

    if (!tableNames.contains('anexos_comentarios')) {
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
    }

    if (!tableNames.contains('temperaturas_elementos')) {
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

  Future<List<Elemento>> getElementsByPrensa(int prensaId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'elementos',
      where: 'prensa_id = ?',
      whereArgs: [prensaId],
    );
    return List.generate(maps.length, (i) => Elemento.fromMap(maps[i]));
  }

  Future<int> createProblema(Problema problema) async {
    final db = await instance.database;
    return await db.insert('problemas', problema.toMap());
  }

  Future<List<Problema>> getProblemasByVisita(int visitaId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'problemas',
      where: 'mypress_visita_id = ?',
      whereArgs: [visitaId],
    );
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
    final db = await instance.database;
    return await db.insert('temperaturas_elementos', temperatura.toMap());
  }

  Future<List<TemperaturaElemento>> getTemperaturasByElemento(
      int elementoId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'temperaturas_elementos',
      where: 'elemento_id = ?',
      whereArgs: [elementoId],
      orderBy: 'data_registro DESC',
    );
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
}
