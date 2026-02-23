import 'package:cloud_firestore/cloud_firestore.dart';

class PuestoModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String dependencia;
  final int vacantes;
  final DateTime? fechaExamen;
  final DateTime fechaLimite;
  final bool activo;
  final List<String> requisitos;
  final DateTime? creadoEn;

  PuestoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.dependencia,
    required this.vacantes,
    this.fechaExamen,
    required this.fechaLimite,
    this.activo = true,
    this.requisitos = const [],
    this.creadoEn,
  });

  factory PuestoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PuestoModel(
      id: doc.id,
      titulo: d['titulo'] ?? '',
      descripcion: d['descripcion'] ?? '',
      dependencia: d['dependencia'] ?? '',
      vacantes: d['vacantes'] ?? 1,
      fechaExamen: (d['fechaExamen'] as Timestamp?)?.toDate(),
      fechaLimite: (d['fechaLimite'] as Timestamp).toDate(),
      activo: d['activo'] ?? true,
      requisitos: List<String>.from(d['requisitos'] ?? []),
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'dependencia': dependencia,
        'vacantes': vacantes,
        'fechaExamen':
            fechaExamen != null ? Timestamp.fromDate(fechaExamen!) : null,
        'fechaLimite': Timestamp.fromDate(fechaLimite),
        'activo': activo,
        'requisitos': requisitos,
        'creadoEn': FieldValue.serverTimestamp(),
      };

  PuestoModel copyWith({
    String? titulo,
    String? descripcion,
    String? dependencia,
    int? vacantes,
    DateTime? fechaExamen,
    DateTime? fechaLimite,
    bool? activo,
    List<String>? requisitos,
  }) =>
      PuestoModel(
        id: id,
        titulo: titulo ?? this.titulo,
        descripcion: descripcion ?? this.descripcion,
        dependencia: dependencia ?? this.dependencia,
        vacantes: vacantes ?? this.vacantes,
        fechaExamen: fechaExamen ?? this.fechaExamen,
        fechaLimite: fechaLimite ?? this.fechaLimite,
        activo: activo ?? this.activo,
        requisitos: requisitos ?? this.requisitos,
        creadoEn: creadoEn,
      );

  bool get isVigente => DateTime.now().isBefore(fechaLimite);
}
