import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goRouterProvider = Provider<GoRouter>((ref) => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Center(child: Text('Home')))),
    // TODO: Add routes for cashbooks, transactions, backup_center, settings as per spec
  ],
));
