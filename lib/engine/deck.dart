import 'dart:math';
import 'card.dart';

class Deck {
  final List<Card> cards;

  Deck._(this.cards);

  factory Deck.standard({int seed = 1}) {
    final rng = Random(seed);
    final cards = <Card>[];

    for (var s in Suit.values) {
      for (int r = 2; r <= 14; r++) {
        cards.add(Card(r, s));
      }
    }

    cards.shuffle(rng);
    return Deck._(cards);
  }

  Card draw() => cards.removeLast();
}
