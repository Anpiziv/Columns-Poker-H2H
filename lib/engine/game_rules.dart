import 'card.dart';
import 'column.dart';
import 'game_state.dart';
import 'poker.evaluate.dart';

class GameRules {
  static bool isBoardFull(GameState state) {
    return state.p1.every((column) => column.cards.length == 5) &&
        state.p2.every((column) => column.cards.length == 5);
  }

  static bool isTopCardHiddenForHuman({
    required bool isHumanBoard,
    required int columnLength,
    required bool revealFinalCards,
  }) {
    return !revealFinalCards && !isHumanBoard && columnLength >= 5;
  }

  static bool shouldHighlightTopCard(
      {required bool isHumanBoard, required int columnLength}) {
    return isHumanBoard && columnLength >= 5;
  }

  static bool canReplaceTopCard(List<Column> columns, int columnIndex) {
    if (columnIndex < 0 || columnIndex >= columns.length) return false;
    final column = columns[columnIndex];
    return column.cards.isNotEmpty && column.cards.length == 5;
  }

  static Card? applyTopCardExchange(
      List<Column> columns, int columnIndex, Card incomingCard) {
    if (!canReplaceTopCard(columns, columnIndex)) {
      return null;
    }

    final column = columns[columnIndex];
    final removedCard = column.cards.last;
    column.cards.removeLast();
    column.cards.add(incomingCard);
    return removedCard;
  }

  static String describeColumnWinner(Column humanColumn, Column botColumn) {
    final result = compareColumns(humanColumn, botColumn);

    if (humanColumn.cards.isEmpty && botColumn.cards.isEmpty) {
      return 'No showdown';
    }
    if (humanColumn.cards.isEmpty) {
      return '${_describeHand(botColumn.cards)}. Bot wins';
    }
    if (botColumn.cards.isEmpty) {
      return '${_describeHand(humanColumn.cards)}. You win';
    }
    if (result > 0) {
      return '${_describeHand(humanColumn.cards)}. You win';
    }
    if (result < 0) {
      return '${_describeHand(botColumn.cards)}. Bot wins';
    }
    return 'Tie: ${_describeHand(humanColumn.cards)}';
  }

  static String _describeHand(List<Card> cards) {
    if (cards.isEmpty) {
      return 'empty hand';
    }

    final sorted = [...cards]..sort((a, b) => b.rank.compareTo(a.rank));
    final groups = <int, List<Card>>{};
    for (final card in sorted) {
      groups.putIfAbsent(card.rank, () => []).add(card);
    }
    final groupedRanks = groups.values.toList()
      ..sort((a, b) {
        if (a.length != b.length) return b.length.compareTo(a.length);
        return b.first.rank.compareTo(a.first.rank);
      });

    final value = PokerEvaluator.evaluate(cards);
    switch (value.rank) {
      case 8:
        return 'straight flush to ${_rankText(sorted.first.rank)}';
      case 7:
        return 'four of a kind, ${_rankText(groupedRanks.first.first.rank)}s';
      case 6:
        return 'full house, ${_rankText(groupedRanks.first.first.rank)}s over ${_rankText(groupedRanks[1].first.rank)}s';
      case 5:
        return 'flush, high card ${_rankText(sorted.first.rank)}';
      case 4:
        {
          final straightHigh = _straightHigh(sorted);
          return 'straight to ${_rankText(straightHigh ?? sorted.first.rank)}';
        }
      case 3:
        return 'three of a kind, ${_rankText(groupedRanks.first.first.rank)}s';
      case 2:
        final pairRanks = groupedRanks
            .where((g) => g.length == 2)
            .map((g) => g.first.rank)
            .toList();
        final kickerCard = groupedRanks
            .where((g) => g.length == 1)
            .expand((g) => g)
            .firstOrNull;
        final kickerText = kickerCard == null
            ? ''
            : ', high card ${_rankText(kickerCard.rank)}';
        return 'two pair, ${_rankText(pairRanks[0])}s and ${_rankText(pairRanks[1])}s$kickerText';
      case 1:
        final pairRank = groupedRanks.first.first.rank;
        final kickerCard = sorted.where((c) => c.rank != pairRank).firstOrNull;
        if (kickerCard == null) {
          return 'pair of ${_rankText(pairRank)}s';
        }
        return 'pair of ${_rankText(pairRank)}s, kicker ${_rankText(kickerCard.rank)}';
      case 0:
        return 'high card ${_rankText(sorted.first.rank)}';
      default:
        return 'empty hand';
    }
  }

  static int? _straightHigh(List<Card> cards) {
    final ranks = cards.map((c) => c.rank).toSet().toList()..sort();
    if (ranks.contains(14) &&
        ranks.contains(2) &&
        ranks.contains(3) &&
        ranks.contains(4) &&
        ranks.contains(5)) {
      return 5;
    }
    for (int i = 0; i <= ranks.length - 5; i++) {
      bool ok = true;
      for (int j = 1; j < 5; j++) {
        if (ranks[i + j] != ranks[i] + j) {
          ok = false;
          break;
        }
      }
      if (ok) return ranks[i + 4];
    }
    return null;
  }

  static String _rankText(int rank) {
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      default:
        return rank.toString();
    }
  }

  static int compareColumns(Column a, Column b) {
    final isAEmpty = a.cards.isEmpty;
    final isBEmpty = b.cards.isEmpty;

    if (isAEmpty && isBEmpty) return 0;
    if (isAEmpty) return -1;
    if (isBEmpty) return 1;

    final va = PokerEvaluator.evaluate(a.cards);
    final vb = PokerEvaluator.evaluate(b.cards);

    return va.compareTo(vb);
  }

  static int scoreGame(GameState state) {
    int score = 0;

    for (int i = 0; i < 5; i++) {
      score += compareColumns(state.p1[i], state.p2[i]);
    }

    return score;
  }

  static int winner(GameState state) {
    final s = scoreGame(state);
    if (s > 0) return 1;
    if (s < 0) return 2;
    return 0;
  }
}
