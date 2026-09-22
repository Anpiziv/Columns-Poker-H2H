import 'card.dart';

class HandValue implements Comparable<HandValue> {
  final int rank;
  final List<int> kickers;

  const HandValue(this.rank, this.kickers);

  @override
  int compareTo(HandValue other) {
    if (rank != other.rank) return rank.compareTo(other.rank);

    for (int i = 0; i < kickers.length; i++) {
      if (i >= other.kickers.length) return 1;
      if (kickers[i] != other.kickers[i]) {
        return kickers[i].compareTo(other.kickers[i]);
      }
    }

    return 0;
  }
}

class PokerEvaluator {
  static HandValue evaluate(List<Card> cards) {
    if (cards.isEmpty) {
      return const HandValue(-1, []);
    }

    final sorted = [...cards]..sort((a, b) => b.rank.compareTo(a.rank));

    final isFlush = _isFlush(sorted);
    final straightHigh = _straightHigh(sorted);

    final groups = _groupByRank(sorted);

    final counts = groups.values.toList()
      ..sort((a, b) {
        if (a.length != b.length) return b.length.compareTo(a.length);
        return b.first.rank.compareTo(a.first.rank);
      });

    if (cards.length >= 5 && isFlush && straightHigh != null) {
      return HandValue(8, [straightHigh]);
    }

    if (counts[0].length == 4) {
      final quad = counts[0].first.rank;
      final kicker = counts.length > 1 ? counts[1].first.rank : 0;
      return HandValue(7, [quad, kicker]);
    }

    if (counts.length > 1 && counts[0].length == 3 && counts[1].length == 2) {
      return HandValue(6, [counts[0].first.rank, counts[1].first.rank]);
    }

    if (cards.length >= 5 && isFlush) {
      return HandValue(5, sorted.map((c) => c.rank).toList());
    }

    if (cards.length >= 5 && straightHigh != null) {
      return HandValue(4, [straightHigh]);
    }

    if (counts[0].length == 3) {
      final trips = counts[0].first.rank;
      final kickers = counts
          .skip(1)
          .expand((g) => g.map((c) => c.rank))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      return HandValue(3, [trips, ...kickers]);
    }

    if (counts.length > 1 && counts[0].length == 2 && counts[1].length == 2) {
      final highPair = counts[0].first.rank;
      final lowPair = counts[1].first.rank;
      final kicker = counts.length > 2 ? counts[2].first.rank : 0;

      return HandValue(2, [highPair, lowPair, kicker]);
    }

    if (counts[0].length == 2) {
      final pair = counts[0].first.rank;

      final kickers = counts
          .skip(1)
          .expand((g) => g.map((c) => c.rank))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      return HandValue(1, [pair, ...kickers]);
    }

    return HandValue(0, sorted.map((c) => c.rank).toList());
  }

  static bool _isFlush(List<Card> cards) {
    if (cards.isEmpty) return false;
    final suit = cards.first.suit;
    return cards.every((c) => c.suit == suit);
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

  static Map<int, List<Card>> _groupByRank(List<Card> cards) {
    final map = <int, List<Card>>{};

    for (final c in cards) {
      map.putIfAbsent(c.rank, () => []).add(c);
    }

    return map;
  }
}
