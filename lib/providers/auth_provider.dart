import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/usuario_model.dart';

// ─────────────────── SERVICES ───────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());

// ─────────────────── AUTH STATE ───────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ─────────────────── CURRENT USER MODEL ───────────────────

final currentUserProvider = FutureProvider<UsuarioModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(firestoreServiceProvider).getUsuario(user.uid);
});

// ─────────────────── IS MASTER ───────────────────

final isMasterProvider = FutureProvider<bool>((ref) async {
  final usuario = await ref.watch(currentUserProvider.future);
  return usuario?.isMaster ?? false;
});

// ─────────────────── PUESTOS ───────────────────

final puestosActivosProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).getPuestosActivos();
});

final todosPuestosProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).getTodosPuestos();
});

// ─────────────────── POSTULACIONES ───────────────────

final misPostulacionesProvider = StreamProvider((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref
      .watch(firestoreServiceProvider)
      .getPostulacionesDeUsuario(user.uid);
});

final postulantesPorPuestoProvider =
    StreamProvider.family<dynamic, String>((ref, puestoId) {
  return ref
      .watch(firestoreServiceProvider)
      .getPostulantesPorPuesto(puestoId);
});
