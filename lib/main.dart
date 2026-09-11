import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_theme.dart';
import 'data/verses.dart';
import 'screens/create_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/images_screen.dart';
import 'screens/more_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ads_service.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'widgets/banner_ad.dart';

/// Navegador raiz do app.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge (Android 15 / SDK 35): desenha sob as barras; Flutter trata os insets.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Aquece a fonte principal (Lora) durante a splash (sem "flash" de fonte).
  GoogleFonts.lora();
  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs);

  // Carrega as frases do bundle (assets/frases/*.json) antes de abrir a home,
  // para que nenhuma tela veja conteúdo vazio.
  await VerseData.load();

  AdsService.instance.init();

  PurchaseService.instance
    ..onEntitlement(appState.grantEntitlement)
    ..onSubscriptionGranted(appState.addSubscription)
    ..init();

  // Notificação: ao tocar abre a tela principal (mesma frase do card do topo).
  // Reagenda o lembrete diário se estiver ativo (também cobre reboot).
  final notif = NotificationService.instance;
  notif.init().then((_) {
    if (appState.reminderOn) {
      notif.scheduleDaily(appState.reminderHour, appState.reminderMin);
    }
  });

  runApp(MensagensApp(appState: appState));
}

class MensagensApp extends StatelessWidget {
  const MensagensApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'Frases em Inglês',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(state.accentColor),
          darkTheme: AppTheme.dark(state.accentColor),
          themeMode: state.themeMode,
          home: const _RootGate(),
        ),
      ),
    );
  }
}

/// Mostra a splash da marca por ~2s e então ESMAECE por cima do app (sem troca
/// de telas / "piscar"). O app é construído por baixo desde o início.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _ready = false;
  bool _splashGone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeShell(),
        if (!_splashGone)
          AnimatedOpacity(
            opacity: _ready ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            onEnd: () {
              if (_ready && mounted) setState(() => _splashGone = true);
            },
            child: const SplashScreen(),
          ),
      ],
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Um navegador por aba: a barra inferior permanece visível mesmo ao entrar
  // nas categorias/telas internas (melhor usabilidade e navegação).
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const _roots = [
    HomeScreen(),
    ImagesScreen(),
    CreateScreen(),
    FavoritesScreen(),
    MoreScreen(),
  ];

  Widget _tabNavigator(int i) => Navigator(
        key: _navKeys[i],
        onGenerateRoute: (settings) =>
            MaterialPageRoute(builder: (_) => _roots[i], settings: settings),
      );

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accentColor;
    final surface = Theme.of(context).colorScheme.surface;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < _roots.length; i++) _tabNavigator(i)
                ],
              ),
            ),
            const BannerPlaceholder(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: accent.withValues(alpha: 0.20),
                  blurRadius: 22,
                  offset: const Offset(0, -3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: surface,
                elevation: 0,
                indicatorColor: accent.withValues(alpha: 0.18),
                labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                    fontSize: 11.5,
                    fontWeight: s.contains(WidgetState.selected)
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: s.contains(WidgetState.selected) ? accent : null)),
                iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
                    color: s.contains(WidgetState.selected) ? accent : null)),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                height: 66,
                onDestinationSelected: (i) {
                  if (i == _index) {
                    _navKeys[i].currentState?.popUntil((r) => r.isFirst);
                  } else {
                    setState(() => _index = i);
                  }
                  if (!context.read<AppState>().adsRemoved) {
                    AdsService.instance.registerActionAndMaybeShow();
                  }
                },
                destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Início'),
            NavigationDestination(
                icon: Icon(Icons.image_outlined),
                selectedIcon: Icon(Icons.image_rounded),
                label: 'Imagens'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline_rounded),
                selectedIcon: Icon(Icons.add_circle_rounded),
                label: 'Criar'),
            NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Favoritos'),
            NavigationDestination(
                icon: Icon(Icons.more_horiz_rounded),
                selectedIcon: Icon(Icons.more_horiz_rounded),
                label: 'Mais'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
