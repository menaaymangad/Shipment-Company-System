// theme_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppTheme { light, dark }

class ThemeCubit extends Cubit<AppTheme> {
  ThemeCubit() : super(AppTheme.light);
    

  void toggleTheme() {
    emit(state == AppTheme.light ? AppTheme.dark : AppTheme.light);
  }
}
class SendThemeCubit extends Cubit<bool> {
  SendThemeCubit() : super(false); // false = light, true = dark

  void toggleTheme() => emit(!state);
}
