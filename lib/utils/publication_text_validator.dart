String? validatePublicationText(String? value, {required String fieldName}) {
  final invalidMessage = fieldName.toLowerCase().contains('descrip')
      ? 'Ingresa una descripción válida'
      : 'Ingresa un título real';
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Completa $fieldName';
  }

  final normalized = text.toLowerCase();
  final letterMatches = RegExp(
    r'[a-záéíóúüñ]',
    caseSensitive: false,
  ).allMatches(normalized);
  final letters = letterMatches.map((match) => match.group(0)!).join();

  if (letters.length < 3) {
    return invalidMessage;
  }

  final hasLongRepeatedLetter = RegExp(
    r'([a-záéíóúüñ])\1{3,}',
    caseSensitive: false,
  ).hasMatch(normalized);
  if (hasLongRepeatedLetter) {
    return invalidMessage;
  }

  final uniqueLetters = letters.split('').toSet().length;
  if (letters.length >= 6 && uniqueLetters <= 2) {
    return invalidMessage;
  }

  final vowelCount = RegExp(
    r'[aeiouáéíóúü]',
    caseSensitive: false,
  ).allMatches(letters).length;

  if (letters.length >= 8 && vowelCount < 2) {
    return invalidMessage;
  }

  final hasLongConsonantRun = RegExp(
    r'[bcdfghjklmnpqrstvwxyzñ]{6,}',
    caseSensitive: false,
  ).hasMatch(normalized);
  if (hasLongConsonantRun) {
    return invalidMessage;
  }

  final words = RegExp(
    r'[a-záéíóúüñ]{4,}',
    caseSensitive: false,
  ).allMatches(normalized).map((match) => match.group(0)!).toList();
  final wordsWithoutVowels = words
      .where((word) => !RegExp(
            r'[aeiouáéíóúü]',
            caseSensitive: false,
          ).hasMatch(word))
      .length;

  if (words.length >= 2 && wordsWithoutVowels >= 2) {
    return invalidMessage;
  }

  return null;
}
