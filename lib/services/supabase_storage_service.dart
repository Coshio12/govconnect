import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class SupabaseStorageService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Nombre del bucket que vas a crear en Supabase
  static const String _bucket = 'documentos-postulaciones';

  /// Abre el selector de archivos y sube el archivo seleccionado a Supabase.
  /// Retorna la URL pública del archivo o null si el usuario canceló.
  static Future<UploadResult?> seleccionarYSubirArchivo({
    required String userId,
    required String puestoId,
  }) async {
    // 1. Abrir file picker — acepta PDF, imágenes, Word, Excel, etc.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'xls', 'xlsx'],
      withData: kIsWeb, // En web necesitamos los bytes directamente
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;

    // 2. Validar tamaño (máx 10 MB)
    const maxBytes = 10 * 1024 * 1024;
    final fileSize = picked.size;
    if (fileSize > maxBytes) {
      throw Exception('El archivo supera el límite de 10 MB');
    }

    // 3. Construir ruta única en el bucket
    final extension = p.extension(picked.name); // Ej: ".pdf"
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$puestoId/$userId/$timestamp$extension';

    // 4. Subir según plataforma
    String publicUrl;

    if (kIsWeb || picked.bytes != null) {
      // Web: usar bytes directamente
      final bytes = picked.bytes!;
      await _client.storage.from(_bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(picked.name),
          upsert: true,
        ),
      );
    } else {
      // Mobile / Desktop: usar File
      final file = File(picked.path!);
      await _client.storage.from(_bucket).upload(
        storagePath,
        file,
        fileOptions: FileOptions(
          contentType: _getContentType(picked.name),
          upsert: true,
        ),
      );
    }

    // 5. Obtener URL pública
    publicUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

    return UploadResult(
      url: publicUrl,
      fileName: picked.name,
      storagePath: storagePath,
    );
  }

  /// Elimina un archivo del storage (por si el usuario re-sube o se elimina la postulación)
  static Future<void> eliminarArchivo(String storagePath) async {
    await _client.storage.from(_bucket).remove([storagePath]);
  }

  static String _getContentType(String fileName) {
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    const types = {
      'pdf': 'application/pdf',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    return types[ext] ?? 'application/octet-stream';
  }
}

class UploadResult {
  final String url;
  final String fileName;
  final String storagePath; // Para poder eliminar después si hace falta

  const UploadResult({
    required this.url,
    required this.fileName,
    required this.storagePath,
  });
}