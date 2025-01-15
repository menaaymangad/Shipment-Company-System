import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/pages/reports_pages/main_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});
static String id='ReportPage';
  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    if (authCubit.isUser() ) {
      return const Center(
        child: Text('You are not authorized to access the Report page.'),
      );
    }
    return const MainScreen();
  }
}