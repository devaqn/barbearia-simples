import 'package:flutter_test/flutter_test.dart';
import 'package:barberos/models/item_comanda.dart';

void main() {
  group('ItemComanda computed properties', () {
    test('subtotal = precoUnitario * quantidade', () {
      const item = ItemComanda(
        comandaId: 1,
        tipo: 'servico',
        referenciaId: 1,
        descricao: 'Corte',
        precoUnitario: 35.0,
        quantidade: 2,
        comissaoPercentual: 50.0,
      );
      expect(item.subtotal, equals(70.0));
    });

    test('comissaoValor = subtotal * percentual / 100', () {
      const item = ItemComanda(
        comandaId: 1,
        tipo: 'servico',
        referenciaId: 1,
        descricao: 'Corte',
        precoUnitario: 35.0,
        quantidade: 1,
        comissaoPercentual: 50.0,
      );
      expect(item.comissaoValor, equals(17.5));
    });

    test('lucroCasa = subtotal - comissaoValor', () {
      const item = ItemComanda(
        comandaId: 1,
        tipo: 'servico',
        referenciaId: 1,
        descricao: 'Corte',
        precoUnitario: 100.0,
        quantidade: 1,
        comissaoPercentual: 30.0,
      );
      expect(item.lucroCasa, closeTo(70.0, 0.001));
    });

    test('toMap / fromMap roundtrip', () {
      const item = ItemComanda(
        comandaId: 5,
        tipo: 'produto',
        referenciaId: 10,
        descricao: 'Shampoo',
        precoUnitario: 25.0,
        quantidade: 3,
        comissaoPercentual: 10.0,
      );
      final map = item.toMap();
      final restored = ItemComanda.fromMap(map);
      expect(restored.descricao, equals(item.descricao));
      expect(restored.precoUnitario, equals(item.precoUnitario));
      expect(restored.quantidade, equals(item.quantidade));
    });
  });
}
