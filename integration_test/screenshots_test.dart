// Store and landing captures, rendered from the real app on the invented
// congregation of tool/demo/demo_dataset.dart. Nothing here reads the user's
// database, so a capture can never leak a real name.
//
//   tool/demo/shots.sh              # everything
//   tool/demo/shots.sh phone es     # one target, one language
//
// The macOS app is sandboxed, so the PNGs are written inside its container
// and each one is printed as `WROTE_PNG <path>`; the script above is what
// copies them out into build/demo/shots/.
//
// Sizes cover Play (phone + 10" tablet), App Store (iPhone 17 Pro Max and
// iPad Pro 11") and the landing hero. Each is captured light and dark, in
// Spanish and English.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:agora/data/db/app_database.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/state/auth_session.dart';
import 'package:agora/state/cloud_auth.dart';
import 'package:agora/state/dashboard_provider.dart';
import 'package:agora/state/db_provider.dart';
import 'package:agora/state/locale_boot.dart';
import 'package:agora/state/mwb_sync.dart';
import 'package:agora/state/program_form.dart';
import 'package:agora/state/ui_state.dart';
import 'package:agora/ui/shell/app_shell.dart';
import 'package:agora/ui/shell/program_shell.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:drift/native.dart';

import '../tool/demo/demo_dataset.dart';

enum Screen { editor, editorPreview, dashboard, participants }

/// A capture surface: [size] is the PNG in pixels, [dpr] decides which layout
/// the app picks for it (size / dpr = the logical width it lays out against),
/// and [insets] are the device's safe-area paddings in pixels.
///
/// The insets matter more than they look: without them the app lays out under
/// the status bar, and a mockup then draws a dynamic island straight across
/// the screen's first line of text.
typedef Target = ({
  String name,
  Size size,
  double dpr,
  ({double top, double bottom}) insets,
  List<Screen> screens,
});

const _tabletScreens = [Screen.editor, Screen.dashboard, Screen.participants];
const _phoneScreens = [
  Screen.editor,
  Screen.editorPreview,
  Screen.dashboard,
  Screen.participants,
];

const _targets = <Target>[
  // Play, phone. 393x785 logical → mobile layout.
  //
  // 2:1 exactly, which is as tall as Play allows (it caps the long side at
  // twice the short one, so the 19.5:9 an iPhone uses would be rejected).
  // The old 1080x1920 was 16:9 at dpr 3, i.e. 360x640 logical: a 2014 phone,
  // where the UI renders huge and the whole thing reads stubby.
  (
    name: 'phone',
    size: Size(1080, 2160),
    dpr: 2.75,
    insets: (top: 0, bottom: 0), // fill the screen: no dead band in a mockup
    screens: _phoneScreens,
  ),
  // App Store, iPhone 17 Pro Max (6.9"). 440x956 logical → mobile layout.
  (
    name: 'iphone17-pro-max',
    size: Size(1320, 2868),
    dpr: 3.0,
    // Only what the dynamic island covers. Any more and the frame shows a
    // band of empty app background, which reads as a screenshot pasted on
    // top of a device rather than as the device's own screen.
    insets: (top: 150, bottom: 0),
    screens: _phoneScreens,
  ),
  // App Store, iPad Pro 11" (M4). 834x1210 logical → tablet layout.
  (
    name: 'ipad11-portrait',
    size: Size(1668, 2420),
    dpr: 2.0,
    insets: (top: 0, bottom: 0),
    screens: _tabletScreens,
  ),
  // Landscape is where a tablet earns its keep: 1194x834 logical crosses into
  // the desktop layout, so both panels sit side by side.
  (
    name: 'ipad11-landscape',
    size: Size(2420, 1668),
    dpr: 2.0,
    insets: (top: 0, bottom: 0),
    screens: _tabletScreens,
  ),
  // Play, 10" tablet. 800x1280 logical → tablet layout.
  (
    name: 'tablet10-portrait',
    size: Size(1600, 2560),
    dpr: 2.0,
    insets: (top: 0, bottom: 0),
    screens: _tabletScreens,
  ),
  // 1280x800 logical → desktop layout.
  (
    name: 'tablet10-landscape',
    size: Size(2560, 1600),
    dpr: 2.0,
    insets: (top: 0, bottom: 0),
    screens: _tabletScreens,
  ),
  (
    name: 'web-hero',
    size: Size(2880, 1800),
    dpr: 2.0,
    insets: (top: 0, bottom: 0), // a browser window has no device chrome
    screens: [Screen.editor],
  ),
];

const _themes = {'light': ThemeMode.light, 'dark': ThemeMode.dark};

/// Comma-separated filters so a single size/language can be re-shot without
/// paying for the whole matrix; empty means everything.
const _onlyTargets = String.fromEnvironment('SHOTS_TARGETS');
const _onlyLocales = String.fromEnvironment('SHOTS_LOCALES');

bool _wanted(String filter, String name) =>
    filter.isEmpty || filter.split(',').contains(name);

/// How long to let a screen finish after switching to it. The editor
/// rasterizes its PDF preview on a background isolate, so it needs a longer
/// runway than the list screens.
int _settleMillis(Screen screen) =>
    screen == Screen.dashboard || screen == Screen.participants ? 1500 : 3000;

/// Waits [millis] of REAL time, pumping as few frames as possible, and stops
/// early once [until] holds.
///
/// Frames are the scarce resource here, not time: `pump` waits on the test
/// window's vsync, which macOS throttles hard whenever that window is behind
/// another app — one frame can cost seconds. So the waiting is handed to
/// `runAsync`, where the drift streams and the PDF isolate make progress on
/// their own clock, and frames are spent only to show the result. Animations
/// are disabled for the same reason (see the MaterialApp builder).
Future<void> _settle(WidgetTester tester, int millis,
    {bool Function()? until}) async {
  // Pump BEFORE waiting: the screen under capture is mounted by this frame,
  // and nothing it kicks off — the editor's programs stream, the PDF isolate
  // — can even start until it exists.
  await tester.pump();
  final slice = until == null ? millis : 250;
  for (var elapsed = 0; elapsed < millis; elapsed += slice) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: slice)));
    await tester.pump();
    if (until != null && until()) return;
  }
}

/// Boot sync without network or disk.
class _NoopSyncController extends MwbSyncController {
  @override
  Future<SyncReport> build() async => const SyncReport();
}

/// Session already unlocked: skips AuthGate without touching the keychain.
///
/// The profile name is not decoration: the sidebar's user card hides itself
/// when the session has none, so an anonymous session captures a nav with a
/// gap where that card belongs.
class _UnlockedSessionController extends SessionController {
  @override
  SessionState build() => SessionUnlocked('00' * 32, AccountMode.local,
      profileName: demoProfileName);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // NOTE: the capture loop runs on the test window's vsync, which macOS
  // throttles while that window is covered — a capture that takes 2s in front
  // can take over a minute behind another app. `framePolicy = benchmark`
  // looks like the fix and is not: it stalls this harness outright. Keep the
  // window frontmost instead (tool/demo/shots.sh says so on startup).

  // One test per (language, size): each stays well inside a timeout, and a
  // slow or broken size fails on its own instead of taking the run with it.
  for (final locale in shippedLocales) {
    if (!_wanted(_onlyLocales, locale.languageCode)) continue;
    for (final target in _targets) {
      if (!_wanted(_onlyTargets, target.name)) continue;

      testWidgets('${target.name} in ${locale.languageCode}', (tester) async {
        await pdfrxFlutterInitialize();
        final outDir = await _resolveOutDir(target.name);
        LocaleSettings.setLocaleSync(locale);

        final db = AppDatabase(NativeDatabase.memory());
        await seedDemoData(db, locale: locale);

        final container = ProviderContainer(overrides: [
          dbProvider.overrideWithValue(db),
          authSessionProvider.overrideWith(_UnlockedSessionController.new),
          mwbSyncProvider.overrideWith(_NoopSyncController.new),
          firebaseAppProvider.overrideWith((ref) async => null),
        ]);

        final stage = ValueNotifier<_Stage>(
            (theme: ThemeMode.light, screen: Screen.dashboard));

        tester.view.physicalSize = target.size;
        tester.view.devicePixelRatio = target.dpr;
        tester.view.padding = FakeViewPadding(
            top: target.insets.top, bottom: target.insets.bottom);

        await tester.pumpWidget(TranslationProvider(
          child: UncontrolledProviderScope(
            container: container,
            child: _StageView(locale: locale, stage: stage),
          ),
        ));

        // Wait on the data, not on a stopwatch: the drift streams have to
        // emit before any screen shows more than its skeleton.
        bool loaded() =>
            container.read(projectsProvider).isNotEmpty &&
            !container.read(dashboardLoadingProvider);
        await _settle(tester, 10000, until: loaded);
        expect(loaded(), isTrue, reason: 'demo data never reached the UI');

        // The dashboard is only worth capturing when it is populated: a hero
        // card to continue, a full reminder list and projects in every state.
        final data = demoDataFor(locale);
        expect(container.read(projectsProvider),
            hasLength(data.projects.length));
        expect(container.read(heroProjectProvider), isNotNull);
        expect(container.read(remindersProvider), hasLength(4));

        for (final theme in _themes.entries) {
          for (final screen in target.screens) {
            final clock = Stopwatch()..start();
            container
                .read(appSectionProvider.notifier)
                .select(screen == Screen.participants
                    ? AppSection.participants
                    : AppSection.home);
            container.read(mobileTabProvider.notifier).select(
                screen == Screen.editorPreview
                    ? MobileTab.preview
                    : MobileTab.assign);
            stage.value = (theme: theme.value, screen: screen);

            // The editor hydrates its own form from the DB once mounted, so
            // wait for the schedule it builds rather than for a stopwatch —
            // capturing early gets the skeleton, which is what a store
            // listing must never show.
            if (screen == Screen.editor || screen == Screen.editorPreview) {
              await _settle(tester, 20000,
                  until: () => container.read(scheduleProvider) != null);
              expect(container.read(scheduleProvider), isNotNull,
                  reason: 'editor never left its skeleton');
            }
            // Bounded instead of pumpAndSettle: the skeleton shimmer and the
            // preview never stop animating, so settling would time out.
            await _settle(tester, _settleMillis(screen));

            final name = '${target.name}_${screen.name}_'
                '${locale.languageCode}_${theme.key}.png';
            await _capture(
                File('$outDir/$name'), target.size, target.dpr, clock);
          }
        }

        // Unmount the editor while the container is still alive: ProgramShell
        // closes its session in a microtask after dispose.
        stage.value = (theme: ThemeMode.light, screen: null);
        await tester.pump();
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());

        tester.view.reset();
        container.dispose();
        await db.close();
        // Short on purpose. Every wait here is bounded, so overrunning means
        // the window never became visible and no frame will ever arrive —
        // failing in three minutes beats hanging for ten.
      }, timeout: const Timeout(Duration(minutes: 3)));
    }
  }
}

typedef _Stage = ({ThemeMode theme, Screen? screen});

final _rootKey = GlobalKey();

class _StageView extends StatelessWidget {
  const _StageView({required this.locale, required this.stage});

  final AppLocale locale;
  final ValueNotifier<_Stage> stage;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _rootKey,
      child: ValueListenableBuilder<_Stage>(
        valueListenable: stage,
        builder: (context, value, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale.flutterLocale,
          supportedLocales: [for (final l in shippedLocales) l.flutterLocale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildAppTheme(pizarra.light, Brightness.light),
          darkTheme: buildAppTheme(pizarra.dark, Brightness.dark),
          themeMode: value.theme,
          // Reduce Motion, which the app honours everywhere (ui/widgets/
          // motion.dart): a capture wants the settled state, and every frame
          // an animation needs is a frame this harness has to wait for.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: switch (value.screen) {
            null => const SizedBox.shrink(),
            Screen.editor || Screen.editorPreview => const _EditorScreen(),
            Screen.dashboard || Screen.participants => const AppShell(),
          },
        ),
      ),
    );
  }
}

/// Waits for the project streams, then hands the editor the demo project.
class _EditorScreen extends ConsumerWidget {
  const _EditorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congregations = ref.watch(congregationsProvider);
    final project = ref
        .watch(projectsProvider)
        .where((p) => p.id == demoProjectId)
        .firstOrNull;
    if (project == null || congregations.isEmpty) {
      return const SizedBox.shrink();
    }
    return ProgramShell(project: project);
  }
}

Future<void> _capture(
    File out, Size size, double dpr, Stopwatch clock) async {
  final boundary =
      _rootKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: dpr);
  try {
    expect(image.width, size.width.round(), reason: 'width of ${out.path}');
    expect(image.height, size.height.round(), reason: 'height of ${out.path}');

    // The files land inside the sandboxed container, where the caller may not
    // be able to eyeball them — so assert here that we captured a rendered
    // screen and not the blank frame before layout settled.
    final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final colors = _distinctColors(raw!);
    expect(colors, greaterThan(8), reason: '${out.path} looks blank');

    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await out.writeAsBytes(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('WROTE_PNG ${out.path} colors=$colors ${clock.elapsedMilliseconds}ms');
  } finally {
    image.dispose();
  }
}

/// Distinct colours over a sparse sample of the frame — enough to tell a real
/// screen from a flat fill, without walking millions of pixels.
int _distinctColors(ByteData raw) {
  final colors = <int>{};
  const stride = 4 * 997; // prime stride: never lands on one column
  for (var i = 0; i + 3 < raw.lengthInBytes; i += stride) {
    colors.add(raw.getUint32(i));
  }
  return colors.length;
}

var _wiped = false;

/// Clears the captures this run is about to replace, so a stale PNG from an
/// earlier target list can never be collected as if it were current. A full
/// run wipes everything once; a filtered one only drops its own target.
Future<String> _resolveOutDir(String target) async {
  final dir = await getApplicationDocumentsDirectory();
  final out = Directory('${dir.path}/agora-shots');
  final fullRun = _onlyTargets.isEmpty && _onlyLocales.isEmpty;

  if (fullRun) {
    if (!_wiped && out.existsSync()) out.deleteSync(recursive: true);
    _wiped = true;
  } else if (out.existsSync()) {
    for (final f in out.listSync()) {
      if (f is File && f.uri.pathSegments.last.startsWith('${target}_')) {
        f.deleteSync();
      }
    }
  }

  await out.create(recursive: true);
  return out.path;
}
