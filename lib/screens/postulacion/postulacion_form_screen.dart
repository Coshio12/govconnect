import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/postulacion_model.dart';
import '../../models/puesto_model.dart';
import '../../providers/auth_provider.dart';

class PostulacionFormScreen extends ConsumerStatefulWidget {
  final String puestoId;
  const PostulacionFormScreen({super.key, required this.puestoId});

  @override
  ConsumerState<PostulacionFormScreen> createState() =>
      _PostulacionFormScreenState();
}

class _PostulacionFormScreenState extends ConsumerState<PostulacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _carnetCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _cargando = false;
  PuestoModel? _puesto;

  @override
  void initState() {
    super.initState();
    _loadPuesto();
  }

  Future<void> _loadPuesto() async {
    final doc = await FirebaseFirestore.instance
        .collection('puestos')
        .doc(widget.puestoId)
        .get();
    if (doc.exists && mounted) {
      setState(() => _puesto = PuestoModel.fromFirestore(doc));
    }
  }

  Future<void> _enviarPostulacion() async {
    if (!_formKey.currentState!.validate()) return;

    final nombres = _nombresCtrl.text.trim();
    final apellidos = _apellidosCtrl.text.trim();
    final carnet = _carnetCtrl.text.trim();

    setState(() => _cargando = true);
    try {
      final postulantes = await ref
          .read(firestoreServiceProvider)
          .getPostulantesPorPuestoList(widget.puestoId);

      final nombresLower = nombres.toLowerCase();
      final apellidosLower = apellidos.toLowerCase();
      final carnetNorm = carnet.toUpperCase().trim();

      final yaPostulado = postulantes.any((p) {
        final mismoCarnet =
            p.carnet.trim().toUpperCase() == carnetNorm &&
            carnetNorm.isNotEmpty;
        final mismoNombre =
            p.nombres.trim().toLowerCase() == nombresLower &&
            p.apellidos.trim().toLowerCase() == apellidosLower;
        return mismoCarnet || mismoNombre;
      });

      if (yaPostulado && mounted) {
        setState(() => _cargando = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Ya postulando'),
              ],
            ),
            content: Text(
              'Ya existe una postulación a este puesto con el mismo carnet de identidad o nombre y apellidos. No puedes postularte dos veces.',
              style: GoogleFonts.poppins(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        return;
      }

      final user = ref.read(authStateProvider).value!;

      await ref
          .read(firestoreServiceProvider)
          .crearPostulacion(
            PostulacionModel(
              puestoId: widget.puestoId,
              puestoTitulo: _puesto?.titulo ?? '',
              userId: user.uid,
              nombres: nombres,
              apellidos: apellidos,
              carnet: carnet,
              telefono: _telefonoCtrl.text.trim(),
              cvUrl: '',
              cvFileName: '',
              fechaPostulacion: DateTime.now(),
            ),
          );

      if (mounted) {
        // Mostrar éxito
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SuccessDialog(
            onPressed: () {
              Navigator.pop(context);
              context.pushReplacement('/mis-postulaciones');
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar postulación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulario de Postulación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Puesto info
              if (_puesto != null)
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
                      const Icon(
                        Icons.work_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Postulando a:',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _puesto!.titulo,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 24),

              Text(
                'Datos Personales',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Nombres
              _FieldLabel(label: 'Nombres *'),
              TextFormField(
                controller: _nombresCtrl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ej: Juan Carlos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Apellidos
              _FieldLabel(label: 'Apellidos *'),
              TextFormField(
                controller: _apellidosCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ej: Mamani García',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Carnet
              _FieldLabel(label: 'Carnet de Identidad con Extencion*'),
              TextFormField(
                controller: _carnetCtrl,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Ej: 1234567 TJA',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Teléfono
              _FieldLabel(label: 'Celular *'),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Ej: 71234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  if (v.trim().length < 7) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              if (_cargando)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF1A73E8)),
                      const SizedBox(height: 12),
                      Text(
                        'Enviando postulación...',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // Botón enviar
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _cargando ? null : _enviarPostulacion,
                  icon: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_cargando ? 'Enviando...' : 'Enviar Postulación'),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _carnetCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          // bodyLarge hereda el color de texto principal del tema
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onPressed;
  const _SuccessDialog({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: Color(0xFF34A853),
              ),
            ).animate().scale(duration: 500.ms),
            const SizedBox(height: 20),
            Text(
              '¡Postulación Enviada!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu postulación fue registrada correctamente. Podrás verificar tu nombre en la lista del puesto.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
              ),
              child: const Text('Ver mis postulaciones'),
            ),
          ],
        ),
      ),
    );
  }
}
