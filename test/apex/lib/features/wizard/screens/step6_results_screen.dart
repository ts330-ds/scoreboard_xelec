import 'package:flutter/material.dart';
import '../../../data/repositories/session_repository.dart';
class Step6ResultsScreen extends StatelessWidget {
  final SessionRepository repository;
  const Step6ResultsScreen({super.key, required this.repository});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Results')));
}
