import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/puesto_model.dart';
import '../models/postulacion_model.dart';
import '../models/usuario_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────────────────── USUARIOS ─────────────────────────────

  Future<UsuarioModel?> getUsuario(String uid) async {
    final doc =
        await _db.collection(AppConstants.colUsuarios).doc(uid).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromFirestore(doc);
  }

  // ───────────────────────────── PUESTOS ─────────────────────────────

  Stream<List<PuestoModel>> getPuestosActivos() {
    return _db
        .collection(AppConstants.colPuestos)
        .where('activo', isEqualTo: true)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(PuestoModel.fromFirestore).toList());
  }

  Stream<List<PuestoModel>> getTodosPuestos() {
    return _db
        .collection(AppConstants.colPuestos)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(PuestoModel.fromFirestore).toList());
  }

  Future<void> crearPuesto(PuestoModel puesto) =>
      _db.collection(AppConstants.colPuestos).add(puesto.toMap());

  Future<void> actualizarPuesto(String id, Map<String, dynamic> datos) =>
      _db.collection(AppConstants.colPuestos).doc(id).update(datos);

  Future<void> actualizarFechaExamen(String puestoId, DateTime? fecha) =>
      _db.collection(AppConstants.colPuestos).doc(puestoId).update({
        'fechaExamen':
            fecha != null ? Timestamp.fromDate(fecha) : null,
      });

  Future<void> eliminarPuesto(String puestoId) =>
      _db.collection(AppConstants.colPuestos).doc(puestoId).update({
        'activo': false,
      });

  // Borrar puesto permanentemente de Firestore (borrado físico)
  Future<void> eliminarPuestoPermanente(String puestoId) =>
      _db.collection(AppConstants.colPuestos).doc(puestoId).delete();

  // ─────────────────────────── POSTULACIONES ───────────────────────────

  Future<DocumentReference> crearPostulacion(PostulacionModel p) =>
      _db.collection(AppConstants.colPostulaciones).add(p.toMap());

  Stream<List<PostulacionModel>> getPostulacionesDeUsuario(String userId) {
    return _db
        .collection(AppConstants.colPostulaciones)
        .where('userId', isEqualTo: userId)
        .orderBy('fechaPostulacion', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(PostulacionModel.fromFirestore).toList());
  }

  Stream<List<PostulacionModel>> getPostulantesPorPuesto(String puestoId) {
    return _db
        .collection(AppConstants.colPostulaciones)
        .where('puestoId', isEqualTo: puestoId)
        .orderBy('apellidos')
        .snapshots()
        .map((snap) =>
            snap.docs.map(PostulacionModel.fromFirestore).toList());
  }

  /// Obtiene la lista de postulantes de un puesto (una sola lectura).
  Future<List<PostulacionModel>> getPostulantesPorPuestoList(
      String puestoId) async {
    final snap = await _db
        .collection(AppConstants.colPostulaciones)
        .where('puestoId', isEqualTo: puestoId)
        .get();
    return snap.docs.map(PostulacionModel.fromFirestore).toList();
  }

  Future<bool> yaPostulado(String userId, String puestoId) async {
    final snap = await _db
        .collection(AppConstants.colPostulaciones)
        .where('userId', isEqualTo: userId)
        .where('puestoId', isEqualTo: puestoId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> eliminarPostulacion(String postId) =>
      _db.collection(AppConstants.colPostulaciones).doc(postId).delete();

  Future<void> actualizarEstadoPostulacion(
          String postId, String estado) =>
      _db
          .collection(AppConstants.colPostulaciones)
          .doc(postId)
          .update({'estado': estado});

  
}
