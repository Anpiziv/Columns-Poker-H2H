import 'game_state.dart';
import 'card.dart';
import 'simulation.dart';
import 'game_rules.dart';

class MonteCarloBot {
  final int simulations;

  MonteCarloBot({this.simulations = 200});

  GameState _sampleVisibleState(GameState state, Card currentCard) {
    final visible = GameState.clone(state);
    final hiddenColumnIndexes = <int>[];

    for (int index = 0; index < visible.p1.length; index++) {
      final column = visible.p1[index];
      if (column.cards.length >= 5) {
        column.cards.removeLast();
        hiddenColumnIndexes.add(index);
      }
    }

    final unknownCards = _allCards()
        .where((candidate) =>
            !_containsCard(visible, candidate) &&
            !_sameCard(candidate, currentCard))
        .toList()
      ..shuffle();

    for (final columnIndex in hiddenColumnIndexes) {
      visible.p1[columnIndex].add(unknownCards.removeLast());
    }

    visible.deckRemaining
      ..clear()
      ..addAll(unknownCards);
    return visible;
  }

  List<Card> _allCards() {
    return [
      for (final suit in Suit.values)
        for (int rank = 2; rank <= 14; rank++) Card(rank, suit),
    ];
  }

  bool _containsCard(GameState state, Card candidate) {
    final boardCards = [
      ...state.p1.expand((column) => column.cards),
      ...state.p2.expand((column) => column.cards),
    ];
    return boardCards.any((card) => _sameCard(card, candidate));
  }

  bool _sameCard(Card first, Card second) {
    return first.rank == second.rank && first.suit == second.suit;
  }

  bool _isLegalColumn(GameState state, int col, int player) {
    final columns = player == 1 ? state.p1 : state.p2;
    final used = player == 1 ? state.p1UsedThisRound : state.p2UsedThisRound;

    return columns[col].cards.length == state.roundNumber - 1 &&
        !used.contains(col) &&
        columns[col].cards.length < 5;
  }

  int chooseMove(GameState state, Card card, int player) {
    double bestScore = -1e9;
    int bestColumn = -1;

    for (int col = 0; col < 5; col++) {
      if (!_isLegalColumn(state, col, player)) continue;

      double wins = 0;

      for (int i = 0; i < simulations; i++) {
        final sim = _sampleVisibleState(state, card);

        final simCol = player == 1 ? sim.p1[col] : sim.p2[col];
        simCol.add(card);

        final used = player == 1 ? sim.p1UsedThisRound : sim.p2UsedThisRound;
        used.add(col);

        Simulation.runToEnd(sim);

        final result = GameRules.winner(sim);

        if (player == 1 && result == 1) wins++;
        if (player == 2 && result == 2) wins++;
      }

      final score = wins / simulations;

      if (score > bestScore) {
        bestScore = score;
        bestColumn = col;
      }
    }

    return bestColumn;
  }
}
