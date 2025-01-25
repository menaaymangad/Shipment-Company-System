class FormStateService {
  static final Map<String, Map<String, dynamic>> _states = {};

  static void saveFormState(String screenId, Map<String, dynamic> state) {
    _states[screenId] = state;
  }

  static Map<String, dynamic>? getFormState(String screenId) {
    return _states[screenId];
  }

  static void clearFormState(String screenId) {
    _states.remove(screenId);
  }
}
