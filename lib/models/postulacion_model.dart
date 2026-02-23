import 'package:cloud_firestore/cloud_firestore.dart';

class PostulacionModel {
  final String id;
  final String puestoId;
  final String puestoTitulo;
  final String userId;
  final String nombres;
  final String apellidos;
  final String carnet;
  final String telefono;
  final String cvUrl;
  final String cvFileName;
  final DateTime fechaPostulacion;
  final String estado; // pendiente | aprobado | rechazado

  PostulacionModel({
    this.id = '',
    required this.puestoId,
    required this.puestoTitulo,
    required this.userId,
    required this.nombres,
    required this.apellidos,
    required this.carnet,
    required this.telefono,
    required this.cvUrl,
    required this.cvFileName,
    required this.fechaPostulacion,
    this.estado = 'pendiente',
  });

  factory PostulacionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostulacionModel(
      id: doc.id,
      puestoId: d['puestoId'] ?? '',
      puestoTitulo: d['puestoTitulo'] ?? '',
      userId: d['userId'] ?? '',
      nombres: d['nombres'] ?? '',
      apellidos: d['apellidos'] ?? '',
      carnet: d['carnet'] ?? '',
      telefono: d['telefono'] ?? '',
      cvUrl: d['cvUrl'] ?? '',
      cvFileName: d['cvFileName'] ?? 'cv.pdf',
      fechaPostulacion:
          (d['fechaPostulacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estado: d['estado'] ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() => {
        'puestoId': puestoId,
        'puestoTitulo': puestoTitulo,
        'userId': userId,
        'nombres': nombres,
        'apellidos': apellidos,
        'carnet': carnet,
        'telefono': telefono,
        'cvUrl': cvUrl,
        'cvFileName': cvFileName,
        'fechaPostulacion': FieldValue.serverTimestamp(),
        'estado': estado,
      };

  String get nombreCompleto => '$apellidos $nombres';
}
