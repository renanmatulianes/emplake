import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

/// Overridden in main() with the instance loaded before runApp.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

const fonts = ['Roboto', 'EB Garamond', 'Arimo', 'Inter', 'Lato', 'Montserrat', 'Merriweather', 'Source Code Pro'];

const seeds = [
  Color(0xFF0D47A1), Color(0xFF00897B), Color(0xFF2E7D32), Color(0xFFF9A825), //
  Color(0xFFE65100), Color(0xFFC62828), Color(0xFFAD1457), Color(0xFF6A1B9A),
  Color(0xFF455A64), Color(0xFF5D4037),
];

typedef Preset = ({String Function(AppLocalizations) name, Color seed, String font});

final List<Preset> presets = [
  (name: (l) => l.presetPlate, seed: const Color(0xFF0D47A1), font: 'Roboto'),
  (name: (l) => l.presetForest, seed: const Color(0xFF2E7D32), font: 'Merriweather'),
  (name: (l) => l.presetSunset, seed: const Color(0xFFE65100), font: 'Montserrat'),
  (name: (l) => l.presetGrape, seed: const Color(0xFF6A1B9A), font: 'Lato'),
  (name: (l) => l.presetTerminal, seed: const Color(0xFF00897B), font: 'Source Code Pro'),
];

class AppSettings {
  const AppSettings({
    this.mode = ThemeMode.system,
    this.textScale = 1,
    this.font = 'Roboto',
    this.seed = const Color(0xFF0D47A1),
    this.locale,
    this.sound = false,
  });

  final ThemeMode mode;
  final double textScale;
  final String font;
  final Color seed;
  final Locale? locale; // null = device language
  final bool sound;

  AppSettings copyWith({ThemeMode? mode, double? textScale, String? font, Color? seed, Locale? locale, bool? sound}) =>
      AppSettings(
        mode: mode ?? this.mode,
        textScale: textScale ?? this.textScale,
        font: font ?? this.font,
        seed: seed ?? this.seed,
        locale: locale ?? this.locale,
        sound: sound ?? this.sound,
      );

  ThemeData theme(Brightness b) {
    final base = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: b));
    return base.copyWith(textTheme: GoogleFonts.getTextTheme(font, base.textTheme));
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  AppSettings build() {
    final lang = _p.getString('locale');
    return AppSettings(
      mode: ThemeMode.values.asNameMap()[_p.getString('mode')] ?? ThemeMode.system,
      textScale: _p.getDouble('textScale') ?? 1,
      font: _p.getString('font') ?? 'Roboto',
      seed: Color(_p.getInt('seed') ?? 0xFF0D47A1),
      locale: lang == null ? null : Locale(lang),
      sound: _p.getBool('sound') ?? false,
    );
  }

  void set(AppSettings s) {
    state = s;
    _p.setString('mode', s.mode.name);
    _p.setDouble('textScale', s.textScale);
    _p.setString('font', s.font);
    _p.setInt('seed', s.seed.toARGB32());
    _p.setBool('sound', s.sound);
    if (s.locale != null) _p.setString('locale', s.locale!.languageCode);
  }
}

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = Localizations.localeOf(context).languageCode;
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        for (final (code, flag, name) in const [('pt', '🇧🇷', 'Português'), ('en', '🇺🇸', 'English')])
          ButtonSegment(
            value: code,
            // The flag uses an explicit emoji font (some text fonts draw it as boxed
            // letters) inside a fixed box: that font loads late on the web,
            // and a width measured before that would wrap the label.
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 24, height: 20, child: FittedBox(child: Text(flag, style: GoogleFonts.notoColorEmoji()))),
              const SizedBox(width: 6),
              Text(name, softWrap: false),
            ]),
          ),
      ],
      selected: {current},
      onSelectionChanged: (v) {
        final c = ref.read(settingsProvider.notifier);
        c.set(ref.read(settingsProvider).copyWith(locale: Locale(v.first)));
      },
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;
    void set(AppSettings v) => ref.read(settingsProvider.notifier).set(v);
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(t, style: Theme.of(context).textTheme.titleMedium),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Text(l.settingsTitle, style: Theme.of(context).textTheme.headlineMedium),
        title(l.themeMode),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto), label: Text(l.themeSystem)),
            ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode), label: Text(l.themeLight)),
            ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode), label: Text(l.themeDark)),
          ],
          selected: {s.mode},
          onSelectionChanged: (v) => set(s.copyWith(mode: v.first)),
        ),
        title(l.presets),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in presets)
            ActionChip(
              avatar: CircleAvatar(backgroundColor: p.seed),
              label: Text(p.name(l), style: GoogleFonts.getFont(p.font)),
              onPressed: () => set(s.copyWith(seed: p.seed, font: p.font)),
            ),
        ]),
        title(l.seedColor),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final c in seeds)
            Semantics(
              button: true,
              selected: c == s.seed,
              label: '${l.seedColor} #${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => set(s.copyWith(seed: c)),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: c,
                  child: c == s.seed ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ),
            ),
        ]),
        title(l.fontFamily),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in fonts)
            ChoiceChip(
              label: Text(f, style: GoogleFonts.getFont(f)),
              selected: f == s.font,
              onSelected: (_) => set(s.copyWith(font: f)),
            ),
        ]),
        title('${l.fontSize} (${(s.textScale * 100).round()}%)'),
        Slider(
          value: s.textScale,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: '${(s.textScale * 100).round()}%',
          onChanged: (v) => set(s.copyWith(textScale: v)),
        ),
        title(l.language),
        const Align(alignment: Alignment.centerLeft, child: LanguagePicker()),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(s.sound ? Icons.volume_up : Icons.volume_off),
          title: Text(l.sound),
          subtitle: Text(l.soundHint),
          value: s.sound,
          onChanged: (v) => set(s.copyWith(sound: v)),
        ),
        title(l.account),
        Text(l.signedInAs(FirebaseAuth.instance.currentUser?.email ?? '')),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(foregroundColor: cs.error),
            icon: const Icon(Icons.logout),
            label: Text(l.signOut),
            onPressed: () => FirebaseUIAuth.signOut(context: context),
          ),
        ),
      ],
    );
  }
}
