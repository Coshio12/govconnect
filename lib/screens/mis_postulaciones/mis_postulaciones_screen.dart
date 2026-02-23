import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/postulacion_model.dart';
import '../../providers/auth_provider.dart';

class MisPostulacionesScreen extends ConsumerStatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  ConsumerState<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends ConsumerState<MisPostulacionesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postulacionesAsync = ref.watch(misPostulacionesProvider);

    return PopScope(
      canPop: false, // Bloqueamos el cierre automático
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Si intentan ir atrás, los mandamos al Home manualmente en lugar de cerrar la app
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Postulaciones'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(
                  '/home',
                ); // Si no puede volver atrás, lo mandamos al inicio
              }
            },
          ),
        ),
        body: postulacionesAsync.when(
          data: (lista) {
            if (lista.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no te has postulado',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Ve a la lista de puestos y postúlate',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (ctx, i) => _PostulacionCard(
                postulacion: lista[i],
              ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.1, end: 0),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _PostulacionCard extends StatelessWidget {
  final PostulacionModel postulacion;
  const _PostulacionCard({required this.postulacion});

  Color get _estadoColor {
    switch (postulacion.estado) {
      case 'aprobado':
        return const Color(0xFF34A853);
      case 'rechazado':
        return Colors.red;
      default:
        return const Color(0xFFFBBC04);
    }
  }

  String get _estadoLabel {
    switch (postulacion.estado) {
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return 'En revisión';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postulacion.puestoTitulo,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        postulacion.nombreCompleto,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _estadoColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _estadoLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _estadoColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'CI: ${postulacion.carnet}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  postulacion.telefono,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Postulado el ${fmt.format(postulacion.fechaPostulacion)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Verificación en lista
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF34A853).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    color: Color(0xFF34A853),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✓ Tu nombre está registrado en la lista de postulantes',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF34A853),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (postulacion.cvUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(postulacion.cvUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Ver mi CV'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  textStyle: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}