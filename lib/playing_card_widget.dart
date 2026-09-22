import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show rootBundle;
import 'package:palette_generator/palette_generator.dart';
import 'package:playing_cards/playing_cards.dart' as playing_cards;

import 'engine/card.dart' as engine;

class AppPlayingCard extends StatelessWidget {
  const AppPlayingCard({
    super.key,
    required this.card,
    this.comboColor,
    this.highlighted = false,
  });

  final engine.Card card;
  final Color? comboColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: highlighted
            ? Border.all(color: Colors.amber.shade700, width: 3)
            : null,
        borderRadius: BorderRadius.circular(7),
        boxShadow: highlighted
            ? const [
                BoxShadow(
                  color: Colors.amber,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: playing_cards.PlayingCardView(
        card: playing_cards.PlayingCard(
          _toPlayingSuit(card.suit),
          _toPlayingValue(card.rank),
        ),
        elevation: 2,
        style: playing_cards.PlayingCardViewStyle(
          cardBackgroundColor: comboColor ??
              (highlighted ? Colors.amber.shade100 : Colors.white),
          surfaceTintColor: highlighted ? Colors.amber.shade200 : null,
        ),
      ),
    );
  }

  playing_cards.Suit _toPlayingSuit(engine.Suit suit) {
    return switch (suit) {
      engine.Suit.spades => playing_cards.Suit.spades,
      engine.Suit.hearts => playing_cards.Suit.hearts,
      engine.Suit.diamonds => playing_cards.Suit.diamonds,
      engine.Suit.clubs => playing_cards.Suit.clubs,
    };
  }

  playing_cards.CardValue _toPlayingValue(int rank) {
    return switch (rank) {
      2 => playing_cards.CardValue.two,
      3 => playing_cards.CardValue.three,
      4 => playing_cards.CardValue.four,
      5 => playing_cards.CardValue.five,
      6 => playing_cards.CardValue.six,
      7 => playing_cards.CardValue.seven,
      8 => playing_cards.CardValue.eight,
      9 => playing_cards.CardValue.nine,
      10 => playing_cards.CardValue.ten,
      11 => playing_cards.CardValue.jack,
      12 => playing_cards.CardValue.queen,
      13 => playing_cards.CardValue.king,
      14 => playing_cards.CardValue.ace,
      _ => throw ArgumentError.value(
          rank, 'rank', 'Expected a standard card rank.'),
    };
  }
}

class AppHiddenPlayingCard extends StatelessWidget {
  const AppHiddenPlayingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return playing_cards.PlayingCardView(
      card: playing_cards.PlayingCard(
        playing_cards.Suit.spades,
        playing_cards.CardValue.ace,
      ),
      showBack: true,
      elevation: 2,
      style: playing_cards.PlayingCardViewStyle(
        cardBackContentBuilder: (context) => const _CardBackDesign(),
      ),
    );
  }
}

// Loads the optional custom card-back image once and caches the result.
// Call [ensureLoaded] as early as possible (e.g. app start) so the check
// finishes before the first hidden card ever needs to render.
class CardBackAssets {
  CardBackAssets._();

  // Drop a licensed image here (see assets/README.md) to replace this look.
  static const String customBackAssetPath = 'assets/card_back.png';

  static Future<void>? _loadFuture;
  static bool? available;
  static Color? backgroundColor;
  static Color? borderColor;

  static Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  static Future<void> _load() async {
    try {
      await rootBundle.load(customBackAssetPath);
      final palette = await PaletteGenerator.fromImageProvider(
        const AssetImage(customBackAssetPath),
      );
      final dominant = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color;
      available = true;
      if (dominant != null) {
        backgroundColor = _withLightness(dominant, 0.32);
        borderColor = _withLightness(dominant, 0.72);
      }
    } catch (_) {
      available = false;
    }
  }

  static Color _withLightness(Color color, double lightness) {
    return HSLColor.fromColor(color).withLightness(lightness).toColor();
  }
}

class _CardBackDesign extends StatefulWidget {
  const _CardBackDesign();

  @override
  State<_CardBackDesign> createState() => _CardBackDesignState();
}

class _CardBackDesignState extends State<_CardBackDesign> {
  @override
  void initState() {
    super.initState();
    if (CardBackAssets.available == null) {
      CardBackAssets.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = CardBackAssets.available == true;
    final backgroundColor =
        CardBackAssets.backgroundColor ?? const Color(0xff123b67);
    final borderColor = CardBackAssets.borderColor ?? const Color(0xffd9b45b);

    final content = available
        ? Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              CardBackAssets.customBackAssetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const _DefaultCardBackArt(),
            ),
          )
        : const _DefaultCardBackArt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 3),
        ),
        child: content,
      ),
    );
  }
}

class _DefaultCardBackArt extends StatelessWidget {
  const _DefaultCardBackArt();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CardBackPainter(),
      child: const Center(
        child: Icon(
          Icons.auto_awesome,
          color: Color(0xffe7c86e),
          size: 24,
        ),
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xff7da6cf)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;

    for (double inset = 8; inset < size.shortestSide / 2; inset += 8) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(inset),
          const Radius.circular(3),
        ),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_CardBackPainter oldDelegate) => false;
}
