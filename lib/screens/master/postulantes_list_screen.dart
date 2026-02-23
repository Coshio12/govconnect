import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
    final postulantesAsync =
        ref.watch(postulantesPorPuestoProvider(puestoId));

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
          // Header con info del puesto
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
                        value: DateFormat('dd/MM/yy')
                            .format(puesto.fechaExamen!),
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
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: postulantes.length,
                  itemBuilder: (ctx, i) =>
                      _PostulanteRow(
                        numero: i + 1,
                        postulacion: postulantes[i],
                        ref: ref,
                      )
                          .animate()
                          .fadeIn(delay: (i * 40).ms)
                          .slideX(begin: 0.05, end: 0),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarPdf(
      BuildContext context, List<PostulacionModel> postulantes) async {
    // 1. Obtener datos del puesto
    final doc = await FirebaseFirestore.instance
        .collection('puestos')
        .doc(puestoId)
        .get();
    final puesto = PuestoModel.fromFirestore(doc);

    if (!context.mounted) return;

    // 2. Mostrar opciones al usuario
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                
                // Navegar a la previsualización
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
                  final nombre = 'Lista_${puesto.titulo.replaceAll(' ', '_')}.pdf';
                  await PdfService.guardarPdfLocal(nombre, bytes);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.download_done_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'PDF guardado en tu carpeta Descargas',
                              style: TextStyle(fontWeight: FontWeight.w500),
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

class _PostulanteRow extends StatelessWidget {
  final int numero;
  final PostulacionModel postulacion;
  final WidgetRef ref;

  const _PostulanteRow({
    required this.numero,
    required this.postulacion,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Número
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('$numero',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            // Datos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    postulacion.nombreCompleto,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('CI: ${postulacion.carnet}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      Text('Tel: ${postulacion.telefono}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  Text(
                    fmt.format(postulacion.fechaPostulacion),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            // Acciones
            Column(
              children: [
                if (postulacion.cvUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        color: Color(0xFF1A73E8), size: 22),
                    tooltip: 'Ver CV',
                    onPressed: () async {
                      final uri = Uri.parse(postulacion.cvUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                // Eliminar postulante
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined,
                      color: Colors.red, size: 22),
                  tooltip: 'Eliminar de la lista',
                  onPressed: () => _confirmarEliminar(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
}

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
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}