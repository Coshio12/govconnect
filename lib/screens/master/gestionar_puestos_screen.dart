import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/puesto_model.dart';
import '../../providers/auth_provider.dart';
import 'puesto_form_widget.dart'; // ← formulario compartido

class GestionarPuestosScreen extends ConsumerStatefulWidget {
  const GestionarPuestosScreen({super.key});

  @override
  ConsumerState<GestionarPuestosScreen> createState() => _GestionarPuestosScreenState();
}

class _GestionarPuestosScreenState extends ConsumerState<GestionarPuestosScreen> {
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
    final puestosAsync = ref.watch(todosPuestosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Puestos')),
      // FAB usa el formulario compartido
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPuestoForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Puesto'),
      ),
      body: puestosAsync.when(
        data: (puestos) {
          final filtrados = _query.isEmpty
              ? puestos
              : puestos.where((p) =>
                  p.titulo.toLowerCase().contains(_query) ||
                  p.dependencia.toLowerCase().contains(_query)).toList();

          return Column(
            children: [
              // Buscador
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar puesto de trabajo...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
              Expanded(
                child: filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.work_off_outlined,
                                size: 72, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _query.isEmpty
                                  ? 'No hay puestos. Crea uno.'
                                  : 'Sin resultados para "$_query"',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtrados.length,
                        itemBuilder: (ctx, i) => _PuestoAdminCard(
                          puesto: filtrados[i],
                          ref: ref,
                          onEdit: () =>
                              showPuestoForm(context, ref, existing: filtrados[i]),
                        ).animate().fadeIn(delay: (i * 60).ms),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TARJETA DE PUESTO
// ════════════════════════════════════════════════════════════

class _PuestoAdminCard extends StatelessWidget {
  final PuestoModel puesto;
  final WidgetRef ref;
  final VoidCallback onEdit;

  const _PuestoAdminCard({
    required this.puesto,
    required this.ref,
    required this.onEdit,
  });

  Future<void> _confirmarCambioEstado(
    BuildContext context,
    bool nuevoValor,
  ) async {
    final accionTitulo = nuevoValor ? 'Activar puesto' : 'Desactivar puesto';
    final colorBoton = nuevoValor ? const Color(0xFF34A853) : Colors.orange;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              nuevoValor
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              color: colorBoton,
            ),
            const SizedBox(width: 8),
            Text(
              accionTitulo,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '¿Seguro que quieres ${nuevoValor ? 'activar' : 'desactivar'} '
          'el puesto\n"${puesto.titulo}"?',
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorBoton,
              shape: const StadiumBorder(),
            ),
            child: Text(
              nuevoValor ? 'Sí, activar' : 'Sí, desactivar',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(firestoreServiceProvider).actualizarPuesto(puesto.id, {
        'activo': nuevoValor,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoValor
                  ? 'Puesto "${puesto.titulo}" activado'
                  : 'Puesto "${puesto.titulo}" desactivado',
            ),
            backgroundColor: colorBoton,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmarBorradoPermanente(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Eliminar puesto',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Seguro que quiere borrar permanentemente el puesto?',
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      puesto.titulo,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '⚠️ Esta acción no se puede deshacer.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Borrar definitivamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(firestoreServiceProvider)
          .eliminarPuestoPermanente(puesto.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Puesto "${puesto.titulo}" eliminado permanentemente',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _asignarFechaExamen(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          puesto.fechaExamen ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) {
      await ref
          .read(firestoreServiceProvider)
          .actualizarFechaExamen(puesto.id, fecha);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fecha de examen: ${DateFormat('dd/MM/yyyy').format(fecha)}',
            ),
            backgroundColor: const Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + badge + switch
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        puesto.titulo,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        puesto.dependencia,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: puesto.activo
                        ? const Color(0xFF34A853).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    puesto.activo ? 'Activo' : 'Inactivo',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: puesto.activo
                          ? const Color(0xFF34A853)
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: puesto.activo,
                  onChanged: (val) => _confirmarCambioEstado(context, val),
                  activeTrackColor: const Color(0xFF34A853),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chips de info
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  icon: Icons.people_outline,
                  label: '${puesto.vacantes} vacante(s)',
                ),
                _Chip(
                  icon: Icons.event_outlined,
                  label: puesto.fechaExamen != null
                      ? 'Examen: ${fmt.format(puesto.fechaExamen!)}'
                      : 'Sin fecha de examen',
                  color: puesto.fechaExamen != null
                      ? const Color(0xFF34A853)
                      : Colors.orange,
                ),
                _Chip(
                  icon: Icons.calendar_month_outlined,
                  label: 'Límite: ${fmt.format(puesto.fechaLimite)}',
                  color: const Color(0xFF9C27B0),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '/master/postulantes/${puesto.id}?titulo=${Uri.encodeComponent(puesto.titulo)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ), // Un poco más de padding vertical
                      textStyle: GoogleFonts.poppins(fontSize: 12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize
                          .min, // Importante para que el botón no sea gigante
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centra verticalmente
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Centra horizontalmente
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 14,
                        ), // Icono un poco más grande para que luzca mejor arriba
                        const SizedBox(
                          height: 4,
                        ), // Espacio entre el icono y el texto
                        const Text('Postulantes'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _asignarFechaExamen(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ), // Espaciado para dar aire al diseño vertical
                      textStyle: GoogleFonts.poppins(fontSize: 10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize
                          .min, // Ajusta el botón al tamaño del contenido
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centra verticalmente
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Centra horizontalmente
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                        ), // Icono centrado arriba
                        const SizedBox(
                          height: 4,
                        ), // Separación entre icono y texto
                        const Text(
                          'Fecha Examen',
                          textAlign: TextAlign
                              .center, // Asegura que el texto esté centrado si ocupa dos líneas
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Editar — abre PuestoFormWidget precargado
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF1A73E8),
                      size: 20,
                    ),
                    tooltip: 'Editar puesto',
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 6),
                // Borrar permanentemente
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'Borrar permanentemente',
                    onPressed: () => _confirmarBorradoPermanente(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CHIP DE INFO
// ════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF1A73E8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}