import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/puesto_detalle/puesto_detalle_screen.dart';
import '../../screens/postulacion/postulacion_form_screen.dart';
import '../../screens/mis_postulaciones/mis_postulaciones_screen.dart';
import '../../screens/master/master_dashboard_screen.dart';
import '../../screens/master/gestionar_puestos_screen.dart';
import '../../screens/master/postulantes_list_screen.dart';

/// Después de este tiempo en splash, forzamos ir a login si auth sigue "loading".
const _splashTimeout = Duration(seconds: 3);

final splashTimeoutProvider = FutureProvider<void>((ref) {
  return Future.delayed(_splashTimeout);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final splashTimeout = ref.watch(splashTimeoutProvider);
  final authStream = ref.read(authServiceProvider).authStateChanges;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final timeoutPassed = splashTimeout.hasValue;
      final isLoading = authState.isLoading && !timeoutPassed;
      if (isLoading) return '/splash';

      final isLoggedIn = authState.value != null;
      final loc = state.matchedLocation;

      // Si pasó el timeout y seguimos en splash sin sesión → ir a login
      if (timeoutPassed && loc == '/splash' && !isLoggedIn) {
        return '/login';
      }
      if (!isLoggedIn && loc != '/login' && loc != '/splash') {
        return '/login';
      }
      if (isLoggedIn && (loc == '/login' || loc == '/splash')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/puesto/:id',
        builder: (context, state) =>
            PuestoDetalleScreen(puestoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/postular/:id',
        builder: (context, state) =>
            PostulacionFormScreen(puestoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/mis-postulaciones',
        builder: (context, state) => const MisPostulacionesScreen(),
      ),
      // Rutas Master
      GoRoute(
        path: '/master',
        builder: (context, state) => const MasterDashboardScreen(),
      ),
      GoRoute(
        path: '/master/puestos',
        builder: (context, state) => const GestionarPuestosScreen(),
      ),
      GoRoute(
        path: '/master/postulantes/:puestoId',
        builder: (context, state) => PostulantesListScreen(
            puestoId: state.pathParameters['puestoId']!,
            puestoTitulo: state.uri.queryParameters['titulo'] ?? ''),
      ),
    ],
  );
});

// Helper para refrescar GoRouter cuando cambia el estado de auth
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
