import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/usuario.dart';
import '../utils/security_utils.dart';
import 'service_exceptions.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirebaseContextService _ctx;

  AuthService(this._ctx);

  static const _maxBarbeiros = 5;
  static const _pwSalt = 'barberos_local_v1';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool get _firebaseAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _hashPassword(String pw) {
    final bytes = utf8.encode('$pw$_pwSalt');
    return sha256.convert(bytes).toString();
  }

  Future<void> _enforceEmployeeLimit(String barbeariaId) async {
    final rows = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM usuarios WHERE barbearia_id = ? AND role = 'barbeiro' AND ativo = 1",
      [barbeariaId],
    );
    final n = (rows.first['c'] as int?) ?? 0;
    if (n >= _maxBarbeiros) {
      throw const ValidationException('Limite de $_maxBarbeiros barbeiros atingido. Desative um para adicionar outro.');
    }
  }

  User? get firebaseUser => _firebaseAvailable ? _auth.currentUser : null;

  Future<Usuario?> signIn(String email, String password) async {
    final cleanEmail = SecurityUtils.sanitizeEmail(email);
    if (!SecurityUtils.isValidEmail(cleanEmail)) {
      throw const ValidationException('E-mail inválido.');
    }

    if (_firebaseAvailable) {
      try {
        final cred = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        return _getUserRecord(cred.user!.uid);
      } on FirebaseAuthException catch (e) {
        throw ServiceException(_mapAuthError(e.code));
      }
    }

    return _localSignIn(cleanEmail, password);
  }

  Future<Usuario?> _localSignIn(String email, String password) async {
    final hash = _hashPassword(password);
    final rows = await _db.query(
      'usuarios',
      where: 'email = ? AND senha_hash = ? AND ativo = 1 AND revoked = 0',
      whereArgs: [email, hash],
    );
    if (rows.isEmpty) throw const ServiceException('E-mail ou senha incorretos.');
    return Usuario.fromMap(rows.first);
  }

  Future<void> signOut() async {
    if (_firebaseAvailable) await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_firebaseAvailable) {
      throw const ServiceException('Redefinição de senha por e-mail requer conexão com Firebase.');
    }
    final cleanEmail = SecurityUtils.sanitizeEmail(email);
    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      throw ServiceException(_mapAuthError(e.code));
    }
  }

  Future<void> changePassword(String newPassword, {int? localUserId}) async {
    if (!SecurityUtils.isStrongPassword(newPassword)) {
      throw const ValidationException(
        'Senha fraca. Use 8+ chars com maiúscula, minúscula, número e símbolo.',
      );
    }
    if (_firebaseAvailable) {
      try {
        await _auth.currentUser?.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        throw ServiceException(_mapAuthError(e.code));
      }
    } else {
      if (localUserId == null) {
        throw const ServiceException('Não foi possível alterar a senha.');
      }
      await _db.update('usuarios', {'senha_hash': _hashPassword(newPassword)}, localUserId);
    }
  }

  Future<String> createBarbeiro({
    required String email,
    required String password,
    required String nome,
    required double comissaoPercentual,
    required String barbeariaId,
  }) async {
    final cleanEmail = SecurityUtils.sanitizeEmail(email);
    if (!SecurityUtils.isValidEmail(cleanEmail)) {
      throw const ValidationException('E-mail inválido.');
    }
    if (!SecurityUtils.isStrongPassword(password)) {
      throw const ValidationException('Senha fraca.');
    }

    await _enforceEmployeeLimit(barbeariaId);

    if (_firebaseAvailable) {
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = await Firebase.initializeApp(
          name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );

        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        final uid = cred.user!.uid;

        await FirebaseErrorHandler.wrapSilent(() async {
          final col = await _ctx.col('usuarios');
          await col.doc(uid).set({
            'firebase_uid': uid,
            'nome': SecurityUtils.sanitizeName(nome),
            'email': cleanEmail,
            'role': 'barbeiro',
            'comissao_percentual': comissaoPercentual,
            'ativo': true,
            'revoked': false,
            'barbearia_id': barbeariaId,
            'firebase_id': uid,
          });
        }, context: 'createBarbeiro.firestore');

        await _db.insert('usuarios', {
          'firebase_uid': uid,
          'nome': SecurityUtils.sanitizeName(nome),
          'email': cleanEmail,
          'role': 'barbeiro',
          'comissao_percentual': comissaoPercentual,
          'ativo': 1,
          'revoked': 0,
          'barbearia_id': barbeariaId,
          'firebase_id': uid,
          'senha_hash': _hashPassword(password),
        });

        return uid;
      } finally {
        await secondaryApp?.delete();
      }
    }

    // Local-only creation
    final uid = const Uuid().v4();
    await _db.insert('usuarios', {
      'firebase_uid': uid,
      'nome': SecurityUtils.sanitizeName(nome),
      'email': cleanEmail,
      'role': 'barbeiro',
      'comissao_percentual': comissaoPercentual,
      'ativo': 1,
      'revoked': 0,
      'barbearia_id': barbeariaId,
      'firebase_id': null,
      'senha_hash': _hashPassword(password),
    });
    return uid;
  }

  Future<String> bootstrapAdmin({
    required String email,
    required String password,
    required String nome,
    required String barbeariaId,
  }) async {
    final hasAdmin = await hasAnyAdmin(barbeariaId);
    if (hasAdmin) {
      throw const ConflictException('Já existe um admin cadastrado.');
    }

    final cleanEmail = SecurityUtils.sanitizeEmail(email);
    if (!SecurityUtils.isValidEmail(cleanEmail)) {
      throw const ValidationException('E-mail inválido.');
    }
    if (!SecurityUtils.isStrongPassword(password)) {
      throw const ValidationException(
        'Senha fraca. Use 8+ chars com maiúscula, minúscula, número e símbolo.',
      );
    }

    if (_firebaseAvailable) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final uid = cred.user!.uid;

        await FirebaseErrorHandler.wrapSilent(() async {
          final col = await _ctx.col('usuarios');
          await col.doc(uid).set({
            'firebase_uid': uid,
            'nome': SecurityUtils.sanitizeName(nome),
            'email': cleanEmail,
            'role': 'admin',
            'comissao_percentual': 0.0,
            'ativo': true,
            'revoked': false,
            'barbearia_id': barbeariaId,
            'firebase_id': uid,
          });
        }, context: 'bootstrapAdmin.firestore');

        await _db.insert('usuarios', {
          'firebase_uid': uid,
          'nome': SecurityUtils.sanitizeName(nome),
          'email': cleanEmail,
          'role': 'admin',
          'comissao_percentual': 0.0,
          'ativo': 1,
          'revoked': 0,
          'barbearia_id': barbeariaId,
          'firebase_id': uid,
          'senha_hash': _hashPassword(password),
        });

        return uid;
      } on FirebaseAuthException catch (e) {
        throw ServiceException(_mapAuthError(e.code));
      }
    }

    // Local-only creation
    final uid = const Uuid().v4();
    await _db.insert('usuarios', {
      'firebase_uid': uid,
      'nome': SecurityUtils.sanitizeName(nome),
      'email': cleanEmail,
      'role': 'admin',
      'comissao_percentual': 0.0,
      'ativo': 1,
      'revoked': 0,
      'barbearia_id': barbeariaId,
      'firebase_id': null,
      'senha_hash': _hashPassword(password),
    });
    return uid;
  }

  Future<Usuario?> _getUserRecord(String uid) async {
    final rows = await _db.query(
      'usuarios',
      where: 'firebase_uid = ?',
      whereArgs: [uid],
    );
    if (rows.isEmpty) return null;
    return Usuario.fromMap(rows.first);
  }

  Future<bool> hasAnyAdmin(String barbeariaId) async {
    final rows = await _db.query(
      'usuarios',
      where: "role = 'admin' AND barbearia_id = ? AND ativo = 1",
      whereArgs: [barbeariaId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Stream<User?> get authStateChanges =>
      _firebaseAvailable ? _auth.authStateChanges() : const Stream.empty();

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'E-mail já cadastrado.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro de autenticação: $code';
    }
  }
}
