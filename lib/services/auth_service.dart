import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../database/database_helper.dart';
import '../models/usuario.dart';
import '../utils/security_utils.dart';
import 'service_exceptions.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirebaseContextService _ctx;

  AuthService(this._ctx);

  User? get firebaseUser => _auth.currentUser;

  Future<Usuario?> signIn(String email, String password) async {
    final cleanEmail = SecurityUtils.sanitizeEmail(email);
    if (!SecurityUtils.isValidEmail(cleanEmail)) {
      throw const ValidationException('E-mail inválido.');
    }

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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = SecurityUtils.sanitizeEmail(email);
    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      throw ServiceException(_mapAuthError(e.code));
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (!SecurityUtils.isStrongPassword(newPassword)) {
      throw const ValidationException(
        'Senha fraca. Use 8+ chars com maiúscula, minúscula, número e símbolo.',
      );
    }
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw ServiceException(_mapAuthError(e.code));
    }
  }

  // Creates a new barbeiro without signing out the current admin
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

    // Use secondary app to avoid signing out admin
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

      // Save to Firestore
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

      // Save to SQLite
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
      });

      return uid;
    } finally {
      await secondaryApp?.delete();
    }
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
      throw const ValidationException('Senha fraca.');
    }

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
      });

      return uid;
    } on FirebaseAuthException catch (e) {
      throw ServiceException(_mapAuthError(e.code));
    }
  }

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

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
