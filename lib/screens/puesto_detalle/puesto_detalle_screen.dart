import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/puesto_model.dart';
import '../../providers/auth_provider.dart';

class PuestoDetalleScreen extends ConsumerWidget {
  final String puestoId;
  const PuestoDetalleScreen({super.key, required this.puestoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Puesto')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('puestos')
            .doc(puestoId)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Puesto no encontrado'));
          }
          final puesto = PuestoModel.fromFirestore(snap.data!);
          return _DetalleBody(puesto: puesto);
        },
      ),
    );
  }
}

class _DetalleBody extends ConsumerStatefulWidget {
  final PuestoModel puesto;
  const _DetalleBody({required this.puesto});

  @override
  ConsumerState<_DetalleBody> createState() => _DetalleBodyState();
}

class _DetalleBodyState extends ConsumerState<_DetalleBody> {
  bool _yaPostulado = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPostulacion();
  }

  Future<void> _checkPostulacion() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final res = await ref
          .read(firestoreServiceProvider)
          .yaPostulado(user.uid, widget.puesto.id);
      if (mounted) setState(() { _yaPostulado = res; _checking = false; });
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puesto;
    final fmt = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  p.titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.dependencia,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Chip(
                        icon: Icons.people_outline,
                        label: '${p.vacantes} vacante(s)'),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.calendar_today_outlined,
                      label:
                          'Límite: ${fmt.format(p.fechaLimite)}',
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          // Fecha examen
          if (p.fechaExamen != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF34A853).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined,
                      color: Color(0xFF34A853), size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha de Examen de Suficiencia',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF34A853))),
                      Text(
                        fmt.format(p.fechaExamen!),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF34A853),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Descripción
          _Section(
            title: 'Descripción del Puesto',
            child: Text(
              p.descripcion,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey[700], height: 1.6),
            ),
          ),

          // Requisitos
          if (p.requisitos.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Section(
              title: 'Requisitos',
              child: Column(
                children: p.requisitos
                    .map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF34A853), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(req,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[700])),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Botón postularse
          SizedBox(
            width: double.infinity,
            height: 54,
            child: _checking
                ? const Center(child: CircularProgressIndicator())
                : _yaPostulado
                    ? OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/mis-postulaciones'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Ya estás postulado · Ver lista'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF34A853),
                          side: const BorderSide(
                              color: Color(0xFF34A853), width: 1.5),
                          shape: const StadiumBorder(),
                        ),
                      )
                    : p.isVigente
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/postular/${p.id}'),
                            icon: const Icon(Icons.send_outlined),
                            label: const Text('Postularme a este puesto'),
                          )
                        : ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey),
                            child: const Text('Convocatoria cerrada'),
                          ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
