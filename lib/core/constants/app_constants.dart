class AppConstants {
  // Firestore collections
  static const String colUsuarios = 'usuarios';
  static const String colPuestos = 'puestos';
  static const String colPostulaciones = 'postulaciones';

  // Storage paths
  static const String storageCvs = 'cvs';

  // Roles
  static const String rolUsuario = 'usuario';
  static const String rolMaster = 'master';

  // Estados de postulación
  static const String estadoPendiente = 'pendiente';
  static const String estadoAprobado = 'aprobado';
  static const String estadoRechazado = 'rechazado';

  // Validaciones
  static const int maxCvSizeMb = 5;
  static const String carnetRegex = r'^\d{6,10}[A-Z]?$';
  static const String telefonoRegex = r'^[67]\d{7}$';
}
