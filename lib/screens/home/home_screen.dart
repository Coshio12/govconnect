import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/puesto_model.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialLoading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Cooldown de 3 segundos al entrar al home
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final puestosAsync = ref.watch(puestosActivosProvider);
    final usuarioAsync = ref.watch(currentUserProvider);
    final isMasterAsync = ref.watch(isMasterProvider);

    // Pantalla de carga inicial
    if (_isInitialLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono animado
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Image(
                      image: const AssetImage('assets/images/gov.png'),
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(
                        begin: 0.95,
                        end: 1.05,
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scaleXY(
                        begin: 1.05,
                        end: 0.95,
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      ),

                  const SizedBox(height: 32),

                  Text(
                    'Cargando puestos...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Por favor espera un momento',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),

                  // Barra de progreso animada
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.white24,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Pantalla principal (después del cooldown)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puestos Disponibles'),
        actions: [
          // Botón "Mis postulaciones"
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Mis postulaciones',
            onPressed: () => context.push('/mis-postulaciones'),
          ),
          // Avatar con menú
          usuarioAsync.when(
            data: (usuario) => PopupMenuButton(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: usuario?.foto != null
                      ? NetworkImage(usuario!.foto!)
                      : null,
                  backgroundColor: Colors.white24,
                  child: usuario?.foto == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              itemBuilder: (_) => [
                if (isMasterAsync.value == true)
                  PopupMenuItem(
                    value: 'master',
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined,
                            color: Color(0xFF1A73E8)),
                        const SizedBox(width: 8),
                        Text('Panel Master', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Cerrar sesión',
                          style: GoogleFonts.poppins(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (val) async {
                if (val == 'master') context.push('/master');
                if (val == 'logout') {
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
                        '¿Seguro que deseas cerrar sesión?\nSe cerrará la aplicación.',
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
                              style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authServiceProvider).signOut();
                    SystemNavigator.pop();
                  }
                }
              },
            ),
            loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
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

          // Lista de puestos
          Expanded(
            child: puestosAsync.when(
              data: (puestos) {
                final filtrados = _query.isEmpty
                    ? puestos
                    : puestos.where((p) =>
                        p.titulo.toLowerCase().contains(_query) ||
                        p.dependencia.toLowerCase().contains(_query)).toList();
                if (filtrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.work_off_outlined,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No hay puestos disponibles',
                            style: GoogleFonts.poppins(
                                fontSize: 18, color: Colors.grey)),
                        Text('Vuelve pronto',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey[400])),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(puestosActivosProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: filtrados.length,
                    itemBuilder: (ctx, i) => _PuestoCard(puesto: filtrados[i])
                        .animate()
                        .fadeIn(delay: (i * 80).ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                );
              },
              loading: () => _ShimmerList(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _PuestoCard extends StatelessWidget {
  final PuestoModel puesto;
  const _PuestoCard({required this.puesto});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final vigente = puesto.isVigente;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/puesto/${puesto.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.work_outline_rounded,
                        color: Color(0xFF1A73E8), size: 28),
                  ),
                  const SizedBox(width: 12),
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
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vigente
                          ? const Color(0xFF34A853).withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vigente ? 'Activo' : 'Cerrado',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: vigente ? const Color(0xFF34A853) : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                puesto.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                children: [
                  _InfoChip(
                    icon: Icons.people_outline,
                    label: '${puesto.vacantes} vacante(s)',
                  ),
                ],
              ),
              if (puesto.fechaExamen != null) ...[
                const SizedBox(height: 8),
                _InfoChip(
                  icon: Icons.event_outlined,
                  label: 'Examen: ${fmt.format(puesto.fechaExamen!)}',
                  color: const Color(0xFF34A853),
                ),
              ],
              if (vigente) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/postular/${puesto.id}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: GoogleFonts.poppins(fontSize: 13),
                    ),
                    child: const Text('Postularme'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}