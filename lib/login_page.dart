import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'settings.dart';

const groupMembers = ['Renan Matulianes Arnaldo', 'João Augusto Luvizotto'];

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SignInScreen(
      // The client ID is only read by the native google_sign_in flow; on the web,
      // the delivered platform, Firebase opens its own popup and ignores it.
      providers: [EmailAuthProvider(), GoogleProvider(clientId: '')],
      showPasswordVisibilityToggle: true,
      headerMaxExtent: 200,
      headerBuilder: (context, constraints, _) => const Center(child: _Logo()),
      sideBuilder: (context, constraints) => const Center(child: _Logo()),
      subtitleBuilder: (context, action) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.tagline, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(l.language, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          const LanguagePicker(),
        ]),
      ),
      footerBuilder: (context, action) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.groupMembers, style: Theme.of(context).textTheme.titleSmall),
          for (final m in groupMembers) Text('• $m'),
        ]),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Container(
      width: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: double.infinity,
          color: cs.primary,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(l.plateRegion,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onPrimary, letterSpacing: 3, fontWeight: FontWeight.w700)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('3MPL4K3',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 4)),
        ),
      ]),
    );
  }
}
