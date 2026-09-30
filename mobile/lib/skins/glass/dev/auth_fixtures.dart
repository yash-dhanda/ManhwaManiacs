import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/models/profile_extras.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/login_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/register_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/setup_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/onboarding_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/picker_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/profile_form.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/profiles_manage_screen.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Everything a Glass auth, profile or onboarding screen reads, faked (mobile/30): no server, no network. The `/dev/glass/auth` page
/// and the widget tests and captures of these screens build their providers from one of these.
class GlassAuthFixture {
  const GlassAuthFixture({
    this.bootstrap = const BootstrapStatus(needsBootstrap: false, registrationEnabled: true),
    this.bootstrapError,
    this.loginError,
    this.registerError,
    this.serverCheck = const ServerCheck.ok('https://mm.example'),
    this.profiles,
    this.profilesError,
    this.active,
    this.signedIn = false,
    this.seeds,
    this.catalogError,
    this.similar = const [],
  });

  final BootstrapStatus bootstrap;
  final AppError? bootstrapError;
  final AppError? loginError;
  final AppError? registerError;
  final ServerCheck serverCheck;

  /// Null keeps the real notifier (a screen that never reads it); an empty list is the "no profiles" state.
  final List<Profile>? profiles;
  final AppError? profilesError;
  final ActiveProfile? active;
  final bool signedIn;
  final List<WorldItem>? seeds;
  final AppError? catalogError;
  final List<WorldItem> similar;
}

/// A profile for fixtures.
Profile fixtureProfile(int id, String name, {Mood mood = Mood.neutral, String avatar = 'violet', String? skin = 'glass', String? step = 'done', int? goal, bool mature = false, int order = 0}) => Profile(
      id: id,
      name: name,
      avatarKey: avatar,
      mood: mood,
      sortOrder: order == 0 ? id : order,
      matureContentEnabled: mature,
      createdAt: DateTime.utc(2026),
      skin: skin,
      onboardingStep: step,
      dailyGoalMinutes: goal,
    );

/// The five profiles of the picker captures.
List<Profile> fixtureProfiles([int n = 4]) => [
      fixtureProfile(1, 'Yash', mood: Mood.fantasy),
      fixtureProfile(2, 'Late-night reads', mood: Mood.horror, avatar: 'phantom'),
      fixtureProfile(3, 'Sunday', mood: Mood.sliceOfLife, avatar: 'amber'),
      fixtureProfile(4, 'Kai', mood: Mood.action, avatar: 'ember'),
      fixtureProfile(5, 'Mira', mood: Mood.romantic, avatar: 'rose'),
    ].take(n).toList();

class FakeProfiles extends ProfilesNotifier {
  FakeProfiles(this.list, {this.error});
  List<Profile> list;
  final AppError? error;

  /// `create`, `edit`, `delete` and `reorder` calls in order, for tests.
  static final List<String> calls = [];
  static ProfileExtras? lastExtras;

  @override
  Future<List<Profile>> build() async {
    if (error != null) throw error!;
    return list;
  }

  @override
  Future<void> refresh() async => state = AsyncData(list);

  @override
  Future<CreateProfileOutcome> createWithExtras({required String name, required String avatarKey, required Mood mood, bool? matureContentEnabled, ProfileExtras? extras}) async {
    calls.add('create:$name');
    lastExtras = extras;
    final p = fixtureProfile(list.length + 100, name, mood: mood, avatar: avatarKey, skin: extras?.skin, step: null, mature: matureContentEnabled ?? false);
    list = [...list, p];
    state = AsyncData(list);
    return CreateProfileOutcome(created: p);
  }

  @override
  Future<AppError?> edit(int profileId, {String? name, String? avatarKey, Mood? mood, bool? matureContentEnabled, String? skin, int? sortOrder, bool? notifyEnabled, ProfileExtras? extras}) async {
    calls.add('edit:$profileId');
    lastExtras = extras;
    list = [
      for (final p in list)
        if (p.id == profileId)
          Profile(
            id: p.id,
            name: name ?? p.name,
            avatarKey: avatarKey ?? p.avatarKey,
            mood: mood ?? p.mood,
            sortOrder: p.sortOrder,
            matureContentEnabled: matureContentEnabled ?? p.matureContentEnabled,
            createdAt: p.createdAt,
            skin: extras?.skin ?? p.skin,
            onboardingStep: p.onboardingStep,
            dailyGoalMinutes: extras?.dailyGoal != null ? extras!.dailyGoal!.minutes : p.dailyGoalMinutes,
          )
        else
          p,
    ];
    state = AsyncData(list);
    return null;
  }

  @override
  Future<AppError?> delete(int id) async {
    calls.add('delete:$id');
    list = [for (final p in list) if (p.id != id) p];
    state = AsyncData(list);
    return null;
  }

  @override
  Future<AppError?> reorder(List<int> idsInOrder) async {
    calls.add('reorder:${idsInOrder.join(',')}');
    list = [for (final id in idsInOrder) list.firstWhere((p) => p.id == id)];
    state = AsyncData(list);
    return null;
  }
}

class FakeAuth extends AuthController {
  FakeAuth(this.initial, {this.loginError, this.registerError});
  final AuthState initial;
  final AppError? loginError;
  final AppError? registerError;
  static final List<String> calls = [];

  static final AuthUser user = AuthUser(id: 1, username: 'demo', isAdmin: false, createdAt: DateTime.utc(2026));

  @override
  AuthState build() => initial;

  @override
  Future<AppError?> login({required String username, required String password, required bool remember}) async {
    calls.add('login:$username');
    if (loginError != null) return loginError;
    state = AuthAuthenticated(user);
    return null;
  }

  @override
  Future<AppError?> register({required String username, required String password, required bool remember, String? email, String? displayName, String? inviteCode}) async {
    calls.add('register:$username');
    if (registerError != null) return registerError;
    state = AuthAuthenticated(user);
    return null;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    state = const AuthUnauthenticated();
  }
}

class _FakeSettings extends SettingsActions {
  _FakeSettings(super.ref);
  @override
  Future<AppError?> saveApiUrl(String url) async => null;
}

class FakeOnboardingRepo implements OnboardingRepository {
  FakeOnboardingRepo(this.catalogResult);
  final Result<OnboardingCatalog> catalogResult;
  final List<TasteUpdate> saved = [];
  bool failSave = false;

  @override
  Future<Result<OnboardingCatalog>> catalog({List<String> formats = const [], List<String> genres = const [], List<String> styles = const []}) async => catalogResult;

  @override
  Future<Result<void>> saveTaste(int profileId, TasteUpdate body) async {
    saved.add(body);
    return failSave ? const Err(NetworkError(message: 'offline')) : const Ok(null);
  }

  @override
  Future<Result<Taste?>> getTaste(int profileId) async => const Ok(null);
}

class FakeLibrary implements LibraryRepository {
  final List<String> calls = [];

  @override
  Future<Result<FollowedSeries>> follow({required String sourceId, required String seriesKey}) async {
    calls.add('follow:$sourceId/$seriesKey');
    return Ok(FollowedSeries(id: calls.length, sourceId: sourceId, seriesKey: seriesKey, title: seriesKey, coverUrl: '', isFavorite: false, readingStatus: 'reading', notify: true, sortOrder: 0, contentRating: 'safe', rating: '', chapterCount: 0));
  }

  @override
  Future<Result<void>> unfollow(int followedId) async {
    calls.add('unfollow:$followedId');
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Twelve seeds for step 6: the first has a source, the second has none.
List<WorldItem> fixtureSeeds([int n = 12]) => [
      for (var i = 0; i < n; i++)
        WorldItem(
          anilistId: 100 + i,
          title: ['Solo Leveling', 'Tower of God', 'Omniscient Reader', 'Lookism', 'Nano Machine', 'Eleceed', 'Wind Breaker', 'Sweet Home', 'True Beauty', 'Noblesse', 'Hardcore Leveling', 'Bastard'][i % 12],
          available: i == 1 ? const [] : [WorldAvailability(sourceId: 'src', sourceName: 'Source', seriesKey: 'series-$i')],
        ),
    ];

/// The overrides of one fixture.
List<Override> glassAuthFixtureOverrides(GlassAuthFixture f, {FakeOnboardingRepo? onboardingRepo, FakeLibrary? library}) {
  final repo = onboardingRepo ?? FakeOnboardingRepo(f.catalogError != null ? Err(f.catalogError!) : Ok(OnboardingCatalog(seeds: f.seeds ?? fixtureSeeds())));
  return [
    bootstrapStatusProvider.overrideWith((ref) async {
      if (f.bootstrapError != null) throw f.bootstrapError!;
      return f.bootstrap;
    }),
    authControllerProvider.overrideWith(() => FakeAuth(f.signedIn ? AuthAuthenticated(FakeAuth.user) : const AuthUnauthenticated(), loginError: f.loginError, registerError: f.registerError)),
    serverCheckProvider.overrideWithValue((input) async => f.serverCheck),
    settingsActionsProvider.overrideWith(_FakeSettings.new),
    if (f.profiles != null || f.profilesError != null) profilesProvider.overrideWith(() => FakeProfiles(f.profiles ?? const [], error: f.profilesError)),
    onboardingRepositoryProvider.overrideWithValue(repo),
    libraryRepositoryProvider.overrideWithValue(library ?? FakeLibrary()),
    onboardingCatalogProvider.overrideWith((ref, key) async {
      final r = repo.catalogResult;
      if (r case Err(:final error)) throw error;
      return r.value;
    }),
    similarSeedsProvider.overrideWith((ref, id) async => SimilarResult(items: f.similar)),
  ];
}

/// The screens the `/dev/glass/auth` page can show.
enum GlassAuthDevScreen { setup, login, register, picker, form, manage, onboarding }

/// `/dev/glass/auth`: every screen of mobile/30 with a fixture switcher, so the harness and the owner reach every state without a
/// server.
class GlassAuthDevPage extends ConsumerStatefulWidget {
  const GlassAuthDevPage({super.key});

  @override
  ConsumerState<GlassAuthDevPage> createState() => _GlassAuthDevPageState();
}

class _GlassAuthDevPageState extends ConsumerState<GlassAuthDevPage> {
  GlassAuthDevScreen _screen = GlassAuthDevScreen.login;
  int _state = 0;

  static const Map<GlassAuthDevScreen, List<String>> _states = {
    GlassAuthDevScreen.setup: ['idle', 'offline', 'not a server'],
    GlassAuthDevScreen.login: ['normal', 'bootstrap', 'unreachable', 'wrong password', 'rate limited'],
    GlassAuthDevScreen.register: ['open', 'bootstrap', 'closed'],
    GlassAuthDevScreen.picker: ['four', 'five', 'empty', 'error'],
    GlassAuthDevScreen.form: ['new', 'edit'],
    GlassAuthDevScreen.manage: ['four', 'empty'],
    GlassAuthDevScreen.onboarding: ['1', '2', '3', '4', '5', '6', '7'],
  };

  GlassAuthFixture _fixture() {
    final s = _states[_screen]![_state];
    return switch ((_screen, s)) {
      (GlassAuthDevScreen.setup, 'offline') => const GlassAuthFixture(serverCheck: ServerCheck.offline()),
      (GlassAuthDevScreen.setup, 'not a server') => const GlassAuthFixture(serverCheck: ServerCheck.notManhwaManiacs()),
      (GlassAuthDevScreen.login, 'bootstrap') => const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: true, registrationEnabled: true)),
      (GlassAuthDevScreen.login, 'unreachable') => const GlassAuthFixture(bootstrapError: NetworkError(message: 'offline')),
      (GlassAuthDevScreen.login, 'wrong password') => const GlassAuthFixture(loginError: ApiError(statusCode: 401, code: 'invalid_credentials', message: 'no')),
      (GlassAuthDevScreen.login, 'rate limited') => const GlassAuthFixture(loginError: ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', retryAfter: Duration(seconds: 42))),
      (GlassAuthDevScreen.register, 'bootstrap') => const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: true, registrationEnabled: true)),
      (GlassAuthDevScreen.register, 'closed') => const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: false, registrationEnabled: false)),
      (GlassAuthDevScreen.picker, 'five') => GlassAuthFixture(signedIn: true, profiles: fixtureProfiles(5)),
      (GlassAuthDevScreen.picker, 'empty') => const GlassAuthFixture(signedIn: true, profiles: []),
      (GlassAuthDevScreen.picker, 'error') => const GlassAuthFixture(signedIn: true, profilesError: ApiError(statusCode: 500, code: 'x', message: 'The server had a problem.')),
      (GlassAuthDevScreen.manage, 'empty') => const GlassAuthFixture(signedIn: true, profiles: []),
      _ => GlassAuthFixture(signedIn: true, profiles: fixtureProfiles(), active: const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy)),
    };
  }

  Widget _child() => switch (_screen) {
        GlassAuthDevScreen.setup => const GlassSetupScreen(),
        GlassAuthDevScreen.login => const GlassLoginScreen(),
        GlassAuthDevScreen.register => const GlassRegisterScreen(),
        GlassAuthDevScreen.picker => const GlassProfilePicker(),
        GlassAuthDevScreen.form => GlassProfileForm(profileId: _states[_screen]![_state] == 'edit' ? 1 : null, onClose: () {}),
        GlassAuthDevScreen.manage => const GlassProfilesManageScreen(),
        GlassAuthDevScreen.onboarding => GlassOnboardingScreen(step: int.parse(_states[_screen]![_state])),
      };

  @override
  Widget build(BuildContext context) {
    final f = _fixture();
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Stack(
        children: [
          // A nested scope: the fixture's fakes replace the real providers for this one page.
          ProviderScope(
            key: ValueKey('$_screen$_state'),
            overrides: glassAuthFixtureOverrides(f),
            child: _child(),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DevSegmented<GlassAuthDevScreen>(values: GlassAuthDevScreen.values, labelOf: (s) => s.name, selected: _screen, onSelected: (s) => setState(() {
                          _screen = s;
                          _state = 0;
                        }),),
                    const SizedBox(height: 4),
                    DevSegmented<int>(values: [for (var i = 0; i < _states[_screen]!.length; i++) i], labelOf: (i) => _states[_screen]![i], selected: _state, onSelected: (i) => setState(() => _state = i)),
                    GlassText('Fixture data only', role: gt.typeCaption1, color: gt.colorLabel3),
                    DevButton(label: 'Back to development index', onTap: () => GoRouter.of(context).go('/dev/glass')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
