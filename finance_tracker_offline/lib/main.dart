import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbService = DbService();
  await dbService.init();

  runApp(
    ProviderScope(
      overrides: [
        dbServiceProvider.overrideWithValue(dbService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Finance Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

