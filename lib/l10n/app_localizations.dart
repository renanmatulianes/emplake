import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Emplake'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Turn license plates into equations'**
  String get tagline;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group members'**
  String get groupMembers;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @navGame.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navGame;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get navHistory;

  /// No description provided for @navHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get navHelp;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @levelEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get levelEasy;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get levelHard;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score: {points}'**
  String score(int points);

  /// No description provided for @plateRegion.
  ///
  /// In en, this message translates to:
  /// **'MERCOSUL · BRAZIL'**
  String get plateRegion;

  /// No description provided for @slotLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot {n}'**
  String slotLabel(int n);

  /// No description provided for @selectSlotHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a “_” mark, then tap operators to insert them there.'**
  String get selectSlotHint;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Rendered formula'**
  String get preview;

  /// No description provided for @sides.
  ///
  /// In en, this message translates to:
  /// **'Left = {left}   ·   Right = {right}'**
  String sides(String left, String right);

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get verify;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip number'**
  String get skip;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Remove last operator of the slot'**
  String get undo;

  /// No description provided for @prevSlot.
  ///
  /// In en, this message translates to:
  /// **'Previous slot'**
  String get prevSlot;

  /// No description provided for @nextSlot.
  ///
  /// In en, this message translates to:
  /// **'Next slot'**
  String get nextSlot;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct! {points, plural, =1{+1 point} other{+{points} points}}'**
  String correct(int points);

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Not equal: {left} ≠ {right}'**
  String wrong(String left, String right);

  /// No description provided for @allSolved.
  ///
  /// In en, this message translates to:
  /// **'You solved every number at this level!'**
  String get allSolved;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your data: {error}'**
  String loadError(String error);

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your answer: {error}'**
  String saveError(String error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cloudOffline.
  ///
  /// In en, this message translates to:
  /// **'no internet connection, or the server did not answer.'**
  String get cloudOffline;

  /// No description provided for @cloudDenied.
  ///
  /// In en, this message translates to:
  /// **'access denied. Sign out and sign in again.'**
  String get cloudDenied;

  /// No description provided for @cloudUnknown.
  ///
  /// In en, this message translates to:
  /// **'unexpected error.'**
  String get cloudUnknown;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected symbol “{token}”.'**
  String errUnexpected(String token);

  /// No description provided for @errIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The expression is incomplete.'**
  String get errIncomplete;

  /// No description provided for @errUnclosed.
  ///
  /// In en, this message translates to:
  /// **'Missing closing “{token}”.'**
  String errUnclosed(String token);

  /// No description provided for @errEquals.
  ///
  /// In en, this message translates to:
  /// **'The equation needs exactly one “=”.'**
  String get errEquals;

  /// No description provided for @errEmptySide.
  ///
  /// In en, this message translates to:
  /// **'Both sides of “=” need an expression.'**
  String get errEmptySide;

  /// No description provided for @errDivZero.
  ///
  /// In en, this message translates to:
  /// **'Division by zero.'**
  String get errDivZero;

  /// No description provided for @errNonInteger.
  ///
  /// In en, this message translates to:
  /// **'Non-integer division is only allowed at the Easy level.'**
  String get errNonInteger;

  /// No description provided for @errFactorial.
  ///
  /// In en, this message translates to:
  /// **'Factorial needs a whole number between 0 and 18.'**
  String get errFactorial;

  /// No description provided for @errSqrtNegative.
  ///
  /// In en, this message translates to:
  /// **'Square root of a negative number.'**
  String get errSqrtNegative;

  /// No description provided for @errPower.
  ///
  /// In en, this message translates to:
  /// **'Invalid power.'**
  String get errPower;

  /// No description provided for @errTooBig.
  ///
  /// In en, this message translates to:
  /// **'The result is too big.'**
  String get errTooBig;

  /// No description provided for @errNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'“{token}” is not available at this level.'**
  String errNotAllowed(String token);

  /// No description provided for @cantPlace.
  ///
  /// In en, this message translates to:
  /// **'“{token}” cannot go in slot {slot} here.'**
  String cantPlace(String token, int slot);

  /// No description provided for @opPlus.
  ///
  /// In en, this message translates to:
  /// **'Addition'**
  String get opPlus;

  /// No description provided for @opMinus.
  ///
  /// In en, this message translates to:
  /// **'Subtraction or negative sign'**
  String get opMinus;

  /// No description provided for @opTimes.
  ///
  /// In en, this message translates to:
  /// **'Multiplication'**
  String get opTimes;

  /// No description provided for @opDivide.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get opDivide;

  /// No description provided for @opLParen.
  ///
  /// In en, this message translates to:
  /// **'Open parenthesis'**
  String get opLParen;

  /// No description provided for @opRParen.
  ///
  /// In en, this message translates to:
  /// **'Close parenthesis'**
  String get opRParen;

  /// No description provided for @opSqrt.
  ///
  /// In en, this message translates to:
  /// **'Square root'**
  String get opSqrt;

  /// No description provided for @opCbrt.
  ///
  /// In en, this message translates to:
  /// **'Cube root'**
  String get opCbrt;

  /// No description provided for @opFact.
  ///
  /// In en, this message translates to:
  /// **'Factorial'**
  String get opFact;

  /// No description provided for @opPow.
  ///
  /// In en, this message translates to:
  /// **'Exponentiation (**)'**
  String get opPow;

  /// No description provided for @opAbs.
  ///
  /// In en, this message translates to:
  /// **'Absolute value |x| (opens and closes)'**
  String get opAbs;

  /// No description provided for @opFloorL.
  ///
  /// In en, this message translates to:
  /// **'Floor ⌊x⌋: open'**
  String get opFloorL;

  /// No description provided for @opFloorR.
  ///
  /// In en, this message translates to:
  /// **'Floor ⌊x⌋: close'**
  String get opFloorR;

  /// No description provided for @opCeilL.
  ///
  /// In en, this message translates to:
  /// **'Ceiling ⌈x⌉: open'**
  String get opCeilL;

  /// No description provided for @opCeilR.
  ///
  /// In en, this message translates to:
  /// **'Ceiling ⌈x⌉: close'**
  String get opCeilR;

  /// No description provided for @opEquals.
  ///
  /// In en, this message translates to:
  /// **'Move the equals sign to the selected “_”'**
  String get opEquals;

  /// No description provided for @equalsTip.
  ///
  /// In en, this message translates to:
  /// **'Drag the = sign to a “_”, or tap it and then tap a “_”'**
  String get equalsTip;

  /// No description provided for @moveEqualsHint.
  ///
  /// In en, this message translates to:
  /// **'Now tap the “_” where the = sign should go.'**
  String get moveEqualsHint;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Solved numbers'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No solved numbers at this level yet.'**
  String get historyEmpty;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total score: {points}'**
  String totalScore(int points);

  /// No description provided for @solvedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{none solved} =1{1 solved} other{{count} solved}}'**
  String solvedCount(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontFamily;

  /// No description provided for @seedColor.
  ///
  /// In en, this message translates to:
  /// **'Seed color'**
  String get seedColor;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Ready-made themes'**
  String get presets;

  /// No description provided for @presetPlate.
  ///
  /// In en, this message translates to:
  /// **'Mercosul plate'**
  String get presetPlate;

  /// No description provided for @presetForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get presetForest;

  /// No description provided for @presetSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get presetSunset;

  /// No description provided for @presetGrape.
  ///
  /// In en, this message translates to:
  /// **'Grape'**
  String get presetGrape;

  /// No description provided for @presetTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get presetTerminal;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get sound;

  /// No description provided for @soundHint.
  ///
  /// In en, this message translates to:
  /// **'Off by default'**
  String get soundHint;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get helpTitle;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'A four-digit plate number appears. Keep the digits in their order and insert operators around them so that the equation becomes true. Digits with nothing between them form a single number (4 and 1 make 41).\n\nEvery “_” mark is a place where symbols can go: before, between and after the digits, and on both sides of the = sign. Tap a “_” to select it, then tap operators to insert them there. Whenever another symbol still fits after the ones you placed, a new “_” shows up, so you can chain symbols such as √( or )!; impossible combinations such as ++ are refused. The backspace key removes the last symbol next to the selected “_”. The = sign is always on the plate: to move it, drag it to another “_”, or tap it and then tap a “_”, or select a “_” and press the = key.\n\nTap Check to validate your answer. Correct answers score points (Easy 1, Intermediate 2, Advanced 3, Hard 4) and that number never shows up again at that level. Only plates that have a solution are dealt. Stuck? Skip the number.'**
  String get helpBody;

  /// No description provided for @helpExample.
  ///
  /// In en, this message translates to:
  /// **'Example with 8131:'**
  String get helpExample;

  /// No description provided for @helpOperators.
  ///
  /// In en, this message translates to:
  /// **'Operators per level'**
  String get helpOperators;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
