import 'card.dart';
import 'column.dart';

class GameState {
  List<Column> p1;
  List<Column> p2;

  int roundNumber;
  Set<int> p1UsedThisRound;
  Set<int> p2UsedThisRound;

  final List<Card> deckRemaining;

  GameState(this.deckRemaining)
      : p1 = List.generate(5, (_) => Column()),
        p2 = List.generate(5, (_) => Column()),
        roundNumber = 2,
        p1UsedThisRound = <int>{},
        p2UsedThisRound = <int>{};

  GameState.clone(GameState other)
      : p1 = other.p1.map((c) => Column()..cards.addAll(c.cards)).toList(),
        p2 = other.p2.map((c) => Column()..cards.addAll(c.cards)).toList(),
        roundNumber = other.roundNumber,
        p1UsedThisRound = Set<int>.from(other.p1UsedThisRound),
        p2UsedThisRound = Set<int>.from(other.p2UsedThisRound),
        deckRemaining = List.of(other.deckRemaining);
}
