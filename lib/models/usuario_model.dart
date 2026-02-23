import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String uid;
  final String email;
  final String nombre;
  final String? foto;
  final String rol; // usuario | master
  final DateTime? creadoEn;

  UsuarioModel({
    required this.uid,
    required this.email,
    required this.nombre,
    this.foto,
    this.rol = 'usuario',
    this.creadoEn,
  });

  bool get isMaster => rol == 'master';

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      uid: doc.id,
      email: d['email'] ?? '',
      nombre: d['nombre'] ?? '',
      foto: d['foto'],
      rol: d['rol'] ?? 'usuario',
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'nombre': nombre,
        'foto': foto,
        'rol': rol,
        'creadoEn': FieldValue.serverTimestamp(),
      };
}
