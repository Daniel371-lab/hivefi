import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _categorias =>
      _db.collection('users').doc(_uid).collection('categorias');

  CollectionReference get _movimientos =>
      _db.collection('users').doc(_uid).collection('movimientos');

  // ─── CATEGORÍAS ────────────────────────────────────────────────────────────

  Future<void> crearCategoria({
    required String nombre,
    required String tipo,
    double meta = 0,
  }) async {
    await _categorias.add({
      'nombre': nombre.toUpperCase().trim(),
      'tipo': tipo,
      'disponible': 0.0,
      'meta': meta,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getCategoriasPorTipo(String tipo) {
    return _categorias
        .where('tipo', isEqualTo: tipo)
        .orderBy('creadoEn')
        .snapshots();
  }

  Stream<QuerySnapshot> getTodasLasCategorias() {
    return _categorias.orderBy('creadoEn').snapshots();
  }

  Stream<QuerySnapshot> getMovimientosPorCategoria({
    required String categoriaId,
    required String tipo,
  }) {
    return _movimientos
        .where('categoriaOrigenId', isEqualTo: categoriaId)
        .where('tipo', isEqualTo: tipo)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<void> eliminarCategoria(String categoriaId, double disponible) async {
    final batch = _db.batch();
    batch.delete(_categorias.doc(categoriaId));
    await batch.commit();
  }

  Future<void> editarCategoria({
    required String categoriaId,
    required String nuevoNombre,
  }) async {
    await _categorias.doc(categoriaId).update({
      'nombre': nuevoNombre.toUpperCase().trim(),
    });
  }

  // ─── MOVIMIENTOS ───────────────────────────────────────────────────────────

  Future<void> registrarIngreso({
    required String categoriaId,
    required String categoriaNombre,
    required double monto,
  }) async {
    final batch = _db.batch();
    batch.update(_categorias.doc(categoriaId), {
      'disponible': FieldValue.increment(monto),
    });
    batch.set(_movimientos.doc(), {
      'tipo': 'ingreso',
      'categoriaOrigenId': categoriaId,
      'categoriaOrigenNombre': categoriaNombre,
      'categoriaDestinoId': null,
      'categoriaDestinoNombre': null,
      'monto': monto,
      'descripcion': 'Carga a $categoriaNombre',
      'fecha': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> registrarGasto({
    required String categoriaId,
    required String categoriaNombre,
    required double monto,
  }) async {
    final batch = _db.batch();
    batch.update(_categorias.doc(categoriaId), {
      'disponible': FieldValue.increment(-monto),
    });
    batch.set(_movimientos.doc(), {
      'tipo': 'gasto',
      'categoriaOrigenId': categoriaId,
      'categoriaOrigenNombre': categoriaNombre,
      'categoriaDestinoId': null,
      'categoriaDestinoNombre': null,
      'monto': -monto,
      'descripcion': 'Gasto en $categoriaNombre',
      'fecha': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> editarGasto({
    required String movimientoId,
    required String categoriaId,
    required double montoAnterior,
    required double montoNuevo,
  }) async {
    final batch = _db.batch();
    final diferencia = montoNuevo - montoAnterior;
    batch.update(_categorias.doc(categoriaId), {
      'disponible': FieldValue.increment(-diferencia),
    });
    batch.update(_movimientos.doc(movimientoId), {
      'monto': -montoNuevo,
      'descripcion': 'Gasto en $categoriaId',
    });
    await batch.commit();
  }

  Future<void> eliminarGasto({
    required String movimientoId,
    required String categoriaId,
    required double monto,
  }) async {
    final batch = _db.batch();
    batch.update(_categorias.doc(categoriaId), {
      'disponible': FieldValue.increment(monto),
    });
    batch.delete(_movimientos.doc(movimientoId));
    await batch.commit();
  }

  Future<void> destinarDinero({
    required String origenId,
    required String origenNombre,
    required String destinoId,
    required String destinoNombre,
    required double monto,
  }) async {
    final batch = _db.batch();
    batch.update(_categorias.doc(origenId), {
      'disponible': FieldValue.increment(-monto),
    });
    batch.update(_categorias.doc(destinoId), {
      'disponible': FieldValue.increment(monto),
    });
    batch.set(_movimientos.doc(), {
      'tipo': 'destinar',
      'categoriaOrigenId': origenId,
      'categoriaOrigenNombre': origenNombre,
      'categoriaDestinoId': destinoId,
      'categoriaDestinoNombre': destinoNombre,
      'monto': -monto,
      'descripcion': 'Destino: $origenNombre → $destinoNombre',
      'fecha': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> repartirDinero({
    required String origenId,
    required String origenNombre,
    required String destinoId,
    required String destinoNombre,
    required double monto,
  }) async {
    final batch = _db.batch();
    batch.update(_categorias.doc(origenId), {
      'disponible': FieldValue.increment(-monto),
    });
    batch.update(_categorias.doc(destinoId), {
      'disponible': FieldValue.increment(monto),
    });
    batch.set(_movimientos.doc(), {
      'tipo': 'reparto',
      'categoriaOrigenId': origenId,
      'categoriaOrigenNombre': origenNombre,
      'categoriaDestinoId': destinoId,
      'categoriaDestinoNombre': destinoNombre,
      'monto': -monto,
      'descripcion': 'Reparto: $origenNombre → $destinoNombre',
      'fecha': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<QuerySnapshot> getMovimientos() {
    return _movimientos
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<void> eliminarMovimiento(String movimientoId) async {
    await _movimientos.doc(movimientoId).delete();
  }

  // ─── BALANCE ───────────────────────────────────────────────────────────────

  Stream<Map<String, double>> getBalance() {
    return _categorias.snapshots().map((snapshot) {
      double totalIngresado = 0;
      double totalDestinadoGastos = 0;
      double totalAhorros = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final disponible = (data['disponible'] as num).toDouble();
        final tipo = data['tipo'] as String;

        if (tipo == 'ingreso') totalIngresado += disponible;
        if (tipo == 'gasto') totalDestinadoGastos += disponible;
        if (tipo == 'ahorro') totalAhorros += disponible;
      }

      final balanceGeneral = totalIngresado + totalDestinadoGastos + totalAhorros;
      final balanceDisponible = totalIngresado + totalDestinadoGastos;

      final progresoGeneral = balanceGeneral > 0
          ? (balanceDisponible / balanceGeneral).clamp(0.0, 1.0)
          : 0.0;

      final progresoDisponible = balanceDisponible > 0
          ? (totalDestinadoGastos / balanceDisponible).clamp(0.0, 1.0)
          : 0.0;

      return {
        'balanceGeneral': balanceGeneral,
        'balanceDisponible': balanceDisponible,
        'progresoGeneral': progresoGeneral,
        'progresoDisponible': progresoDisponible,
      };
    });
  }
}