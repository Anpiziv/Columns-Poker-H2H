import 'card.dart';

class Column {
  final List<Card> cards = [];

  void add(Card c) {
    if (cards.length >= 5) {
      throw Exception("Column full");
    }
    cards.add(c);
  }

  Card get last => cards.last;
}
