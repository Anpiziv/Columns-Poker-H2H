import 'dart:math';
import 'game_state.dart';

class Simulation {
  static final Random _rng = Random();

  static void runToEnd(GameState state) {
    final deck = state.deckRemaining;

    while (deck.isNotEmpty && !_isBoardFull(state)) {
      if (state.p1UsedThisRound.length == 5 &&
          state.p2UsedThisRound.length == 5) {
        state.roundNumber++;
        state.p1UsedThisRound.clear();
        state.p2UsedThisRound.clear();
      }

      final players = <int>[];
      if (state.p1UsedThisRound.length < 5 &&
          _legalColumns(state, 1).isNotEmpty) {
        players.add(1);
      }
      if (state.p2UsedThisRound.length < 5 &&
          _legalColumns(state, 2).isNotEmpty) {
        players.add(2);
      }

      if (players.isEmpty) break;

      final card = deck.removeLast();
      final player = players[_rng.nextInt(players.length)];
      final legalColumns = _legalColumns(state, player);
      final columnIndex = legalColumns[_rng.nextInt(legalColumns.length)];
      final columns = player == 1 ? state.p1 : state.p2;
      final used = player == 1 ? state.p1UsedThisRound : state.p2UsedThisRound;

      columns[columnIndex].add(card);
      used.add(columnIndex);
    }

    _runFinalExchanges(state);
  }

  static bool _isBoardFull(GameState state) {
    return state.p1.every((column) => column.cards.length == 5) &&
        state.p2.every((column) => column.cards.length == 5);
  }

  static List<int> _legalColumns(GameState state, int player) {
    final columns = player == 1 ? state.p1 : state.p2;
    final used = player == 1 ? state.p1UsedThisRound : state.p2UsedThisRound;

    return [
      for (int index = 0; index < columns.length; index++)
        if (columns[index].cards.length == state.roundNumber - 1 &&
            columns[index].cards.length < 5 &&
            !used.contains(index))
          index,
    ];
  }

  static void _runFinalExchanges(GameState state) {
    if (!_isBoardFull(state)) {
      state.deckRemaining.clear();
      return;
    }

    for (final columns in [state.p1, state.p2]) {
      if (state.deckRemaining.isEmpty) return;

      final drawnCard = state.deckRemaining.removeLast();
      if (_rng.nextBool()) {
        final columnIndex = _rng.nextInt(5);
        columns[columnIndex].cards[4] = drawnCard;
      }
    }

    state.deckRemaining.clear();
  }
}
