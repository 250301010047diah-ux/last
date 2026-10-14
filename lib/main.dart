import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/data.dart';
import 'game/game.dart';
import 'ui/action_button.dart';
import 'ui/main_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The game world is a fixed 360x640 portrait field.
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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
                Text(game.combat?.area.name ?? '',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                if (wave > 1) ...[
                  const SizedBox(height: 4),
                  Text('Lanjut dari Wave $wave',
                      style: const TextStyle(fontSize: 15, color: Colors.amber)),
                ],
                if (game.tutorialPending) ...[
                  const SizedBox(height: 6),
                  const Text('TUTORIAL LATIHAN',
                      style: TextStyle(
                          fontSize: 15,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber)),
                ],
                const SizedBox(height: 8),
                Text(game.tutorialPending ? 'TAP UNTUK MULAI LATIHAN' : 'TAP UNTUK BERMAIN',
                    style: const TextStyle(fontSize: 18, color: Colors.white70)),
              ],
            ),
          ),
        );
      case GamePhase.playing:
        return _playingHud();
      case GamePhase.upgrade:
        return _upgradeScreen();
      case GamePhase.gameover:
        return _centerCard(
          title: 'GAME OVER',
          subtitle: 'Skor: ${game.combat?.score.round() ?? 0}\n'
              'Skor terbaik: ${game.save.bestScore}',
          button: 'ULANGI',
          onTap: () => game.restart(),
        );
      case GamePhase.victory:
        return _centerCard(
          title: 'AREA CLEAR',
          subtitle: 'Skor: ${game.combat?.score.round() ?? 0}\n'
              'Skor terbaik: ${game.save.bestScore}',
          button: 'LANJUT',
          onTap: () => game.startArea(
              (game.activeArea + 1).clamp(0, AREAS.length - 1), false),
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
          const Text('Memuat...',
              style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap,
      {double size = 30}) {
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
        _iconBtn(Icons.help_outline, 'Tutorial', () => _openPanel(_Panel.tutorial)),
        if (withPause)
          _iconBtn(Icons.pause_circle_filled, 'Jeda', () => game.pauseGame(),
              size: 34),
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
            child: Text(okLabel, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _startNewRun() async {
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
            Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(button, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                game.audio.play('click');
                game.quitToMenu();
              },
              child: const Text('MENU', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playingHud() {
    final w = game.combat!;
    final p = w.player;
    return SafeArea(
      child: Stack(
        children: [
          // Informational layer (non-interactive)
          IgnorePointer(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      Text(game.inTutorial ? 'Latihan' : 'Wave ${w.wave}',
                          style: const TextStyle(fontSize: 16)),
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
                              color: Color.lerp(Colors.white, const Color(0xffffc93c), k),
                              shadows: [
                                Shadow(
                                  color: const Color(0xffff9a1f).withValues(alpha: k),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                      Text('${w.runCoins}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                if (game.banner.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(game.banner,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _bar('RAGE', p.rage / 100, Colors.orange),
                      _bar('ULT', p.ultimate / 100, Colors.cyanAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 112),
              ],
            ),
          ),
          // Volume / tutorial / pause (interactive), below the top bar so they
          // don't cover the score.
          Positioned(top: 36, right: 4, child: _settingsButtons(withPause: true)),
          if (game.inTutorial)
            Positioned(top: 88, left: 12, right: 12, child: _tutorialCard()),
          // Action buttons (interactive)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _actionBtn('Lompat', Icons.keyboard_double_arrow_up_rounded,
                    const Color(0xff5ee7ff), () => game.combat?.jump(),
                    enabled: p.jump <= 0.5),
                _actionBtn('Melee', Icons.flare_rounded, const Color(0xffff8a3d),
                    () => game.combat?.useAction('melee'),
                    cooldown: p.meleeCooldown, cooldownMax: p.meleeCooldownMax,
                    enabled: p.jump <= 10),
                _actionBtn('Skill1', Icons.bolt_rounded, const Color(0xffffe45c),
                    () => game.combat?.useAction('skill1'),
                    cooldown: p.skillOneCooldown, cooldownMax: p.skillOneCooldownMax),
                _actionBtn('Skill2', Icons.ac_unit_rounded, const Color(0xff8fd8ff),
                    () => game.combat?.useAction('skill2'),
                    cooldown: p.skillTwoCooldown, cooldownMax: p.skillTwoCooldownMax),
                _actionBtn('Ulti', Icons.whatshot_rounded, const Color(0xffff5fd2),
                    () => game.combat?.useAction('ultimate'),
                    charge: p.ultimate / 100, size: 66),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pauseMenu() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('JEDA',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            _settingsButtons(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                game.audio.play('click');
                game.resumeGame();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              ),
              child: const Text('LANJUT', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                game.audio.play('click');
                game.resumeGame();
                game.restart();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              ),
              child: const Text('ULANGI', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                game.audio.play('click');
                game.quitToMenu();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              ),
              child: const Text('MENU', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            const Text('Progres tersimpan otomatis setiap awal wave',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _volumePanel() {
    final audio = game.audio;
    Widget row(IconData icon, String label, double value,
        ValueChanged<double> onChanged, ValueChanged<double> onEnd) {
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
            child: Text('${(value * 100).round()}%', textAlign: TextAlign.right),
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
                const Text('VOLUME',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                row(Icons.music_note, 'Musik', audio.bgmVolume, (v) {
                  setState(() => audio.setBgmVolume(v));
                }, game.setBgmVolume),
                row(Icons.volume_up, 'Efek', audio.sfxVolume, (v) {
                  setState(() => audio.setSfxVolume(v));
                }, (v) {
                  game.setSfxVolume(v);
                  game.audio.play('click');
                }),
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
          color: done ? Colors.greenAccent : Colors.amber.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (done ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.25),
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
                style: const TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.amber),
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
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
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
            child: Text(info[1],
                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3)),
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
    final wanted = game.inTutorial &&
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
        SizedBox(width: 42, child: Text(label, style: const TextStyle(fontSize: 12))),
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
            const Text('PILIH UPGRADE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            for (final u in game.upgradeChoicesList)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    game.audio.play('select');
                    game.chooseUpgrade(u.id);
                  },
                  child: Text('${u.label} — ${u.detail}'),
                ),
              ),
            const SizedBox(height: 12),
            Text('Skor: ${w.score.round()}', style: const TextStyle(color: Colors.white70)),
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
  _TutorialPage(Icons.sports_esports, 'Selamat datang!',
      'Monster berjatuhan dari langit. Tembak mereka sebelum mendarat dan '
          'menyerangmu dari tanah.'),
  _TutorialPage(Icons.swipe, 'Bergerak & menembak',
      'Geser jari ke kiri atau kanan di layar untuk menggerakkan Asha. '
          'Panah ditembakkan otomatis ke atas.'),
  _TutorialPage(Icons.arrow_upward, 'Lompat',
      'Ketuk layar atau tekan tombol Lompat untuk menghindari serangan darat '
          'dan hantaman musuh. Perhatikan tanda laser sebelum menembak!'),
  _TutorialPage(Icons.flash_on, 'Skill',
      'Melee memukul musuh yang sudah mendarat di dekatmu. Skill1 menyerang '
          'semua musuh, Skill2 memperlambat semuanya. Tunggu cooldown sebelum '
          'memakainya lagi.'),
  _TutorialPage(Icons.whatshot, 'Rage & Ulti',
      'Bar RAGE terisi saat kamu menyerang. Saat penuh, damage dan kecepatanmu '
          'naik. Saat bar ULT penuh, tekan Ulti untuk menghantam semua musuh.'),
  _TutorialPage(Icons.emoji_events, 'Wave & Boss',
      'Setiap area punya 15 wave. Pilih upgrade setelah wave 5 dan 10, lawan '
          'mini-boss di wave 10 dan boss di wave 15. Progres tersimpan otomatis '
          'di awal setiap wave.'),
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
                    const Text('TUTORIAL',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const Spacer(),
                    if (!last)
                      TextButton(onPressed: widget.onDone, child: const Text('LEWATI')),
                  ],
                ),
                Icon(page.icon, size: 56, color: Colors.amber),
                const SizedBox(height: 12),
                Text(page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(page.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.4)),
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
                      onPressed: last ? widget.onDone : () => setState(() => _page += 1),
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
