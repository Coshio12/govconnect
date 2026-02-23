import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/puesto_model.dart';
import '../../providers/auth_provider.dart';

/// Abre el formulario de crear/editar puesto con el estilo de PostulacionFormScreen.
void showPuestoForm(BuildContext context, WidgetRef ref, {PuestoModel? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PuestoFormWidget(existing: existing, ref: ref),
  );
}

class PuestoFormWidget extends ConsumerStatefulWidget {
  final PuestoModel? existing;
  final WidgetRef ref;

  const PuestoFormWidget({super.key, this.existing, required this.ref});

  @override
  ConsumerState<PuestoFormWidget> createState() => _PuestoFormWidgetState();
}

class _PuestoFormWidgetState extends ConsumerState<PuestoFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dependenciaCtrl = TextEditingController();
  final _vacantesCtrl = TextEditingController(text: '1');
  final _requisitoCtrl = TextEditingController();
  
  final List<String> _requisitos = [];
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  bool get _esEdicion => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.existing!;
      _tituloCtrl.text = p.titulo;
      _descCtrl.text = p.descripcion;
      _dependenciaCtrl.text = p.dependencia;
      _vacantesCtrl.text = '${p.vacantes}';
      _requisitos.addAll(p.requisitos);
      _fechaLimite = p.fechaLimite;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final puesto = PuestoModel(
        id: widget.existing?.id ?? '',
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        dependencia: _dependenciaCtrl.text.trim(),
        vacantes: int.tryParse(_vacantesCtrl.text) ?? 1,
        fechaLimite: _fechaLimite,
        requisitos: List<String>.from(_requisitos),
        fechaExamen: widget.existing?.fechaExamen,
        activo: widget.existing?.activo ?? true,
      );

      if (!_esEdicion) {
        await ref.read(firestoreServiceProvider).crearPuesto(puesto);
      } else {
        await ref.read(firestoreServiceProvider).actualizarPuesto(
          puesto.id,
          {
            'titulo': puesto.titulo,
            'descripcion': puesto.descripcion,
            'dependencia': puesto.dependencia,
            'vacantes': puesto.vacantes,
            'fechaLimite': puesto.toMap()['fechaLimite'],
            'requisitos': puesto.requisitos,
          },
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion
                ? 'Puesto actualizado correctamente'
                : 'Puesto creado correctamente'),
            backgroundColor: const Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _agregarRequisito() {
    final texto = _requisitoCtrl.text.trim();
    if (texto.isNotEmpty) {
      setState(() {
        _requisitos.add(texto);
        _requisitoCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle superior
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Banner Azul (Idéntico a PostulacionFormScreen)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _esEdicion ? Icons.edit_note_rounded : Icons.work_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _esEdicion ? 'Editando puesto:' : 'Nuevo puesto',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _esEdicion ? widget.existing!.titulo : 'Completa los detalles',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              Text(
                'Información del Puesto',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              const _FieldLabel(label: 'Título del puesto *', style: TextStyle(color: Colors.white)),
              TextFormField(
                controller: _tituloCtrl,
                style: TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ej: Técnico en Sistemas',
                  fillColor: Color(0xFF0F3460),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              const _FieldLabel(label: 'Descripción *', style: TextStyle(color: Colors.white)),
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Describe las funciones...',
                  fillColor: Color(0xFF0F3460),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              const _FieldLabel(label: 'Dependencia *', style: TextStyle(color: Colors.white)),
              TextFormField(
                controller: _dependenciaCtrl,
                style: TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ej: Secretaría de Salud',
                  fillColor: Color(0xFF0F3460),
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              const _FieldLabel(label: 'Número de vacantes *', style: TextStyle(color: Colors.white)),
              TextFormField(
                controller: _vacantesCtrl,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej: 2',
                  fillColor: Color(0xFF0F3460),
                  prefixIcon: Icon(Icons.people_outline),
                ),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Inválido' : null,
              ),

              const SizedBox(height: 24),
              Text(
                'Fecha Límite',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Selector de Fecha con el color azul de la app
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fechaLimite,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _fechaLimite = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        fmt.format(_fechaLimite),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_calendar_outlined, color: Colors.grey[400], size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Requisitos',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),

              const _FieldLabel(label: 'Agregar requisito', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _requisitoCtrl,
                      style: TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ej: Título Provisión Nacional',
                        prefixIcon: Icon(Icons.checklist_outlined),
                      ),
                      onFieldSubmitted: (_) => _agregarRequisito(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _agregarRequisito,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // Lista de Requisitos Estilizada
              ..._requisitos.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF34A853), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value, style: GoogleFonts.poppins(fontSize: 13), selectionColor: Colors.white,)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      onPressed: () => setState(() => _requisitos.removeAt(e.key)),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 32),

              // Botón Principal con el estilo de PostulacionFormScreen
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _guardar,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(_esEdicion ? Icons.save_as_outlined : Icons.send_outlined),
                  label: Text(
                    _saving ? 'Guardando...' : (_esEdicion ? 'Guardar Cambios' : 'Crear Puesto'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _dependenciaCtrl.dispose();
    _vacantesCtrl.dispose();
    _requisitoCtrl.dispose();
    super.dispose();
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final TextStyle? style;
  const _FieldLabel({required this.label, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: style?.color ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}