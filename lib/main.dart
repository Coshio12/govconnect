import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'firebase_init.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException('Firebase init'),
    );
    firebaseInitialized = true;
  } catch (e, st) {
    debugPrint('Firebase init error: $e');
    debugPrint('$st');
    firebaseInitialized = false;
  }

  // ── Supabase ──────────────────────────────────────────────
  // Reemplaza los valores con los de tu proyecto en https://supabase.com
  await Supabase.initialize(
    url: 'https://owvsiwnkimhrbxzqfzsl.supabase.co',          // 👈 cambia esto
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93dnNpd25raW1ocmJ4enFmenNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzMzAxODksImV4cCI6MjA4NzkwNjE4OX0.SSAG4FsQwewiK2ujrvugxNWhdk1ipYR47qcwm4hVg9Q',                             // 👈 cambia esto
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'GovConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}