import 'dart:math';

import 'engine/card.dart';
import 'engine/deck.dart';
import 'engine/game_rules.dart';
import 'engine/game_state.dart';
import 'engine/monte_carlo_bot.dart';

class GameLogEntry {
  const GameLogEntry({
    required this.round,
    required this.message,
    this.concealedMessage,
  });

  final int round;
  final String message;
  // Shown instead of [message] while the bot's final card stays hidden.
  final String? concealedMessage;
}

class FinalDiscard {
  const FinalDiscard({required this.isHuman, required this.card});

  final bool isHuman;
  final Card card;
}

class LocalChinesePokerGame {
  late Deck deck;
  late GameState state;
  late MonteCarloBot bot;

  Card? currentCard;
  final List<FinalDiscard> finalDiscards = [];
  final List<GameLogEntry> moveLog = [];
  bool isHumanTurn = true;
  bool humanGoesFirst = true;
  bool isGameFinished = false;
  bool isFinalExchangePhase = false;
  int? selectedExchangeColumn;
  String statusText = 'Your turn';

  void startNewGame() {
    deck = Deck.standard(seed: DateTime.now().millisecondsSinceEpoch);
    state = GameState(deck.cards);
    bot = MonteCarloBot(simulations: 50);
    currentCard = null;
    finalDiscards.clear();
    moveLog.clear();
    isGameFinished = false;
    isFinalExchangePhase = false;
    selectedExchangeColumn = null;
    state.p1UsedThisRound.clear();
    state.p2UsedThisRound.clear();

    humanGoesFirst = Random().nextBool();
    _log(
      humanGoesFirst ? 'You go first this game.' : 'Bot goes first this game.',
      round: 1,
    );

    _dealInitialColumns();
    state.roundNumber = 2;

    if (humanGoesFirst) {
      isHumanTurn = true;
      statusText = 'Your turn. Draw a card.';
      drawHumanCard();
    } else {
      isHumanTurn = false;
      statusText = 'Bot goes first this game. Bot is thinking...';
    }
  }

  void _log(String message, {int? round, String? concealedMessage}) {
    moveLog.add(
      GameLogEntry(
        round: round ?? state.roundNumber,
        message: message,
        concealedMessage: concealedMessage,
      ),
    );
  }

  void _dealInitialColumns() {
    for (int i = 0; i < 5; i++) {
      final firstCard = deck.draw();
      final secondCard = deck.draw();

      final humanCard = humanGoesFirst ? firstCard : secondCard;
      final botCard = humanGoesFirst ? secondCard : firstCard;

      state.p1[i].add(humanCard);
      state.p2[i].add(botCard);

      // Mention whoever is dealt to first, matching real deal order.
      _log(
        humanGoesFirst
            ? 'Initial deal — Column ${i + 1}: You got ${describeCard(humanCard)}, '
                'Bot got ${describeCard(botCard)}.'
            : 'Initial deal — Column ${i + 1}: Bot got ${describeCard(botCard)}, '
                'You got ${describeCard(humanCard)}.',
        round: 1,
      );
    }
  }

  bool _isColumnLegalForPlayer(int player, int columnIndex) {
    final columns = player == 1 ? state.p1 : state.p2;
    final used = player == 1 ? state.p1UsedThisRound : state.p2UsedThisRound;

    if (columnIndex < 0 || columnIndex >= 5) return false;
    if (columns[columnIndex].cards.length != state.roundNumber - 1) {
      return false;
    }
    if (used.contains(columnIndex)) return false;
    return true;
  }

  void _advanceRoundIfNeeded() {
    if (state.p1UsedThisRound.length == 5 &&
        state.p2UsedThisRound.length == 5) {
      state.roundNumber++;
      state.p1UsedThisRound.clear();
      state.p2UsedThisRound.clear();
    }
  }

  void drawHumanCard() {
    if (isGameFinished || deck.cards.isEmpty) {
      finishGame();
      return;
    }

    currentCard = deck.draw();
    isHumanTurn = true;
    statusText = 'Choose a column for ${describeCard(currentCard!)}.';
  }

  bool _allColumnsFull() {
    return state.p1.every((c) => c.cards.length == 5) &&
        state.p2.every((c) => c.cards.length == 5);
  }

  void beginFinalExchangePhase() {
    if (!_allColumnsFull() || deck.cards.isEmpty) {
      return;
    }

    isFinalExchangePhase = true;
    selectedExchangeColumn = null;

    if (humanGoesFirst) {
      currentCard = deck.draw();
      isHumanTurn = true;
      statusText = 'Optional: switch one final card, then press Set';
      _log('You go first for the final exchange.');
    } else {
      currentCard = null;
      isHumanTurn = false;
      statusText = 'Bot goes first for the final exchange. Bot is thinking...';
      _log('Bot goes first for the final exchange.');
    }
  }

  bool canHumanPlaceOnColumn(int columnIndex) {
    return _isColumnLegalForPlayer(1, columnIndex) &&
        currentCard != null &&
        !isGameFinished &&
        isHumanTurn &&
        !isFinalExchangePhase;
  }

  bool canHumanExchangeColumn(int columnIndex) {
    return isFinalExchangePhase &&
        isHumanTurn &&
        currentCard != null &&
        GameRules.canReplaceTopCard(state.p1, columnIndex);
  }

  bool placeHumanCard(int columnIndex) {
    if (!canHumanPlaceOnColumn(columnIndex)) {
      return false;
    }

    final placedCard = currentCard!;
    final roundOfPlacement = state.roundNumber;
    state.p1[columnIndex].add(placedCard);
    state.p1UsedThisRound.add(columnIndex);
    _log(
      'You placed ${describeCard(placedCard)} into column ${columnIndex + 1} '
      '(round $roundOfPlacement).',
    );
    currentCard = null;
    isHumanTurn = false;
    statusText = 'Bot is thinking...';

    _advanceRoundIfNeeded();

    if (_allColumnsFull() && deck.cards.isNotEmpty) {
      beginFinalExchangePhase();
      return true;
    }

    if (deck.cards.isEmpty) {
      finishGame();
    }
    return true;
  }

  bool chooseHumanExchangeColumn(int columnIndex) {
    if (!canHumanExchangeColumn(columnIndex)) {
      return false;
    }

    if (selectedExchangeColumn == columnIndex) {
      selectedExchangeColumn = null;
      statusText = 'No column selected. Press Set to keep your cards';
      return true;
    }

    selectedExchangeColumn = columnIndex;
    statusText =
        'Selected column ${columnIndex + 1}. Tap again to undo, then press Set';
    return true;
  }

  bool setHumanExchange() {
    if (!isFinalExchangePhase || !isHumanTurn || currentCard == null) {
      return false;
    }

    final current = currentCard!;

    if (selectedExchangeColumn != null) {
      final old = GameRules.applyTopCardExchange(
        state.p1,
        selectedExchangeColumn!,
        current,
      );

      if (old == null) {
        return false;
      }

      finalDiscards.add(FinalDiscard(isHuman: true, card: old));
      statusText =
          'You exchanged ${describeCard(old)} with ${describeCard(current)}';
      _log(
        'You exchanged ${describeCard(current)} into column '
        '${selectedExchangeColumn! + 1}, discarding ${describeCard(old)} '
        '(final exchange).',
      );
    } else {
      finalDiscards.add(FinalDiscard(isHuman: true, card: current));
      currentCard = null;
      statusText = 'You chose not to exchange';
      _log(
        'You kept your columns and discarded ${describeCard(current)} '
        '(final exchange).',
      );
    }

    currentCard = null;
    selectedExchangeColumn = null;
    isHumanTurn = false;

    if (deck.cards.isEmpty) {
      finishGame();
    }
    return true;
  }

  bool playBotTurn() {
    if (isGameFinished || deck.cards.isEmpty) {
      finishGame();
      return false;
    }

    if (isFinalExchangePhase) {
      return playBotExchange();
    }

    final botCard = deck.draw();
    final move = bot.chooseMove(state, botCard, 2);

    if (move == -1) {
      statusText = 'Illegal move by bot';
      _log('Bot had no legal move for ${describeCard(botCard)}.');
      return false;
    }

    final roundOfPlacement = state.roundNumber;
    state.p2[move].add(botCard);
    state.p2UsedThisRound.add(move);
    statusText = 'Bot placed ${describeCard(botCard)}.';
    final isFinalCardForColumn = state.p2[move].cards.length == 5;
    _log(
      'Bot placed ${describeCard(botCard)} into column ${move + 1} '
      '(round $roundOfPlacement).',
      concealedMessage: isFinalCardForColumn
          ? 'Bot placed a hidden card into column ${move + 1} '
              '(round $roundOfPlacement).'
          : null,
    );

    _advanceRoundIfNeeded();

    if (_allColumnsFull() && deck.cards.isNotEmpty) {
      beginFinalExchangePhase();
      return true;
    }

    if (deck.cards.isEmpty) {
      finishGame();
    }
    return true;
  }

  bool playBotExchange() {
    if (!isFinalExchangePhase || isGameFinished) {
      return false;
    }

    if (deck.cards.isEmpty) {
      statusText = 'Final exchange could not draw the opponent card';
      _log('Deck ran out before the bot could draw for the final exchange.');
      finishGame();
      return false;
    }

    final botDraw = deck.draw();
    int? bestColumn;
    int bestDiff = 0;

    for (int i = 0; i < 5; i++) {
      if (state.p2[i].cards.length != 5) continue;
      final topCard = state.p2[i].last;
      final diff = botDraw.rank - topCard.rank;

      if (diff > bestDiff) {
        bestDiff = diff;
        bestColumn = i;
      }
    }

    if (bestColumn != null) {
      final old = GameRules.applyTopCardExchange(
        state.p2,
        bestColumn,
        botDraw,
      );

      if (old == null) {
        statusText = 'Bot chose not to exchange';
        finalDiscards.add(FinalDiscard(isHuman: false, card: botDraw));
        _log(
          'Bot chose not to exchange, discarding ${describeCard(botDraw)} '
          '(final exchange).',
        );
      } else {
        finalDiscards.add(FinalDiscard(isHuman: false, card: old));
        statusText =
            'Bot exchanged ${describeCard(old)} with ${describeCard(botDraw)}';
        _log(
          'Bot exchanged ${describeCard(botDraw)} into column '
          '${bestColumn + 1}, discarding ${describeCard(old)} '
          '(final exchange).',
          concealedMessage:
              'Bot exchanged its final card in column ${bestColumn + 1} '
              '(hidden until reveal).',
        );
      }
    } else {
      finalDiscards.add(FinalDiscard(isHuman: false, card: botDraw));
      statusText = 'Bot chose not to exchange';
      _log(
        'Bot chose not to exchange, discarding ${describeCard(botDraw)} '
        '(final exchange).',
      );
    }

    if (humanGoesFirst) {
      // Bot concludes the exchange after the human already decided.
      isFinalExchangePhase = false;
      isHumanTurn = true;
      currentCard = null;

      if (deck.cards.isEmpty) {
        finishGame();
      } else {
        drawHumanCard();
      }
    } else {
      // Bot led the exchange; hand the last remaining card to the human.
      isHumanTurn = true;
      currentCard = deck.cards.isEmpty ? null : deck.draw();
      statusText = 'Optional: switch one final card, then press Set';

      if (currentCard == null) {
        finishGame();
      }
    }

    return true;
  }

  void finishGame() {
    isGameFinished = true;
    currentCard = null;

    final humanScore = scoreHuman();
    final botScore = scoreBot();

    if (humanScore > botScore) {
      statusText = 'You win! Final score: $humanScore-$botScore';
    } else if (botScore > humanScore) {
      statusText = 'Bot wins! Final score: $humanScore-$botScore';
    } else {
      statusText = 'Draw! Final score: $humanScore-$botScore';
    }
    _log('Game over — $statusText');
  }

  int scoreHuman() {
    int score = 0;
    for (int i = 0; i < 5; i++) {
      final result = GameRules.compareColumns(state.p1[i], state.p2[i]);
      if (result > 0) score++;
    }
    return score;
  }

  int scoreBot() {
    int score = 0;
    for (int i = 0; i < 5; i++) {
      final result = GameRules.compareColumns(state.p1[i], state.p2[i]);
      if (result < 0) score++;
    }
    return score;
  }

  static String describeCard(Card card) {
    final rankText = switch (card.rank) {
      14 => 'A',
      13 => 'K',
      12 => 'Q',
      11 => 'J',
      _ => card.rank.toString(),
    };

    final suitText = switch (card.suit) {
      Suit.hearts => '♥',
      Suit.diamonds => '♦',
      Suit.clubs => '♣',
      Suit.spades => '♠',
    };

    return '$rankText$suitText';
  }
}
