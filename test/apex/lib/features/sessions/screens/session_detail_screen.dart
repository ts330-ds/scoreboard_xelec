import 'package:flutter/material.dart';
import '../../../data/repositories/session_repository.dart';
class SessionDetailScreen extends StatelessWidget {
  final String sessionId;
  final SessionRepository repository;
  const SessionDetailScreen({super.key, required this.sessionId, required this.repository});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Session Detail')));
}
