import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import '../utils/app_config.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final path = await getDatabasesPath();
      return openDatabase(
        '$path/${AppConstants.dbName}',
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
        },
      );
    }

    // Android / iOS: use SQLCipher with a key derived from LICENSE_HASH
    final encryptionKey = AppConfig.licenseHash.isNotEmpty
        ? AppConfig.licenseHash.substring(0, 16)
        : 'barberos_default';

    final path = await sqlcipher.getDatabasesPath();
    return sqlcipher.openDatabase(
      '$path/${AppConstants.dbName}',
      password: encryptionKey,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _createSchema(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('PRAGMA foreign_keys = ON');
    if (oldVersion < 2) {
      await addColumnIfMissing(db, 'usuarios', 'senha_hash', 'TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS avaliacoes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
          barbeiro_id INTEGER NOT NULL REFERENCES usuarios(id),
          agendamento_id INTEGER REFERENCES agendamentos(id) ON DELETE SET NULL,
          nota INTEGER NOT NULL,
          comentario TEXT,
          barbearia_id TEXT NOT NULL,
          firebase_id TEXT UNIQUE,
          criado_em TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_avaliacoes_barbearia ON avaliacoes(barbearia_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_avaliacoes_barbeiro ON avaliacoes(barbeiro_id)');
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT UNIQUE,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'barbeiro',
        comissao_percentual REAL NOT NULL DEFAULT 50.0,
        foto_url TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        revoked INTEGER NOT NULL DEFAULT 0,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE,
        senha_hash TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT NOT NULL,
        email TEXT,
        data_nascimento TEXT,
        total_atendimentos INTEGER NOT NULL DEFAULT 0,
        total_gasto REAL NOT NULL DEFAULT 0.0,
        pontos_fidelidade INTEGER NOT NULL DEFAULT 0,
        is_assinante INTEGER NOT NULL DEFAULT 0,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE,
        criado_em TEXT NOT NULL DEFAULT (datetime('now')),
        atualizado_em TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS servicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        preco REAL NOT NULL,
        duracao_minutos INTEGER NOT NULL DEFAULT 30,
        comissao_percentual REAL NOT NULL DEFAULT 50.0,
        ativo INTEGER NOT NULL DEFAULT 1,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fornecedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT,
        email TEXT,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        preco_venda REAL NOT NULL,
        preco_custo REAL NOT NULL DEFAULT 0.0,
        custo_medio REAL NOT NULL DEFAULT 0.0,
        quantidade INTEGER NOT NULL DEFAULT 0,
        estoque_minimo INTEGER NOT NULL DEFAULT 5,
        comissao_percentual REAL NOT NULL DEFAULT 0.0,
        fornecedor_id INTEGER REFERENCES fornecedores(id) ON DELETE SET NULL,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS atendimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
        barbeiro_id INTEGER NOT NULL REFERENCES usuarios(id),
        data_hora TEXT NOT NULL,
        total REAL NOT NULL DEFAULT 0.0,
        forma_pagamento TEXT NOT NULL,
        observacoes TEXT,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS atendimento_itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        atendimento_id INTEGER NOT NULL REFERENCES atendimentos(id) ON DELETE CASCADE,
        tipo TEXT NOT NULL,
        referencia_id INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        preco_unitario REAL NOT NULL,
        quantidade INTEGER NOT NULL DEFAULT 1,
        subtotal REAL NOT NULL,
        comissao_valor REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS agendamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
        barbeiro_id INTEGER NOT NULL REFERENCES usuarios(id),
        servico_id INTEGER REFERENCES servicos(id) ON DELETE SET NULL,
        data_hora_inicio TEXT NOT NULL,
        data_hora_fim TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        observacoes TEXT,
        faturado INTEGER NOT NULL DEFAULT 0,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS despesas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        categoria TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        observacoes TEXT,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS movimentos_estoque (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produto_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
        tipo TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        custo_unitario REAL NOT NULL DEFAULT 0.0,
        observacoes TEXT,
        data_hora TEXT NOT NULL,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS caixas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barbeiro_id INTEGER NOT NULL REFERENCES usuarios(id),
        data_abertura TEXT NOT NULL,
        data_fechamento TEXT,
        saldo_inicial REAL NOT NULL DEFAULT 0.0,
        saldo_final REAL,
        resumo_pagamentos_json TEXT,
        status TEXT NOT NULL DEFAULT 'aberto',
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comandas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
        barbeiro_id INTEGER NOT NULL REFERENCES usuarios(id),
        status TEXT NOT NULL DEFAULT 'aberta',
        forma_pagamento TEXT,
        total_servicos REAL NOT NULL DEFAULT 0.0,
        total_produtos REAL NOT NULL DEFAULT 0.0,
        total REAL NOT NULL DEFAULT 0.0,
        data_abertura TEXT NOT NULL,
        data_fechamento TEXT,
        observacoes TEXT,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comandas_itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comanda_id INTEGER NOT NULL REFERENCES comandas(id) ON DELETE CASCADE,
        tipo TEXT NOT NULL,
        referencia_id INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        preco_unitario REAL NOT NULL,
        quantidade INTEGER NOT NULL DEFAULT 1,
        subtotal REAL NOT NULL,
        comissao_percentual REAL NOT NULL DEFAULT 0.0,
        comissao_valor REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comissoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barbeiro_id INTEGER NOT NULL REFERENCES usuarios(id),
        comanda_id INTEGER REFERENCES comandas(id) ON DELETE SET NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        pago INTEGER NOT NULL DEFAULT 0,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS avaliacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
        barbeiro_id INTEGER NOT NULL REFERENCES usuarios(id),
        agendamento_id INTEGER REFERENCES agendamentos(id) ON DELETE SET NULL,
        nota INTEGER NOT NULL,
        comentario TEXT,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE,
        criado_em TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS assinaturas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
        plano TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ativo',
        valor REAL NOT NULL,
        data_inicio TEXT NOT NULL,
        data_vencimento TEXT NOT NULL,
        mp_subscription_id TEXT,
        mp_payer_id TEXT,
        barbearia_id TEXT NOT NULL,
        firebase_id TEXT UNIQUE
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_clientes_barbearia ON clientes(barbearia_id)',
      'CREATE INDEX IF NOT EXISTS idx_clientes_telefone ON clientes(telefone)',
      'CREATE INDEX IF NOT EXISTS idx_clientes_nome ON clientes(nome)',
      'CREATE INDEX IF NOT EXISTS idx_clientes_aniversario ON clientes(data_nascimento)',
      'CREATE INDEX IF NOT EXISTS idx_servicos_barbearia ON servicos(barbearia_id)',
      'CREATE INDEX IF NOT EXISTS idx_servicos_ativo ON servicos(ativo)',
      'CREATE INDEX IF NOT EXISTS idx_produtos_barbearia ON produtos(barbearia_id)',
      'CREATE INDEX IF NOT EXISTS idx_produtos_estoque ON produtos(quantidade, estoque_minimo)',
      'CREATE INDEX IF NOT EXISTS idx_atendimentos_barbearia_data ON atendimentos(barbearia_id, data_hora)',
      'CREATE INDEX IF NOT EXISTS idx_atendimentos_cliente ON atendimentos(cliente_id)',
      'CREATE INDEX IF NOT EXISTS idx_atendimentos_barbeiro ON atendimentos(barbeiro_id)',
      'CREATE INDEX IF NOT EXISTS idx_agendamentos_barbeiro_data ON agendamentos(barbeiro_id, data_hora_inicio)',
      'CREATE INDEX IF NOT EXISTS idx_agendamentos_barbearia ON agendamentos(barbearia_id)',
      'CREATE INDEX IF NOT EXISTS idx_despesas_barbearia_data ON despesas(barbearia_id, data)',
      'CREATE INDEX IF NOT EXISTS idx_movimentos_produto ON movimentos_estoque(produto_id)',
      'CREATE INDEX IF NOT EXISTS idx_movimentos_barbearia ON movimentos_estoque(barbearia_id)',
      'CREATE INDEX IF NOT EXISTS idx_caixas_barbeiro ON caixas(barbeiro_id, status)',
      'CREATE INDEX IF NOT EXISTS idx_comandas_barbeiro_status ON comandas(barbeiro_id, status)',
      'CREATE INDEX IF NOT EXISTS idx_comandas_barbearia ON comandas(barbearia_id)',
      'CREATE INDEX IF NOT EXISTS idx_comandas_itens_comanda ON comandas_itens(comanda_id)',
      'CREATE INDEX IF NOT EXISTS idx_comissoes_barbeiro ON comissoes(barbeiro_id, pago)',
      'CREATE INDEX IF NOT EXISTS idx_assinaturas_cliente ON assinaturas(cliente_id)',
      'CREATE INDEX IF NOT EXISTS idx_assinaturas_status ON assinaturas(status, data_vencimento)',
      'CREATE INDEX IF NOT EXISTS idx_avaliacoes_barbearia ON avaliacoes(barbearia_id)',
      'CREATE INDEX IF NOT EXISTS idx_avaliacoes_barbeiro ON avaliacoes(barbeiro_id)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_caixas_aberto_unique ON caixas(barbeiro_id) WHERE status = \'aberto\'',
    ];

    for (final sql in indexes) {
      await db.execute(sql);
    }
  }

  // Migration helper — idempotent column addition
  Future<void> addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    final exists = result.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
      if (kDebugMode) debugPrint('[DB] Added column $table.$column');
    }
  }

  // Generic CRUD

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
