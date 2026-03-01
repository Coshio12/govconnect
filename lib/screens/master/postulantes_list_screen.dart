import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/postulacion_model.dart';
import '../../models/puesto_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/pdf_service.dart';

class PostulantesListScreen extends ConsumerWidget {
  final String puestoId;
  final String puestoTitulo;
  const PostulantesListScreen(
      {super.key, required this.puestoId, required this.puestoTitulo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postulantesAsync = ref.watch(postulantesPorPuestoProvider(puestoId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          puestoTitulo.length > 25
              ? '${puestoTitulo.substring(0, 25)}...'
              : puestoTitulo,
        ),
        actions: [
          postulantesAsync.when(
            data: (postulantes) => IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exportar PDF',
              onPressed: () => _exportarPdf(context, postulantes),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header con info del puesto ──────────────────────
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('puestos')
                .doc(puestoId)
                .get(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox();
              final puesto = PuestoModel.fromFirestore(snap.data!);
              return Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1A73E8).withValues(alpha: 0.05),
                child: Row(
                  children: [
                    _InfoBadge(
                      icon: Icons.people_outline,
                      label: 'Vacantes',
                      value: '${puesto.vacantes}',
                    ),
                    const SizedBox(width: 12),
                    if (puesto.fechaExamen != null)
                      _InfoBadge(
                        icon: Icons.event_outlined,
                        label: 'Examen',
                        value: DateFormat('dd/MM/yy').format(puesto.fechaExamen!),
                        color: const Color(0xFF34A853),
                      ),
                    const Spacer(),
                    postulantesAsync.when(
                      data: (p) => _InfoBadge(
                        icon: Icons.assignment_outlined,
                        label: 'Postulantes',
                        value: '${p.length}',
                        color: const Color(0xFF9C27B0),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Lista de postulantes ────────────────────────────
          Expanded(
            child: postulantesAsync.when(
              data: (postulantes) {
                if (postulantes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search_outlined,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Sin postulantes aún',
                            style: GoogleFonts.poppins(
                                fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // ── Resumen de archivos adjuntos ──────────────
                final lista = postulantes.cast<PostulacionModel>();
                final conArchivo =
                    lista.where((p) => p.cvUrl.isNotEmpty).length;
                final sinArchivo = lista.length - conArchivo;

                return Column(
                  children: [
                    // Banner de resumen
                    if (postulantes.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Archivos adjuntos: ',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            _ResumenChip(
                              label: '$conArchivo con archivo',
                              color: const Color(0xFF34A853),
                            ),
                            const SizedBox(width: 6),
                            if (sinArchivo > 0)
                              _ResumenChip(
                                label: '$sinArchivo sin archivo',
                                color: Colors.orange,
                              ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                        itemCount: lista.length,
                        itemBuilder: (ctx, i) => _PostulanteRow(
                          numero: i + 1,
                          postulacion: lista[i],
                          ref: ref,
                        )
                            .animate()
                            .fadeIn(delay: (i * 40).ms)
                            .slideX(begin: 0.05, end: 0),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarPdf(
      BuildContext context, List<PostulacionModel> postulantes) async {
    final doc = await FirebaseFirestore.instance
        .collection('puestos')
        .doc(puestoId)
        .get();
    final puesto = PuestoModel.fromFirestore(doc);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opciones de Exportación',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1A73E8),
                child: Icon(Icons.remove_red_eye, color: Colors.white),
              ),
              title: Text('Visualizar PDF', style: GoogleFonts.poppins()),
              subtitle: Text('Ver, imprimir o compartir directamente',
                  style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                final pdf = await PdfService.crearDocumento(
                  puestoTitulo: puesto.titulo,
                  dependencia: puesto.dependencia,
                  vacantes: puesto.vacantes,
                  fechaExamen: puesto.fechaExamen,
                  postulantes: postulantes,
                );
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Previsualización')),
                      body: PdfPreview(
                        build: (format) => pdf.save(),
                        allowPrinting: true,
                        allowSharing: true,
                        canChangePageFormat: false,
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF34A853),
                child: Icon(Icons.download, color: Colors.white),
              ),
              title: Text('Descargar archivo', style: GoogleFonts.poppins()),
              subtitle: Text('Guardar en el almacenamiento del dispositivo',
                  style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pdf = await PdfService.crearDocumento(
                    puestoTitulo: puesto.titulo,
                    dependencia: puesto.dependencia,
                    vacantes: puesto.vacantes,
                    fechaExamen: puesto.fechaExamen,
                    postulantes: postulantes,
                  );
                  final bytes = await pdf.save();
                  final nombre =
                      'Lista_${puesto.titulo.replaceAll(' ', '_')}.pdf';
                  await PdfService.guardarPdfLocal(nombre, bytes);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.download_done_rounded,
                              color: Colors.white),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'PDF guardado en tu carpeta Descargas',
                              style:
                                  TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF34A853),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FILA DE POSTULANTE
// ════════════════════════════════════════════════════════════

class _PostulanteRow extends StatelessWidget {
  final int numero;
  final PostulacionModel postulacion;
  final WidgetRef ref;

  const _PostulanteRow({
    required this.numero,
    required this.postulacion,
    required this.ref,
  });

  // ── Helpers de tipo de archivo ──────────────────────────

  String get _fileExt {
    if (postulacion.cvFileName.isEmpty) return '';
    return postulacion.cvFileName.split('.').last.toLowerCase();
  }

  IconData get _fileIcon {
    switch (_fileExt) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      default:
        return Icons.attach_file;
    }
  }

  Color get _fileColor {
    switch (_fileExt) {
      case 'pdf':
        return Colors.red;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Colors.purple;
      case 'doc':
      case 'docx':
        return const Color(0xFF1A73E8);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF34A853);
      default:
        return Colors.grey;
    }
  }

  String get _fileLabel {
    switch (_fileExt) {
      case 'pdf':
        return 'PDF';
      case 'png':
      case 'jpg':
      case 'jpeg':
        return 'Imagen';
      case 'doc':
      case 'docx':
        return 'Word';
      case 'xls':
      case 'xlsx':
        return 'Excel';
      default:
        return 'Archivo';
    }
  }

  // ── Abrir archivo (solo lectura) ────────────────────────

  Future<void> _abrirArchivo(BuildContext context) async {
    final url = postulacion.cvUrl;
    if (url.isEmpty) return;

    // PDF → visor interno de solo lectura (sin lápices ni edición)
    if (_fileExt == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfViewerScreen(
            url: url,
            fileName: postulacion.cvFileName,
          ),
        ),
      );
      return;
    }

    // Imágenes → visor interno de solo lectura
    if (['png', 'jpg', 'jpeg'].contains(_fileExt)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ImageViewerScreen(
            url: url,
            fileName: postulacion.cvFileName,
          ),
        ),
      );
      return;
    }

    // Word / Excel y otros → navegador en modo inApp (sin app externa que edite)
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el archivo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar postulante?'),
        content: Text(
            '¿Seguro que deseas eliminar a ${postulacion.nombreCompleto} de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(firestoreServiceProvider)
          .eliminarPostulacion(postulacion.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    final tieneArchivo = postulacion.cvUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila principal: número + datos + eliminar ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Datos personales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postulacion.nombreCompleto,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text('CI: ${postulacion.carnet}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(width: 10),
                          const Icon(Icons.phone_outlined,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(postulacion.telefono,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined,
                              size: 11, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            fmt.format(postulacion.fechaPostulacion),
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón eliminar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: Colors.red, size: 20),
                    tooltip: 'Eliminar de la lista',
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _confirmarEliminar(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Botón de archivo adjunto ────────────────────
            tieneArchivo
                ? _BotonArchivo(
                    fileName: postulacion.cvFileName,
                    fileIcon: _fileIcon,
                    fileColor: _fileColor,
                    fileLabel: _fileLabel,
                    onTap: () => _abrirArchivo(context),
                  )
                : _SinArchivo(),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  BOTÓN DE ARCHIVO (cuando sí subió)
// ════════════════════════════════════════════════════════════

class _BotonArchivo extends StatelessWidget {
  final String fileName;
  final IconData fileIcon;
  final Color fileColor;
  final String fileLabel;
  final VoidCallback onTap;

  const _BotonArchivo({
    required this.fileName,
    required this.fileIcon,
    required this.fileColor,
    required this.fileLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: fileColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fileColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Ícono del tipo de archivo
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: fileColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(fileIcon, color: fileColor, size: 18),
            ),
            const SizedBox(width: 10),

            // Nombre del archivo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName.isNotEmpty ? fileName : 'Documento adjunto',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fileColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$fileLabel · Toca para abrir',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Indicador de subido + flecha
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF34A853), size: 11),
                      const SizedBox(width: 3),
                      Text(
                        'Subido',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF34A853),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.open_in_new_rounded,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  INDICADOR SIN ARCHIVO
// ════════════════════════════════════════════════════════════

class _SinArchivo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            'Sin documento adjunto',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CHIP RESUMEN
// ════════════════════════════════════════════════════════════

class _ResumenChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ResumenChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  INFO BADGE (header)
// ════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════
//  VISOR DE PDF — solo lectura, sin herramientas de edición
// ════════════════════════════════════════════════════════════

class _PdfViewerScreen extends StatefulWidget {
  final String url;
  final String fileName;
  const _PdfViewerScreen({required this.url, required this.fileName});

  @override
  State<_PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<_PdfViewerScreen> {
  String? _localPath;
  bool _loading = true;
  bool _error = false;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  // Descarga el PDF a un archivo temporal para mostrarlo con flutter_pdfview
  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) throw Exception('Error al descargar');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName}');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) setState(() => _localPath = file.path);
    } catch (e) {
      if (mounted) setState(() { _error = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Página ${_currentPage + 1} de $_totalPages · Solo lectura',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54),
              )
            else
              Text(
                'Solo lectura',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 13, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  'Solo lectura',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF cargado: mostrar con flutter_pdfview
          if (_localPath != null)
            PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              fitPolicy: FitPolicy.BOTH,
              onRender: (pages) => setState(() {
                _totalPages = pages ?? 0;
                _loading = false;
              }),
              onPageChanged: (page, total) => setState(() {
                _currentPage = page ?? 0;
                _totalPages = total ?? 0;
              }),
              onError: (_) => setState(() { _error = true; _loading = false; }),
            ),

          // Error al cargar
          if (_error)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudo cargar el PDF',
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.parse(widget.url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      'Abrir en otra app',
                      style: GoogleFonts.poppins(color: const Color(0xFF1A73E8)),
                    ),
                  ),
                ],
              ),
            ),

          // Cargando
          if (_loading)
            Container(
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF1A73E8)),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando documento...',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VISOR DE IMAGEN — solo lectura con zoom
// ════════════════════════════════════════════════════════════

class _ImageViewerScreen extends StatelessWidget {
  final String url;
  final String fileName;
  const _ImageViewerScreen({required this.url, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Solo lectura',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 13, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  'Solo lectura',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          // Zoom con los dedos pero sin edición
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF1A73E8),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_outlined,
                    size: 64, color: Colors.white54),
                const SizedBox(height: 12),
                Text(
                  'No se pudo cargar la imagen',
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  INFO BADGE (header)
// ════════════════════════════════════════════════════════════

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    this.color = const Color(0xFF1A73E8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 9, color: Colors.grey[600])),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 12, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}