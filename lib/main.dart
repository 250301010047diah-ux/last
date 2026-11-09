import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/data.dart';
import 'game/game.dart';
import 'ui/action_button.dart';
import 'ui/main_menu.dart';
import 'ui/ultimate_gauge.dart';
import 'ui/virtual_joystick.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The game world is a fixed 360x640 portrait field.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magitech Siege',
      theme: ThemeData.dark(),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _Panel { none, volume, tutorial }

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final RuntuhGame game;
  Timer? _hudTimer;
  _Panel _panel = _Panel.none;

  /// True when opening a panel paused a running game, so closing it resumes.
  bool _resumeOnClose = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game = RuntuhGame();
    game.notifyUi = () {
      if (mounted) setState(() {});
    };
    game.onShowTutorial = () {
      if (mounted) setState(() => _panel = _Panel.tutorial);
    };
    _hudTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (game.phase == GamePhase.playing && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hudTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        game.onAppBackground();
        // The run is now paused by the game; don't auto-resume it when a
        // panel that was open gets closed.
        _resumeOnClose = false;
        break;
      case AppLifecycleState.resumed:
        game.onAppForeground();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _openPanel(_Panel panel) {
    game.audio.play('click');
    if (game.phase == GamePhase.playing && !game.gamePaused) {
      game.pauseGame(silent: true);
      _resumeOnClose = true;
    }
    setState(() => _panel = panel);
  }

  void _closePanel() {
    setState(() => _panel = _Panel.none);
    if (_resumeOnClose) {
      _resumeOnClose = false;
      game.resumeGame();
    }
  }

  void _finishTutorial() {
    game.completeTutorial();
    _closePanel();
  }

  // First-time players get the tutorial when their first run starts (see
  // RuntuhGame.onShowTutorial), not on the title screen.
  bool get _showTutorial => _panel == _Panel.tutorial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: game),
          _overlay(),
          if (_showTutorial)
            TutorialOverlay(onDone: _finishTutorial)
          else if (_panel == _Panel.volume)
            _volumePanel(),
        ],
      ),
    );
  }

  Widget _overlay() {
    if (game.gamePaused) return _pauseMenu();
    switch (game.phase) {
      case GamePhase.title:
        return _mainMenu();
      case GamePhase.ready:
        final wave = game.combat?.wave ?? 1;
        return IgnorePointer(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  game.combat?.area.name ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (wave > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lanjut dari Wave $wave',
                    style: const TextStyle(fontSize: 15, color: Colors.amber),
                  ),
                ],
                if (game.tutorialPending) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'TUTORIAL LATIHAN',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  game.tutorialPending
                      ? 'TAP UNTUK MULAI LATIHAN'
                      : 'TAP UNTUK BERMAIN',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      case GamePhase.playing:
        return _playingHud();
      case GamePhase.upgrade:
        return _upgradeScreen();
      case GamePhase.gameover:
        return _gameOverScreen();
      case GamePhase.victory:
        return _centerCard(
          title: 'AREA CLEAR',
          subtitle:
              'Skor: ${game.combat?.score.round() ?? 0}\n'
              'Skor terbaik: ${game.save.bestScore}',
          button: 'LANJUT',
          onTap: () => game.startArea(
            (game.activeArea + 1).clamp(0, AREAS.length - 1),
            false,
          ),
        );
      case GamePhase.loading:
        // Boot / area load from the menu: continue the native splash look.
        if (game.combat == null) return _logoLoading();
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _logoLoading() {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      color: const Color(0xff0a0e1f),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: (width * 0.78).clamp(160.0, 340.0),
            cacheWidth: 680,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: const LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.white12,
                color: Color(0xff5ee7ff),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Memuat...',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    double size = 30,
  }) {
    return IconButton(
      icon: Icon(icon, size: size, color: Colors.white),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  Widget _settingsButtons({bool withPause = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBtn(Icons.volume_up, 'Volume', () => _openPanel(_Panel.volume)),
        _iconBtn(
          Icons.help_outline,
          'Tutorial',
          () => _openPanel(_Panel.tutorial),
        ),
        if (withPause)
          _iconBtn(
            Icons.pause_circle_filled,
            'Jeda',
            () => game.pauseGame(),
            size: 34,
          ),
      ],
    );
  }

  Future<bool> _confirm(String title, String message, String okLabel) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              okLabel,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _startNewRun() async {
    if (!game.isSkinUnlocked(game.selectedSkin) ||
        !game.isAreaUnlocked(game.selectedTheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buka skin dan area yang dipilih dulu.')),
      );
      return;
    }
    if (game.checkpoint != null) {
      final ok = await _confirm(
        'Mulai baru?',
        'Kamu punya permainan tersimpan. Memulai baru akan menghapus '
            'permainan tersimpan itu.',
        'MULAI BARU',
      );
      if (!ok) return;
    }
    game.audio.play('start');
    game.startArea(game.selectedTheme, false);
  }

  Future<void> _resetProgress() async {
    final ok = await _confirm(
      'Reset progres?',
      'Skor terbaik, koin, permainan tersimpan, dan pilihan skin/tema akan '
          'dihapus. Tindakan ini tidak bisa dibatalkan.',
      'RESET',
    );
    if (!ok) return;
    game.audio.play('click');
    game.resetProgress();
  }

  Widget _mainMenu() {
    return MainMenu(
      game: game,
      onVolume: () => _openPanel(_Panel.volume),
      onHelp: () => _openPanel(_Panel.tutorial),
      onStart: _startNewRun,
      onContinue: () {
        game.audio.play('start');
        game.continueRun();
      },
      onReset: _resetProgress,
    );
  }

  Widget _gameOverScreen() {
    final score = game.combat?.score.round() ?? 0;
    final best = game.save.bestScore;
    final record = score > 0 && score >= best;
    const gold = Color(0xffe8b04a);
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.0,
          colors: [Color(0x99200a14), Color(0xe6050710)],
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xdd0c1022),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: gold.withValues(alpha: 0.8),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffff3d5a).withValues(alpha: 0.3),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.heart_broken_rounded,
                  size: 40,
                  color: Color(0xffff5a6e),
                ),
                const SizedBox(height: 6),
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.white,
                    shadows: [Shadow(color: Color(0xffff3d5a), blurRadius: 14)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wave ${game.combat?.wave ?? 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'SKOR',
                  style: TextStyle(fontSize: 11, letterSpacing: 3, color: gold),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record ? 'REKOR BARU!' : 'Terbaik: $best',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: record ? const Color(0xffffc93c) : Colors.white60,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => game.restart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: const Color(0xff1a1206),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ULANGI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    game.audio.play('click');
                    game.quitToMenu();
                  },
                  child: const Text(
                    'MENU',
                    style: TextStyle(color: Colors.white70, letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _centerCard({
    required String title,
    required String subtitle,
    required String button,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: Text(button, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                game.audio.play('click');
                game.quitToMenu();
              },
              child: const Text(
                'MENU',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playingHud() {
    final w = game.combat!;
    final p = w.player;
    final compactControls = MediaQuery.sizeOf(context).width < 360;
    final actionSize = compactControls ? 48.0 : 54.0;
    final ultimateSize = compactControls ? 54.0 : 62.0;
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Informational layer (non-interactive)
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: List.generate(
                          p.maxHp,
                          (i) => Icon(
                            Icons.favorite,
                            size: 18,
                            color: i < p.hp
                                ? Colors.red
                                : Colors.red.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        game.inTutorial ? 'Latihan' : 'Wave ${w.wave}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      // Pops and flashes gold each time the score goes up.
                      TweenAnimationBuilder<double>(
                        key: ValueKey(w.score.round()),
                        tween: Tween(begin: 1, end: 0),
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOut,
                        builder: (context, k, _) => Transform.scale(
                          scale: 1 + 0.35 * k,
                          child: Text(
                            '${w.score.round()}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color.lerp(
                                Colors.white,
                                const Color(0xffffc93c),
                                k,
                              ),
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xffff9a1f,
                                  ).withValues(alpha: k),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.monetization_on,
                        size: 16,
                        color: Colors.amber,
                      ),
                      Text(
                        '${w.runCoins}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _bar('RAGE', p.rage / 100, Colors.orange),
                      const SizedBox(height: 6),
                      UltimateGauge(value: p.ultimate / 100),
                    ],
                  ),
                ),
                if (game.banner.isNotEmpty && !game.inTutorial)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      game.banner,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Volume / tutorial / pause (interactive), below the top bar so they
          // don't cover the score.
          Positioned(
            top: 36,
            right: 4,
            child: _settingsButtons(withPause: true),
          ),
          if (game.inTutorial)
            Positioned(top: 146, left: 12, right: 12, child: _tutorialCard()),
          // Left stick moves Asha; arrows auto-aim upward.
          Positioned(
            bottom: 24,
            left: 12,
            child: VirtualJoystick(
              label: 'Gerak',
              color: const Color(0xff5ee7ff),
              onChanged: (axis) => game.input.moveX = axis.dx,
            ),
          ),
          // Action buttons clustered bottom-right: bottom row Melee/Lompat/
          // Ulti, top row Skill1/Skill2.
          Positioned(
            bottom: 12,
            right: 10,
            child: SizedBox(
              width: 216,
              height: 172,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 148,
                    bottom: 0,
                    child: _actionBtn(
                      'Melee',
                      Icons.flare_rounded,
                      const Color(0xffff8a3d),
                      () => game.combat?.useAction('melee'),
                      cooldown: p.meleeCooldown,
                      cooldownMax: p.meleeCooldownMax,
                      enabled: p.jump <= 10,
                      size: actionSize,
                    ),
                  ),
                  Positioned(
                    right: 76,
                    bottom: 84,
                    child: _actionBtn(
                      'Skill1',
                      Icons.bolt_rounded,
                      const Color(0xffffe45c),
                      () => game.combat?.useAction('skill1'),
                      cooldown: p.skillOneCooldown,
                      cooldownMax: p.skillOneCooldownMax,
                      size: actionSize,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 94,
                    child: _actionBtn(
                      'Skill2',
                      Icons.ac_unit_rounded,
                      const Color(0xff8fd8ff),
                      () => game.combat?.useAction('skill2'),
                      cooldown: p.skillTwoCooldown,
                      cooldownMax: p.skillTwoCooldownMax,
                      size: actionSize,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _actionBtn(
                      'Ulti',
                      Icons.whatshot_rounded,
                      const Color(0xffff5fd2),
                      () => game.combat?.useAction('ultimate'),
                      charge: p.ultimate / 100,
                      size: ultimateSize,
                    ),
                  ),
                  Positioned(
                    right: 78,
                    bottom: 0,
                    child: _actionBtn(
                      'Lompat',
                      Icons.keyboard_double_arrow_up_rounded,
                      const Color(0xff5ee7ff),
                      () => game.combat?.jump(),
                      enabled: p.jump <= 0.5,
                      size: actionSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pauseMenu() {
    const gold = Color(0xffe8b04a);
    final w = game.combat;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.0,
          colors: [Color(0x99081028), Color(0xe6050710)],
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
          ),
          child: Container(
            width: 290,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            decoration: BoxDecoration(
              color: const Color(0xdd0c1022),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: gold.withValues(alpha: 0.8),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff5ee7ff).withValues(alpha: 0.22),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 38,
                  color: Color(0xff5ee7ff),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JEDA',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0xff5ee7ff), blurRadius: 14),
                    ],
                  ),
                ),
                if (w != null)
                  Text(
                    '${game.inTutorial ? 'Latihan' : 'Wave ${w.wave}'}'
                    '  •  Skor ${w.score.round()}',
                    style: const TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.5,
                      color: Colors.white60,
                    ),
                  ),
                const SizedBox(height: 18),
                _menuButton(
                  'LANJUT',
                  Icons.play_arrow_rounded,
                  primary: true,
                  onTap: () {
                    game.audio.play('click');
                    game.resumeGame();
                  },
                ),
                const SizedBox(height: 10),
                _menuButton(
                  'ULANGI',
                  Icons.replay_rounded,
                  onTap: () {
                    game.audio.play('click');
                    game.resumeGame();
                    game.restart();
                  },
                ),
                const SizedBox(height: 10),
                _menuButton(
                  'MENU',
                  Icons.home_rounded,
                  onTap: () {
                    game.audio.play('click');
                    game.quitToMenu();
                  },
                ),
                const SizedBox(height: 10),
                _settingsButtons(),
                const Text(
                  'Progres tersimpan otomatis setiap awal wave',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
    String label,
    IconData icon, {
    required VoidCallback onTap,
    bool primary = false,
  }) {
    const gold = Color(0xffe8b04a);
    final style = primary
        ? ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: const Color(0xff1a1206),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff141a33),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: gold.withValues(alpha: 0.55)),
            ),
          );
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: style,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _volumePanel() {
    final audio = game.audio;
    Widget row(
      IconData icon,
      String label,
      double value,
      ValueChanged<double> onChanged,
      ValueChanged<double> onEnd,
    ) {
      return Row(
        children: [
          Icon(value <= 0 ? Icons.volume_off : icon, color: Colors.white70),
          const SizedBox(width: 8),
          SizedBox(width: 52, child: Text(label)),
          Expanded(
            child: Slider(
              value: value,
              onChanged: onChanged,
              onChangeEnd: onEnd,
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          color: const Color(0xff1c1c28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VOLUME',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                row(Icons.music_note, 'Musik', audio.bgmVolume, (v) {
                  setState(() => audio.setBgmVolume(v));
                }, game.setBgmVolume),
                row(
                  Icons.volume_up,
                  'Efek',
                  audio.sfxVolume,
                  (v) {
                    setState(() => audio.setSfxVolume(v));
                  },
                  (v) {
                    game.setSfxVolume(v);
                    game.audio.play('click');
                  },
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _closePanel, child: const Text('TUTUP')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tutorialCard() {
    final step = game.tutorialStep;
    final info = RuntuhGame.tutorialSteps[step];
    final done = game.tutorialStepCompleted;
    final progress = game.tutorialProgress;
    final hasProgress = step == 0 || step == 2;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: BoxDecoration(
        color: const Color(0xee141420),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? Colors.greenAccent
              : Colors.amber.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (done ? Colors.greenAccent : Colors.amber).withValues(
              alpha: 0.25,
            ),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'TUTORIAL ${step + 1}/${RuntuhGame.tutorialSteps.length}',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: Colors.amber,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  game.audio.play('click');
                  game.finishTutorial();
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Colors.white60,
                ),
                child: const Text('LEWATI ›', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Row(
            children: [
              if (done) ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 22,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                done ? 'Bagus!' : info[0],
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: done ? Colors.greenAccent : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              info[1],
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ),
          if (hasProgress) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  color: done ? Colors.greenAccent : Colors.amber,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    double cooldown = 0,
    double cooldownMax = 1,
    double? charge,
    bool enabled = true,
    double size = 56,
  }) {
    // Highlight the button the current tutorial step is asking for.
    final wanted =
        game.inTutorial &&
        !game.tutorialStepCompleted &&
        RuntuhGame.tutorialButtons[game.tutorialStep] == label;
    return ActionButton(
      label: label.toUpperCase(),
      icon: icon,
      color: color,
      onTap: onTap,
      cooldown: cooldown,
      cooldownMax: cooldownMax,
      charge: charge,
      enabled: enabled,
      highlight: wanted,
      size: size,
    );
  }

  Widget _bar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _upgradeScreen() {
    final w = game.combat!;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PILIH UPGRADE',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            for (final u in game.upgradeChoicesList)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    game.audio.play('select');
                    game.chooseUpgrade(u.id);
                  },
                  child: Text('${u.label} — ${u.detail}'),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Skor: ${w.score.round()}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage {
  const _TutorialPage(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const List<_TutorialPage> _tutorialPages = [
  _TutorialPage(
    Icons.sports_esports,
    'Selamat datang!',
    'Monster berjatuhan dari langit. Tembak mereka sebelum mendarat dan '
        'menyerangmu dari tanah.',
  ),
  _TutorialPage(
    Icons.swipe,
    'Bergerak & menembak',
    'Joystick kiri menggerakkan Asha. '
        'Panah ditembakkan otomatis ke atas.',
  ),
  _TutorialPage(
    Icons.arrow_upward,
    'Lompat',
    'Ketuk layar atau tekan tombol Lompat untuk menghindari serangan darat '
        'dan hantaman musuh. Perhatikan tanda laser sebelum menembak!',
  ),
  _TutorialPage(
    Icons.flash_on,
    'Skill',
    'Melee memukul musuh yang sudah mendarat di dekatmu. Skill1 menyerang '
        'semua musuh, Skill2 memperlambat semuanya. Tunggu cooldown sebelum '
        'memakainya lagi.',
  ),
  _TutorialPage(
    Icons.whatshot,
    'Rage & Ulti',
    'Bar RAGE terisi saat kamu menyerang. Saat penuh, damage dan kecepatanmu '
        'naik. Saat bar ULT penuh, tekan Ulti untuk menghantam semua musuh.',
  ),
  _TutorialPage(
    Icons.emoji_events,
    'Wave & Boss',
    'Setiap area punya 15 wave. Pilih upgrade setelah wave 5 dan 10, lawan '
        'mini-boss di wave 10 dan boss di wave 15. Progres tersimpan otomatis '
        'di awal setiap wave.',
  ),
];

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final page = _tutorialPages[_page];
    final last = _page == _tutorialPages.length - 1;
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          color: const Color(0xff1c1c28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'TUTORIAL',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: widget.onDone,
                        child: const Text('LEWATI'),
                      ),
                  ],
                ),
                Icon(page.icon, size: 56, color: Colors.amber),
                const SizedBox(height: 12),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _tutorialPages.length; i++)
                      Container(
                        width: i == _page ? 18 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page ? Colors.amber : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        onPressed: () => setState(() => _page -= 1),
                        child: const Text('KEMBALI'),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: last
                          ? widget.onDone
                          : () => setState(() => _page += 1),
                      child: Text(last ? 'MAIN!' : 'LANJUT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
