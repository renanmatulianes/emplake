import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'game.dart';
import 'history_page.dart';
import 'l10n/app_localizations.dart';
import 'login_page.dart';
import 'math_engine.dart';
import 'settings.dart';

const _tabs = ['/game', '/history', null, '/settings']; // null = help dialog

class _AuthChanges extends ChangeNotifier {
  _AuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.read(prefsProvider);
  String last() => prefs.getString('route') ?? '/game';
  final router = GoRouter(
    initialLocation: last(),
    refreshListenable: _AuthChanges(),
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      if (FirebaseAuth.instance.currentUser == null) return atLogin ? null : '/login';
      return atLogin ? last() : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => _Shell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/game', builder: (_, _) => const GamePage()),
          GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
        ],
      ),
    ],
  );
  router.routerDelegate.addListener(() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (_tabs.contains(path)) prefs.setString('route', path);
  });
  ref.onDispose(router.dispose);
  return router;
});

class _Shell extends StatelessWidget {
  const _Shell({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final icons = [
      (Icons.calculate, l.navGame),
      (Icons.history_edu, l.navHistory),
      (Icons.help_outline, l.navHelp),
      (Icons.settings, l.navSettings),
    ];
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: child),
        ),
      ),
      // The package pins a narrower bar to the left, so on wide screens it is
      // centered here as a dock with rounded corners instead.
      bottomNavigationBar: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _dockWidth),
          child: ClipPath(
            clipper: const _DockClip(),
            child: Padding(
              padding: const EdgeInsets.only(top: _dockHeadroom),
              child: CurvedNavigationBar(
                index: _tabs.indexOf(location).clamp(0, _tabs.length - 1),
                height: 64,
                color: cs.primaryContainer,
                buttonBackgroundColor: cs.tertiaryContainer,
                backgroundColor: Colors.transparent,
                items: [
                  for (final (icon, label) in icons)
                    Tooltip(
                      message: label,
                      child: Icon(icon, size: 28, color: cs.onPrimaryContainer, semanticLabel: label),
                    ),
                ],
                letIndexChange: (i) {
                  if (_tabs[i] != null) return true;
                  showHelp(context);
                  return false;
                },
                onTap: (i) => context.go(_tabs[i]!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _dockWidth = 600.0;
const _dockHeadroom = 16.0; // the selected button rises above the bar

/// Rounds the top corners of the bar when it does not span the whole screen,
/// leaving the headroom above it unclipped.
class _DockClip extends CustomClipper<Path> {
  const _DockClip();

  @override
  Path getClip(Size size) {
    final r = Radius.circular(size.width < _dockWidth ? 0 : 28);
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, _dockHeadroom + 1))
      ..addRRect(RRect.fromLTRBAndCorners(0, _dockHeadroom, size.width, size.height, topLeft: r, topRight: r));
  }

  @override
  bool shouldReclip(_DockClip old) => false;
}

void showHelp(BuildContext context) {
  final l = AppLocalizations.of(context);
  final theme = Theme.of(context);
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.help_outline),
      title: Text(l.helpTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(l.helpBody),
            const SizedBox(height: 16),
            Text(l.helpExample, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Center(child: Math.tex(r'\sqrt{8 + 1} = 3^{1}', textStyle: const TextStyle(fontSize: 26))),
            const SizedBox(height: 16),
            Text(l.helpOperators, style: theme.textTheme.titleSmall),
            for (final v in Level.values)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${levelName(l, v)}: ${Op.values.where(v.ops.contains).map((o) => o.symbol).join('  ')}'),
              ),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
    ),
  );
}
