import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/data.dart';
import '../game/game.dart';

/// Brand palette taken from the logo; the menu always uses it, whatever theme
/// or skin is selected, so the title screen looks the same every time.
const Color _gold = Color(0xffe8b04a);
const Color _cyan = Color(0xff5ee7ff);

/// Title screen drawn over the game canvas. The middle of the screen is left
/// open so the selected skin (rendered by [RuntuhGame]) stays visible.
class MainMenu extends StatefulWidget {
  const MainMenu({
    super.key,
    required this.game,
    required this.onVolume,
    required this.onHelp,
    required this.onStart,
    required this.onContinue,
    required this.onReset,
  });

  final RuntuhGame game;
  final VoidCallback onVolume;
  final VoidCallback onHelp;
  final VoidCallback onStart;
  final VoidCallback onContinue;
  final VoidCallback onReset;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  RuntuhGame get game => widget.game;

  @override
  void dispose() {
    _pulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  /// Fade + slide a section in, staggered by [start] (0..1 of the intro).
  Widget _enter(double start, Offset from, Widget child) {
    final curve = CurvedAnimation(
      parent: _intro,
      curve: Interval(
        start,
        (start + 0.6).clamp(0, 1),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: from, end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  }

  void _changeSkin(int delta) {
    game.audio.play('select');
    game.selectSkin(game.selectedSkin + delta);
  }

  void _changeTheme(int delta) {
    game.audio.play('select');
    game.selectTheme(game.selectedTheme + delta);
  }

  void _unlock(bool skin) {
    final success = skin
        ? game.unlockSelectedSkin()
        : game.unlockSelectedArea();
    game.audio.play(success ? 'select' : 'click');
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koin belum cukup untuk membuka pilihan ini.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = _gold;
    return Stack(
      children: [
        // Dark at the top and bottom for text, clear in the middle for the
        // character and background art.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.88),
                ],
                stops: const [0, 0.32, 0.5, 0.72],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: _content(accent),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(Color accent) {
    final skin = SKINS[game.selectedSkin];
    final cp = game.checkpoint;
    return Column(
      children: [
        _enter(0, const Offset(0, -0.4), _topBar()),
        const SizedBox(height: 10),
        _enter(0.1, const Offset(0, -0.3), _title(accent)),
        // Character zone: the game draws the selected skin here.
        Expanded(
          child: _enter(
            0.3,
            Offset.zero,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkinArrow(
                    left: true,
                    accent: _cyan,
                    pulse: _pulse,
                    onTap: () => _changeSkin(-1),
                  ),
                  _SkinArrow(
                    left: false,
                    accent: _cyan,
                    pulse: _pulse,
                    onTap: () => _changeSkin(1),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Fixed heights so browsing skins/themes never shifts the layout.
        SizedBox(
          height: 98,
          child: _enter(0.35, const Offset(0, 0.3), _skinInfo(skin, accent)),
        ),
        if (!game.isSkinUnlocked(game.selectedSkin))
          TextButton.icon(
            onPressed: () => _unlock(true),
            icon: const Icon(Icons.lock_open_rounded, size: 16),
            label: Text('Buka skin · ${game.selectedSkin * 100} koin'),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: _enter(0.45, const Offset(0, 0.3), _themePicker(accent)),
        ),
        if (!game.isAreaUnlocked(game.selectedTheme))
          TextButton.icon(
            onPressed: () => _unlock(false),
            icon: const Icon(Icons.lock_open_rounded, size: 16),
            label: Text('Buka area · ${game.selectedTheme * 150} koin'),
          ),
        const SizedBox(height: 18),
        _enter(
          0.55,
          const Offset(0, 0.3),
          Column(
            children: [
              if (cp != null) ...[
                _GlowButton(
                  pulse: _pulse,
                  icon: Icons.play_arrow_rounded,
                  label: 'LANJUTKAN',
                  sublabel:
                      '${AREAS[cp.area.clamp(0, AREAS.length - 1)].name} · Wave '
                      '${cp.pendingUpgrade ? cp.wave + 1 : cp.wave}',
                  colors: const [Color(0xffffc04a), Color(0xffff7a18)],
                  onTap: widget.onContinue,
                ),
                const SizedBox(height: 10),
                _GlowButton(
                  icon: Icons.refresh_rounded,
                  label:
                      game.isSkinUnlocked(game.selectedSkin) &&
                          game.isAreaUnlocked(game.selectedTheme)
                      ? 'MULAI BARU'
                      : 'TERKUNCI',
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.12),
                  ],
                  borderColor: accent.withValues(alpha: 0.7),
                  compact: true,
                  onTap: widget.onStart,
                ),
              ] else
                _GlowButton(
                  pulse: _pulse,
                  icon: Icons.play_arrow_rounded,
                  label:
                      game.isSkinUnlocked(game.selectedSkin) &&
                          game.isAreaUnlocked(game.selectedTheme)
                      ? 'MULAI'
                      : 'TERKUNCI',
                  colors: [accent, Color.lerp(accent, Colors.black, 0.45)!],
                  onTap: widget.onStart,
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _enter(
          0.65,
          Offset.zero,
          TextButton.icon(
            onPressed: game.save.unlimitedCoins
                ? null
                : () {
                    game.audio.play('click');
                    game.unlockEverything();
                  },
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              game.save.unlimitedCoins
                  ? 'SEMUA TERBUKA · KOIN ∞'
                  : '999999+ KOIN & BUKA SEMUA',
            ),
            style: TextButton.styleFrom(foregroundColor: _cyan),
          ),
        ),
        _enter(
          0.7,
          Offset.zero,
          TextButton.icon(
            onPressed: widget.onReset,
            style: TextButton.styleFrom(foregroundColor: Colors.white38),
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text('Reset progres', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _Glass(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: Color(0xffffd54f),
              ),
              const SizedBox(width: 6),
              Text(
                '${game.save.bestScore}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.monetization_on_rounded,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 6),
              Text(
                game.save.unlimitedCoins
                    ? '999999+ ∞'
                    : '${game.save.totalCoins}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _glassIcon(Icons.volume_up_rounded, 'Volume', widget.onVolume),
        const SizedBox(width: 8),
        _glassIcon(Icons.help_outline_rounded, 'Tutorial', widget.onHelp),
      ],
    );
  }

  Widget _glassIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: _Glass(
        radius: 22,
        onTap: onTap,
        padding: const EdgeInsets.all(9),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }

  Widget _title(Color accent) {
    final size = (MediaQuery.sizeOf(context).height * 0.25).clamp(120.0, 210.0);
    final logo = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      cacheWidth: 520,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Magitech Siege',
    );
    return AnimatedBuilder(
      animation: _pulse,
      child: logo,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.10 + 0.12 * t),
                blurRadius: 40 + 20 * t,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  Widget _skinInfo(Skin skin, Color accent) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(game.selectedSkin),
        children: [
          Text(
            'SKIN ${(game.selectedSkin + 1).toString().padLeft(2, '0')} / ${SKINS.length}'
            '${game.isSkinUnlocked(game.selectedSkin) ? '' : '  🔒 TERKUNCI'}',
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 3,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              skin.name.toUpperCase(),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    skin.buffLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themePicker(Color accent) {
    final area = AREAS[game.selectedTheme];
    return _Glass(
      radius: 18,
      borderColor: accent.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeTheme(-1),
            icon: Icon(Icons.chevron_left_rounded, color: accent, size: 30),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey(game.selectedTheme),
                children: [
                  Text(
                    'TEMA  ${(game.selectedTheme + 1).toString().padLeft(2, '0')} / ${AREAS.length}'
                    '${game.isAreaUnlocked(game.selectedTheme) ? '' : '  🔒 TERKUNCI'}',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: accent.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    area.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    area.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeTheme(1),
            icon: Icon(Icons.chevron_right_rounded, color: accent, size: 30),
          ),
        ],
      ),
    );
  }
}

/// Skin selector arrow: a glowing diamond crystal with a double chevron that
/// nudges outward in time with the menu pulse and squashes when pressed.
class _SkinArrow extends StatefulWidget {
  const _SkinArrow({
    required this.left,
    required this.accent,
    required this.pulse,
    required this.onTap,
  });

  final bool left;
  final Color accent;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  State<_SkinArrow> createState() => _SkinArrowState();
}

class _SkinArrowState extends State<_SkinArrow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    const box = 46.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      child: Padding(
        // Room for the rotated diamond's corners and its glow.
        padding: const EdgeInsets.all(12),
        child: AnimatedScale(
          scale: _pressed ? 0.84 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: widget.pulse,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(widget.pulse.value);
              final glow = _pressed ? 1.0 : t;
              return Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: box,
                  height: box,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          accent,
                          Colors.black,
                          0.55,
                        )!.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.75),
                        accent.withValues(alpha: 0.45 + 0.25 * glow),
                      ],
                    ),
                    border: Border.all(
                      color: Color.lerp(accent, Colors.white, 0.25 * glow)!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35 + 0.35 * glow),
                        blurRadius: 10 + 10 * glow,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Inner rune ring.
                        Container(
                          width: box * 0.78,
                          height: box * 0.78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(
                                alpha: 0.25 + 0.2 * glow,
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset((widget.left ? -1 : 1) * 3 * t, 0),
                          child: Icon(
                            widget.left
                                ? Icons.keyboard_double_arrow_left_rounded
                                : Icons.keyboard_double_arrow_right_rounded,
                            size: 28,
                            color: Colors.white,
                            shadows: [Shadow(color: accent, blurRadius: 10)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass panel that blurs the game canvas behind it.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: BorderSide(
              color: borderColor ?? Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: shape,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Full-width gradient button; with [pulse] it gets a breathing glow.
class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.sublabel,
    this.pulse,
    this.borderColor,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String? sublabel;
  final List<Color> colors;
  final VoidCallback onTap;
  final Animation<double>? pulse;
  final Color? borderColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget button(double t) {
      final shape = BorderRadius.circular(16);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: shape,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.35),
          ),
          boxShadow: pulse == null
              ? null
              : [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.35 + 0.3 * t),
                    blurRadius: 14 + 12 * t,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 11 : 14,
                horizontal: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: compact ? 22 : 30, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: compact ? 15 : 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                        if (sublabel != null)
                          Text(
                            sublabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final p = pulse;
    if (p == null) return button(0);
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) => button(Curves.easeInOut.transform(p.value)),
    );
  }
}
