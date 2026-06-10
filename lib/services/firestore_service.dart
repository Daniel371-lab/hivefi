import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'connectivity_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _categorias =>
      _db.collection('users').doc(_uid).collection('categorias');

  CollectionReference get _movimientos =>
      _db.collection('users').doc(_uid).collection('movimientos');

  Future<void> _verificarInternet() async {
    final tiene = await ConnectivityService.instance.tieneInternet();
    if (!tiene) {
      throw Exception('Sin conexión a internet. Conéctate e intenta de nuevo.');
    }
  }

  // ─── CATEGORÍAS ────────────────────────────────────────────────────────────

  Future<void> crearCategoria({
    required String nombre,
    required String tipo,
    double meta = 0,
  }) async {
    await _verificarInternet();
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

  // Este es el método estrella que alimenta tu AppProvider a costo casi cero
  Stream<QuerySnapshot> getTodasLasCategorias() {
    return _categorias.orderBy('creadoEn').snapshots();
  }

  Future<void> eliminarCategoria(String categoriaId, double disponible) async {
    await _verificarInternet();
    final batch = _db.batch();
    batch.delete(_categorias.doc(categoriaId));
    await batch.commit();
  }

  Future<void> editarCategoria({
    required String categoriaId,
    required String nuevoNombre,
  }) async {
    await _verificarInternet();
    final nombreFinal = nuevoNombre.toUpperCase().trim();

    await _categorias.doc(categoriaId).update({'nombre': nombreFinal});

    final movimientos = await _movimientos
        .where('categoriaOrigenId', isEqualTo: categoriaId)
        .get();

    final movimientosDestino = await _movimientos
        .where('categoriaDestinoId', isEqualTo: categoriaId)
        .get();

    final batch = _db.batch();
    for (final doc in movimientos.docs) {
      batch.update(doc.reference, {'categoriaOrigenNombre': nombreFinal});
    }
    for (final doc in movimientosDestino.docs) {
      batch.update(doc.reference, {'categoriaDestinoNombre': nombreFinal});
    }
    await batch.commit();
  }

  // ─── MOVIMIENTOS ───────────────────────────────────────────────────────────

  Future<void> registrarIngreso({
    required String categoriaId,
    required String categoriaNombre,
    required double monto,
  }) async {
    await _verificarInternet();
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
    await _verificarInternet();
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
    required String categoriaNombre,
    required double montoAnterior,
    required double montoNuevo,
  }) async {
    await _verificarInternet();
    final batch = _db.batch();
    final diferencia = montoNuevo - montoAnterior;
    batch.update(_categorias.doc(categoriaId), {
      'disponible': FieldValue.increment(-diferencia),
    });
    batch.update(_movimientos.doc(movimientoId), {
      'monto': -montoNuevo,
      'descripcion': 'Gasto en $categoriaNombre',
    });
    await batch.commit();
  }

  Future<void> eliminarGasto({
    required String movimientoId,
    required String categoriaId,
    required double monto,
  }) async {
    await _verificarInternet();
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
    await _verificarInternet();
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
    await _verificarInternet();
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

  Future<void> editarMontoDestinar({
    required String movimientoId,
    required String origenId,
    required String destinoId,
    required double montoAnterior,
    required double montoNuevo,
  }) async {
    await _verificarInternet();
    final diferencia = montoNuevo - montoAnterior;
    final batch = _db.batch();
    batch.update(_categorias.doc(origenId), {
      'disponible': FieldValue.increment(-diferencia),
    });
    batch.update(_categorias.doc(destinoId), {
      'disponible': FieldValue.increment(diferencia),
    });
    batch.update(_movimientos.doc(movimientoId), {
      'monto': -montoNuevo,
      'descripcion': 'Destino editado',
    });
    await batch.commit();
  }

  Future<void> editarMontoIngreso({
    required String movimientoId,
    required String categoriaId,
    required double montoAnterior,
    required double montoNuevo,
  }) async {
    await _verificarInternet();
    final diferencia = montoNuevo - montoAnterior;
    final batch = _db.batch();
    batch.update(_categorias.doc(categoriaId), {
      'disponible': FieldValue.increment(diferencia),
    });
    batch.update(_movimientos.doc(movimientoId), {
      'monto': montoNuevo,
      'descripcion': 'Carga editada',
    });
    await batch.commit();
  }

  Future<void> eliminarMovimiento(String movimientoId) async {
    await _verificarInternet();
    await _movimientos.doc(movimientoId).delete();
  }

  // ─── CONSULTAS DE MOVIMIENTOS Y FILTROS ────────────────────────────────────

  Stream<QuerySnapshot> getMovimientos() {
    return _movimientos.orderBy('fecha', descending: true).snapshots();
  }

  // NUEVO: Método optimizado para el HistorialScreen para evitar lecturas infinitas
  Stream<QuerySnapshot> getMovimientosPorRango(DateTime inicio, DateTime fin) {
    return _movimientos
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .orderBy('fecha', descending: true)
        .snapshots();
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

  Stream<QuerySnapshot> getMovimientosDestinarPorOrigen(String categoriaOrigenId) {
    return _movimientos
        .where('categoriaOrigenId', isEqualTo: categoriaOrigenId)
        .where('tipo', isEqualTo: 'destinar')
        .orderBy('fecha', descending: true)
        .limit(3)
        .snapshots();
  }

  Stream<QuerySnapshot> getMovimientosDestinarPorDestino(String categoriaDestinoId) {
    return _movimientos
        .where('categoriaDestinoId', isEqualTo: categoriaDestinoId)
        .where('tipo', isEqualTo: 'destinar')
        .orderBy('fecha', descending: true)
        .limit(3)
        .snapshots();
  }

  Stream<QuerySnapshot> getMovimientosIngresoPorCategoria(String categoriaId) {
    return _movimientos
        .where('categoriaOrigenId', isEqualTo: categoriaId)
        .where('tipo', isEqualTo: 'ingreso')
        .orderBy('fecha', descending: true)
        .limit(3)
        .snapshots();
  }

  Future<bool> categoriaIngresaTieneMovimientos(String categoriaId) async {
    final snapshot = await _movimientos
        .where('categoriaOrigenId', isEqualTo: categoriaId)
        .where('tipo', isEqualTo: 'ingreso')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> movimientoIngresoFueDestinado(String movimientoId, String categoriaId) async {
    final snapshot = await _movimientos
        .where('categoriaOrigenId', isEqualTo: categoriaId)
        .where('tipo', isEqualTo: 'destinar')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ─── LIMPIEZA DE DATOS (OPTIMIZADO PARA MEMORIA) ───────────────────────────

  Future<void> eliminarTodosLosDatos() async {
    await _verificarInternet();
    
    // Función auxiliar para borrar en lotes pequeños y proteger la memoria RAM
    Future<void> borrarColeccionEnLotes(CollectionReference ref) async {
      var snapshot = await ref.limit(500).get();
      while (snapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        // Buscar el siguiente lote
        snapshot = await ref.limit(500).get();
      }
    }

    await borrarColeccionEnLotes(_categorias);
    await borrarColeccionEnLotes(_movimientos);
  }

  // ─── USUARIO ───────────────────────────────────────────────────────────────

  Future<bool> monedaConfigurada() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['monedaConfigurada'] == true;
  }

  Future<String?> leerMonedaUsuario() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['moneda'] as String?;
  }

  Future<void> guardarMonedaUsuario(String currencyCode) async {
    await _verificarInternet();
    await _db.collection('users').doc(_uid).set(
      {
        'monedaConfigurada': true,
        'moneda': currencyCode,
      },
      SetOptions(merge: true),
    );
  }
}
