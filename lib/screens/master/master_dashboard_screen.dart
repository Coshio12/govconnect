import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../master/puesto_form_widget.dart'; // ← formulario compartido

class MasterDashboardScreen extends ConsumerWidget {
  const MasterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puestosAsync = ref.watch(todosPuestosProvider);
    final usuarioAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Cerrar sesión',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: Text(
                    '¿Seguro que deseas cerrar sesión?',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancelar',
                          style: GoogleFonts.poppins(
                              color: Colors.grey[600])),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Sí, salir',
                          style:
                              GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authServiceProvider).signOut();
                SystemNavigator.pop();
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        usuarioAsync.when(
                          data: (u) => Text(
                            'Gestión de Puestos',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => Text(
                            'Panel Master',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'Administra los puestos y postulaciones',
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // ── Stats ─────────────────────────────────────────────
            puestosAsync.when(
              data: (puestos) {
                final activos = puestos.where((p) => p.activo).length;
                final inactivos = puestos.length - activos;
                return Row(
                  children: [
                    _StatCard(
                      icon: Icons.work_outline,
                      label: 'Puestos Activos',
                      value: '$activos',
                      color: const Color(0xFF1A73E8),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.archive_outlined,
                      label: 'Inactivos',
                      value: '$inactivos',
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.layers_outlined,
                      label: 'Total',
                      value: '${puestos.length}',
                      color: const Color(0xFF34A853),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox(),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 24),

            // ── Acciones Rápidas ──────────────────────────────────
            Text(
              'Acciones Rápidas',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // ✅ Abre el PuestoFormWidget directamente (crear)
                _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Nuevo Puesto',
                  subtitle: 'Crear convocatoria',
                  color: const Color(0xFF1A73E8),
                  onTap: () => showPuestoForm(context, ref),
                ),
                // Navega a GestionarPuestosScreen (gestionar/editar)
                _ActionCard(
                  icon: Icons.list_alt_outlined,
                  label: 'Gestionar Puestos',
                  subtitle: 'Editar y eliminar',
                  color: const Color(0xFF34A853),
                  onTap: () => context.push('/master/puestos'),
                ),
              ]
                  .asMap()
                  .entries
                  .map((e) => e.value
                      .animate()
                      .fadeIn(delay: (200 + e.key * 80).ms))
                  .toList(),
            ),

            const SizedBox(height: 28),

            // ── Lista: postulantes por puesto ─────────────────────
            Text(
              'Listas de Postulantes por Puesto',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            puestosAsync.when(
              data: (puestos) {
                if (puestos.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.work_off_outlined,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No hay puestos creados aún',
                            style:
                                GoogleFonts.poppins(color: Colors.grey)),
                        const SizedBox(height: 12),
                        // ✅ Estado vacío también usa el formulario compartido
                        ElevatedButton.icon(
                          onPressed: () => showPuestoForm(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear primer puesto'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: puestos
                      .asMap()
                      .entries
                      .map(
                        (e) => _PuestoResumenCard(puesto: e.value)
                            .animate()
                            .fadeIn(delay: (e.key * 60).ms)
                            .slideX(begin: 0.05, end: 0),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TARJETA RESUMEN — toca para ver lista de postulantes
// ════════════════════════════════════════════════════════════

class _PuestoResumenCard extends StatefulWidget {
  final dynamic puesto;
  const _PuestoResumenCard({required this.puesto});

  @override
  State<_PuestoResumenCard> createState() => _PuestoResumenCardState();
}

class _PuestoResumenCardState extends State<_PuestoResumenCard> {
  int? _totalPostulantes;

  @override
  void initState() {
    super.initState();
    _cargarPostulantes();
  }

  Future<void> _cargarPostulantes() async {
    final snap = await FirebaseFirestore.instance
        .collection('postulaciones')
        .where('puestoId', isEqualTo: widget.puesto.id)
        .count()
        .get();
    if (mounted) {
      setState(() => _totalPostulantes = snap.count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puesto = widget.puesto;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/master/postulantes/${puesto.id}'
          '?titulo=${Uri.encodeComponent(puesto.titulo)}',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: puesto.activo
                      ? const Color(0xFF1A73E8).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  color: puesto.activo ? const Color(0xFF1A73E8) : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puesto.titulo,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      puesto.dependencia,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: puesto.activo
                          ? const Color(0xFF34A853).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      puesto.activo ? 'Activo' : 'Inactivo',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: puesto.activo
                            ? const Color(0xFF34A853)
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Número real de postulantes desde Firestore
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      _totalPostulantes == null
                          ? SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.grey[400],
                              ),
                            )
                          : Text(
                              '$_totalPostulantes postulante(s)',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: Colors.grey[400]),
                            ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  STAT CARD
// ════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                  height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ACTION CARD
// ════════════════════════════════════════════════════════════

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}