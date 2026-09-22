enum Suit { hearts, diamonds, clubs, spades }

class Card {
  final int rank; // 2-14 (A = 14)
  final Suit suit;

  const Card(this.rank, this.suit);

  @override
  String toString() => "$rank-$suit";
}
