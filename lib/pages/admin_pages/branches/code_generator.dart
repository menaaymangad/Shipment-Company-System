class CodeGenerator {
  static String generateCode({
    required String characterPrefix,
    required String yearPrefix,
    required String numberOfDigits,
    required int currentSequence,
  }) {
    final formattedCharPrefix = characterPrefix.length >= 2
        ? characterPrefix.substring(0, 2).toUpperCase()
        : characterPrefix.padRight(2, 'X').toUpperCase();

    final formattedYearPrefix = yearPrefix.length >= 2
        ? yearPrefix.substring(yearPrefix.length - 2)
        : DateTime.now().year.toString().substring(2);

    int digits;
    try {
      digits = int.parse(numberOfDigits);
      if (digits > 7) digits = 7;
      if (digits < 1) digits = 1;
    } catch (e) {
      digits = 7;
    }

    final sequenceNumber = currentSequence.toString().padLeft(digits, '0');
    return '$formattedCharPrefix-$formattedYearPrefix$sequenceNumber';
  }

  static Map<String, String?> validateFields({
    required String characterPrefix,
    required String yearPrefix,
    required String numberOfDigits,
  }) {
    Map<String, String?> errors = {};

    if (characterPrefix.isEmpty) {
      errors['characterPrefix'] = 'Character prefix is required';
    }

    if (yearPrefix.isEmpty) {
      errors['yearPrefix'] = 'Year prefix is required';
    } else {
      try {
        int year = int.parse(yearPrefix);
        if (year < 0) {
          errors['yearPrefix'] = 'Please enter a valid year';
        }
      } catch (e) {
        errors['yearPrefix'] = 'Please enter a valid year';
      }
    }

    if (numberOfDigits.isEmpty) {
      errors['numberOfDigits'] = 'Number of digits is required';
    } else {
      try {
        int digits = int.parse(numberOfDigits);
        if (digits < 1 || digits > 7) {
          errors['numberOfDigits'] = 'Number of digits must be between 1 and 7';
        }
      } catch (e) {
        errors['numberOfDigits'] = 'Please enter a valid number';
      }
    }

    return errors;
  }
}
