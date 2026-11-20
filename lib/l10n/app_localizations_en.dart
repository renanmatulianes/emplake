// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Emplake';

  @override
  String get tagline => 'Turn license plates into equations';

  @override
  String get groupMembers => 'Group members';

  @override
  String get language => 'Language';

  @override
  String get navGame => 'Play';

  @override
  String get navHistory => 'Solved';

  @override
  String get navHelp => 'Help';

  @override
  String get navSettings => 'Settings';

  @override
  String get levelEasy => 'Easy';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelHard => 'Hard';

  @override
  String score(int points) {
    return 'Score: $points';
  }

  @override
  String get plateRegion => 'MERCOSUL · BRAZIL';

  @override
  String slotLabel(int n) {
    return 'Slot $n';
  }

  @override
  String get selectSlotHint =>
      'Tap a “_” mark, then tap operators to insert them there.';

  @override
  String get preview => 'Rendered formula';

  @override
  String sides(String left, String right) {
    return 'Left = $left   ·   Right = $right';
  }

  @override
  String get verify => 'Check';

  @override
  String get skip => 'Skip number';

  @override
  String get clear => 'Clear';

  @override
  String get undo => 'Remove last operator of the slot';

  @override
  String get prevSlot => 'Previous slot';

  @override
  String get nextSlot => 'Next slot';

  @override
  String correct(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points points',
      one: '+1 point',
    );
    return 'Correct! $_temp0';
  }

  @override
  String wrong(String left, String right) {
    return 'Not equal: $left ≠ $right';
  }

  @override
  String get allSolved => 'You solved every number at this level!';

  @override
  String get loading => 'Loading…';

  @override
  String loadError(String error) {
    return 'Could not load your data: $error';
  }

  @override
  String saveError(String error) {
    return 'Could not save your answer: $error';
  }

  @override
  String get retry => 'Try again';

  @override
  String get cloudOffline =>
      'no internet connection, or the server did not answer.';

  @override
  String get cloudDenied => 'access denied. Sign out and sign in again.';

  @override
  String get cloudUnknown => 'unexpected error.';

  @override
  String errUnexpected(String token) {
    return 'Unexpected symbol “$token”.';
  }

  @override
  String get errIncomplete => 'The expression is incomplete.';

  @override
  String errUnclosed(String token) {
    return 'Missing closing “$token”.';
  }

  @override
  String get errEquals => 'The equation needs exactly one “=”.';

  @override
  String get errEmptySide => 'Both sides of “=” need an expression.';

  @override
  String get errDivZero => 'Division by zero.';

  @override
  String get errNonInteger =>
      'Non-integer division is only allowed at the Easy level.';

  @override
  String get errFactorial => 'Factorial needs a whole number between 0 and 18.';

  @override
  String get errSqrtNegative => 'Square root of a negative number.';

  @override
  String get errPower => 'Invalid power.';

  @override
  String get errTooBig => 'The result is too big.';

  @override
  String errNotAllowed(String token) {
    return '“$token” is not available at this level.';
  }

  @override
  String cantPlace(String token) {
    return '“$token” cannot go where the cursor is.';
  }

  @override
  String get opPlus => 'Addition';

  @override
  String get opMinus => 'Subtraction or negative sign';

  @override
  String get opTimes => 'Multiplication';

  @override
  String get opDivide => 'Division';

  @override
  String get opLParen => 'Open parenthesis';

  @override
  String get opRParen => 'Close parenthesis';

  @override
  String get opSqrt => 'Square root';

  @override
  String get opCbrt => 'Cube root';

  @override
  String get opFact => 'Factorial';

  @override
  String get opPow => 'Exponentiation (**)';

  @override
  String get opAbs => 'Absolute value |x| (opens and closes)';

  @override
  String get opFloorL => 'Floor ⌊x⌋: open';

  @override
  String get opFloorR => 'Floor ⌊x⌋: close';

  @override
  String get opCeilL => 'Ceiling ⌈x⌉: open';

  @override
  String get opCeilR => 'Ceiling ⌈x⌉: close';

  @override
  String get opEquals => 'Move the equals sign to the selected “_”';

  @override
  String get equalsTip =>
      'Drag the = sign to a “_”, or tap it and then tap a “_”';

  @override
  String get moveEqualsHint => 'Now tap the “_” where the = sign should go.';

  @override
  String get historyTitle => 'Solved numbers';

  @override
  String get historyEmpty => 'No solved numbers at this level yet.';

  @override
  String totalScore(int points) {
    return 'Total score: $points';
  }

  @override
  String solvedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solved',
      one: '1 solved',
      zero: 'none solved',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontFamily => 'Font';

  @override
  String get seedColor => 'Seed color';

  @override
  String get presets => 'Ready-made themes';

  @override
  String get presetPlate => 'Mercosul plate';

  @override
  String get presetForest => 'Forest';

  @override
  String get presetSunset => 'Sunset';

  @override
  String get presetGrape => 'Grape';

  @override
  String get presetTerminal => 'Terminal';

  @override
  String get sound => 'Sound effects';

  @override
  String get soundHint => 'Off by default';

  @override
  String get account => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get helpTitle => 'How to play';

  @override
  String get helpBody =>
      'A four-digit plate number appears. Keep the digits in their order and insert operators around them so that the equation becomes true. Digits with nothing between them form a single number (4 and 1 make 41).\n\nEvery “_” mark is a place where symbols can go: before, between and after the digits, and on both sides of the = sign. Tap a “_” to select it, then tap operators to insert them there. Whenever another symbol still fits after the ones you placed, a new “_” shows up, so you can chain symbols such as √( or )!; impossible combinations such as ++ are refused. To type a symbol between two others, tap one of them (or use the arrow keys): the cursor moves next to it and the new symbol goes exactly there. The backspace key removes the symbol right before the cursor. The = sign is always on the plate: to move it, drag it to another “_”, or tap it and then tap a “_”, or select a “_” and press the = key.\n\nTap Check to validate your answer. Correct answers score points (Easy 1, Intermediate 2, Advanced 3, Hard 4) and that number never shows up again at that level. Only plates that have a solution are dealt. Stuck? Skip the number.';

  @override
  String get helpExample => 'Example with 8131:';

  @override
  String get helpOperators => 'Operators per level';

  @override
  String get close => 'Close';

  @override
  String tourStep(int n, int total) {
    return '$n of $total';
  }

  @override
  String get tourSkip => 'Skip tour';

  @override
  String get tourBack => 'Back';

  @override
  String get tourNext => 'Next';

  @override
  String get tourDone => 'Start playing';

  @override
  String get tourReplay => 'Show the tour';

  @override
  String get tourDisplayTitle => 'The display';

  @override
  String get tourDisplayBody =>
      'The four digits of the plate are here, in the order you must keep. Above them are the level and your score. The bottom line tells you how much each side of the equation is worth, or what is wrong with it.';

  @override
  String get tourMarksTitle => 'Where symbols go';

  @override
  String get tourMarksBody =>
      'Each “_” is a place for symbols. Tap one to select it (it blinks), then tap operators. When another symbol still fits, a new “_” appears beside it. To type between two symbols, tap one of them.';

  @override
  String get tourEqualsTitle => 'The = sign';

  @override
  String get tourEqualsBody =>
      'It splits the plate into the two sides of the equation. To change where the plate is split, drag it to another “_”, or tap it and then tap a “_”.';

  @override
  String get tourFormulaTitle => 'Rendered formula';

  @override
  String get tourFormulaBody =>
      'As you type, your equation is drawn here in mathematical notation, with roots, fractions and exponents, so you can check that it means what you intended.';

  @override
  String get tourLevelTitle => 'Level';

  @override
  String get tourLevelBody =>
      'Tap or slide to choose a level. Harder levels have fewer operators and are worth more points: Easy 1, Intermediate 2, Advanced 3, Hard 4.';

  @override
  String get tourOperatorsTitle => 'Operators';

  @override
  String get tourOperatorsBody =>
      'Tap an operator to insert it where the cursor is. The keys change with the level. Rest the pointer on a key, or long-press it, to see its name.';

  @override
  String get tourEditTitle => 'Moving and erasing';

  @override
  String get tourEditBody =>
      'The arrows move the cursor through every place a symbol can go. The backspace key removes the symbol before the cursor, and Clear removes them all.';

  @override
  String get tourSkipTitle => 'Skip number';

  @override
  String get tourSkipBody =>
      'Stuck? Skip to another plate. Every plate you get has at least one solution.';

  @override
  String get tourVerifyTitle => 'Check';

  @override
  String get tourVerifyBody =>
      'When both sides are equal, tap Check. A right answer scores and brings a new plate. A wrong one shows why and leaves your symbols in place, so you can keep trying.';

  @override
  String get tourMenuTitle => 'Menu';

  @override
  String get tourMenuBody =>
      'Play, the plates you have solved, help (where you can see this tour again) and settings: theme, colors, font, language and sound.';
}
