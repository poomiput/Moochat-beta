import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/widgets/app_shell.dart';

/// Redesigned main screen using the new app shell architecture
class RedesignedMainScreen extends ConsumerWidget {
  const RedesignedMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppShell();
  }
}
