import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;

import 'engine/card.dart';
import 'engine/game_rules.dart';
import 'engine/poker.evaluate.dart';
import 'game_service.dart';
import 'playing_card_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final LocalChinesePokerGame _game = LocalChinesePokerGame();
  bool _botIsThinking = false;

  Set<int> _humanAvailableColumns() {
    if (_botIsThinking || _game.isGameFinished) {
      return <int>{};
    }

    final available = <int>{};
    for (int i = 0; i < 5; i++) {
      final canPlay = _game.isFinalExchangePhase
          ? _game.canHumanExchangeColumn(i)
          : _game.canHumanPlaceOnColumn(i);
      if (canPlay) {
        available.add(i);
      }
    }
    return available;
  }

  @override
  void initState() {
    super.initState();
    // Start loading the custom card back well before any hidden card renders.
    CardBackAssets.ensureLoaded();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _botIsThinking = false;
      _game.startNewGame();
    });

    if (!_game.humanGoesFirst) {
      _triggerBotTurn(alsoDrawHumanCard: true);
    }
  }

  void _triggerBotTurn({bool alsoDrawHumanCard = false}) {
    setState(() {
      _botIsThinking = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        _game.playBotTurn();
        _botIsThinking = false;
      });

      if (_game.isGameFinished) return;

      if (_game.isFinalExchangePhase && !_game.isHumanTurn) {
        // The bot just started the final exchange and must also lead it.
        _triggerBotTurn();
        return;
      }

      if (alsoDrawHumanCard && !_game.isFinalExchangePhase) {
        setState(() {
          _game.drawHumanCard();
        });
      }
    });
  }

  void _showGameBreakdown() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final entries = _game.moveLog;
            final revealHiddenCards = _game.isGameFinished;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Game breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(child: Text('No moves yet.'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final message = (!revealHiddenCards &&
                                    entry.concealedMessage != null)
                                ? entry.concealedMessage!
                                : entry.message;
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text(
                                  '${entry.round}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(message),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onHumanColumnTap(int columnIndex) {
    if (_botIsThinking || _game.isGameFinished) return;

    if (_game.isFinalExchangePhase) {
      if (!_game.canHumanExchangeColumn(columnIndex)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Illegal move')));
        return;
      }

      setState(() {
        _game.chooseHumanExchangeColumn(columnIndex);
      });
      return;
    }

    if (!_game.canHumanPlaceOnColumn(columnIndex)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Illegal move')));
      return;
    }

    setState(() {
      _game.placeHumanCard(columnIndex);
    });

    if (_game.isGameFinished) return;

    // If this placement just started the final exchange and it's the
    // human's turn to decide, wait for the Set button. If the bot should
    // lead the exchange instead, let it take its turn now.
    if (_game.isFinalExchangePhase && _game.isHumanTurn) return;

    _triggerBotTurn(alsoDrawHumanCard: true);
  }

  void _onSetPressed() {
    if (_botIsThinking || !_game.isFinalExchangePhase) return;

    setState(() {
      _game.setHumanExchange();
    });

    if (_game.isGameFinished) return;

    _triggerBotTurn();
  }

  @override
  Widget build(BuildContext context) {
    final summaryRows = _game.isGameFinished
        ? List.generate(5, (index) {
            final result = GameRules.compareColumns(
              _game.state.p1[index],
              _game.state.p2[index],
            );
            return _SummaryRow(
              text: GameRules.describeColumnWinner(
                _game.state.p1[index],
                _game.state.p2[index],
              ),
              isHumanWin: result > 0,
              isBotWin: result < 0,
            );
          })
        : const <_SummaryRow>[];
    final availableColumns = _humanAvailableColumns();
    final enablePinchZoom = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinese Poker'),
        actions: [
          IconButton(
            onPressed: _showGameBreakdown,
            icon: const Icon(Icons.list_alt),
            tooltip: 'Game breakdown',
          ),
          IconButton(onPressed: _resetGame, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;
            final pagePadding = isCompact
                ? const EdgeInsets.fromLTRB(8, 8, 8, 12)
                : const EdgeInsets.all(16);
            final gameColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TurnPanel(
                  isCompact: isCompact,
                  statusText: _game.statusText,
                  card: _game.currentCard,
                  isFinalExchangePhase: _game.isFinalExchangePhase,
                  canAct: !_botIsThinking &&
                      !_game.isGameFinished &&
                      _game.isHumanTurn,
                  onSetPressed: _onSetPressed,
                ),
                SizedBox(height: isCompact ? 12 : 20),
                _FeltTable(
                  isCompact: isCompact,
                  opponent: _PlayerBoard(
                    title: 'Opponent',
                    columns: _game.state.p2,
                    isHumanBoard: false,
                    revealFinalCards: _game.isGameFinished,
                    winningColumnIndexes: _game.isGameFinished
                        ? _winningColumns(isOpponent: true)
                        : const <int>{},
                    selectedColumnIndex: null,
                    availableColumnIndexes: const <int>{},
                    isCompact: isCompact,
                  ),
                  player: _PlayerBoard(
                    title: 'You',
                    columns: _game.state.p1,
                    isHumanBoard: true,
                    revealFinalCards: _game.isGameFinished,
                    winningColumnIndexes: _game.isGameFinished
                        ? _winningColumns(isOpponent: false)
                        : const <int>{},
                    selectedColumnIndex: _game.selectedExchangeColumn,
                    availableColumnIndexes: availableColumns,
                    isCompact: isCompact,
                  ),
                  remainingCards: _game.finalDiscards,
                  revealHiddenCards: _game.isGameFinished,
                ),
                if (_game.isGameFinished) ...[
                  const SizedBox(height: 12),
                  _FinalComparisonPanel(rows: summaryRows),
                ],
              ],
            );

            if (enablePinchZoom) {
              return InteractiveViewer(
                constrained: false,
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.85,
                maxScale: 2.8,
                boundaryMargin: const EdgeInsets.all(240),
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Padding(
                    padding: pagePadding,
                    child: gameColumn,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: pagePadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: gameColumn,
              ),
            );
          },
        ),
      ),
    );
  }

  Set<int> _winningColumns({required bool isOpponent}) {
    final winners = <int>{};
    for (int index = 0; index < 5; index++) {
      final result = GameRules.compareColumns(
        _game.state.p1[index],
        _game.state.p2[index],
      );
      if ((isOpponent && result < 0) || (!isOpponent && result > 0)) {
        winners.add(index);
      }
    }
    return winners;
  }
}

class _TurnPanel extends StatelessWidget {
  const _TurnPanel({
    required this.isCompact,
    required this.statusText,
    required this.card,
    required this.isFinalExchangePhase,
    required this.canAct,
    this.onSetPressed,
  });

  final bool isCompact;
  final String statusText;
  final Card? card;
  final bool isFinalExchangePhase;
  final bool canAct;
  final VoidCallback? onSetPressed;

  @override
  Widget build(BuildContext context) {
    final showSetButton = isFinalExchangePhase && card != null && canAct;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: showSetButton
            ? Colors.deepOrange.withValues(alpha: 0.08)
            : Colors.deepPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: showSetButton
            ? Border.all(color: Colors.deepOrange.shade300, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _buildMessage(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 15 : 18,
              ),
            ),
          ),
          if (showSetButton) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onSetPressed,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('SET'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                elevation: 6,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 14 : 18,
                  vertical: isCompact ? 10 : 14,
                ),
                textStyle: TextStyle(
                  fontSize: isCompact ? 15 : 18,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Combines the draw/status message with the current card on one line.
  String _buildMessage() {
    final currentCard = card;
    if (currentCard == null) {
      return statusText;
    }

    final label = LocalChinesePokerGame.describeCard(currentCard);
    if (isFinalExchangePhase) {
      return 'Current card: $label — optional, swap one fifth card, then press Set.';
    }
    if (canAct) {
      return 'Current card: $label — choose a column below.';
    }
    return statusText;
  }
}

class _FeltTable extends StatelessWidget {
  const _FeltTable({
    required this.isCompact,
    required this.opponent,
    required this.player,
    required this.remainingCards,
    required this.revealHiddenCards,
  });

  final bool isCompact;
  final Widget opponent;
  final Widget player;
  final List<FinalDiscard> remainingCards;
  final bool revealHiddenCards;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isCompact
          ? const EdgeInsets.fromLTRB(4, 10, 4, 12)
          : const EdgeInsets.fromLTRB(8, 14, 8, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade900, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade700, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: remainingCards.isEmpty ? 520 : 680,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final board = Column(
                children: [
                  opponent,
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 12,
                      vertical: 2,
                    ),
                    child: Divider(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  player,
                ],
              );

              if (remainingCards.isEmpty || constraints.maxWidth < 600) {
                return Column(
                  children: [
                    board,
                    if (remainingCards.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      _RemainingCardsPanel(
                        discards: remainingCards,
                        isCompact: isCompact,
                        revealHiddenCards: revealHiddenCards,
                      ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: board),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 128,
                    child: _RemainingCardsPanel(
                      discards: remainingCards,
                      isCompact: isCompact,
                      revealHiddenCards: revealHiddenCards,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlayerBoard extends StatelessWidget {
  const _PlayerBoard({
    required this.title,
    required this.columns,
    required this.isHumanBoard,
    required this.revealFinalCards,
    required this.availableColumnIndexes,
    required this.winningColumnIndexes,
    required this.isCompact,
    this.selectedColumnIndex,
  });

  final String title;
  final List<dynamic> columns;
  final bool isHumanBoard;
  final bool revealFinalCards;
  final Set<int> availableColumnIndexes;
  final Set<int> winningColumnIndexes;
  final bool isCompact;
  final int? selectedColumnIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 1 : 2),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(5, (index) {
              final column = columns[index];
              final myCards = List<Card>.from(column.cards);
              final cardColors = revealFinalCards
                  ? _buildCombinationColors(myCards)
                  : List<Color?>.filled(column.cards.length, null);
              final isSelected = selectedColumnIndex == index && isHumanBoard;
              final isAvailable =
                  isHumanBoard && availableColumnIndexes.contains(index);
              final isWinningColumn = winningColumnIndexes.contains(index);
              final isLastCardHidden = GameRules.isTopCardHiddenForHuman(
                isHumanBoard: isHumanBoard,
                columnLength: column.cards.length,
                revealFinalCards: revealFinalCards,
              );
              final highlightTopCard = GameRules.shouldHighlightTopCard(
                    isHumanBoard: isHumanBoard,
                    columnLength: column.cards.length,
                  ) &&
                  !revealFinalCards;

              return Expanded(
                child: _ColumnTapTarget(
                  enabled: isHumanBoard,
                  onTap: () => _handleTap(context, index),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 1 : (isCompact ? 2 : 3),
                      right: index == 4 ? 1 : (isCompact ? 2 : 3),
                    ),
                    padding: isCompact
                        ? const EdgeInsets.fromLTRB(2, 5, 2, 6)
                        : const EdgeInsets.fromLTRB(3, 6, 3, 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.shade200
                          : isWinningColumn
                              ? Colors.green.shade300
                              : Colors.white.withValues(alpha: 0.92),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orange.shade700
                            : isWinningColumn
                                ? Colors.green.shade700
                                : Colors.black.withValues(alpha: 0.18),
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isAvailable) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green.shade900,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        _OverlappingCardStack(
                          cards: List<Card>.from(column.cards),
                          cardColors: cardColors,
                          hideTopCard:
                              isLastCardHidden && column.cards.length == 5,
                          highlightTopCard: highlightTopCard,
                          isCompact: isCompact,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<Color?> _buildCombinationColors(List<Card> cards) {
    final colors = List<Color?>.filled(cards.length, null);
    if (cards.length < 2) {
      return colors;
    }

    final hand = PokerEvaluator.evaluate(cards);
    final rankToIndexes = <int, List<int>>{};
    for (int i = 0; i < cards.length; i++) {
      rankToIndexes.putIfAbsent(cards[i].rank, () => []).add(i);
    }

    final grouped = rankToIndexes.entries.toList()
      ..sort((a, b) {
        if (a.value.length != b.value.length) {
          return b.value.length.compareTo(a.value.length);
        }
        return b.key.compareTo(a.key);
      });

    if (hand.rank == 5 || hand.rank == 8) {
      return List<Color?>.filled(cards.length, Colors.blue.shade100);
    }

    if (hand.rank == 4) {
      return List<Color?>.filled(cards.length, Colors.indigo.shade100);
    }

    if (hand.rank == 6) {
      _applyGroupColor(colors, grouped, 3, Colors.orange.shade200);
      _applyGroupColor(colors, grouped, 2, Colors.teal.shade200);
      return colors;
    }

    if (hand.rank == 2) {
      int pairIndex = 0;
      for (final entry in grouped) {
        if (entry.value.length == 2) {
          final color =
              pairIndex == 0 ? Colors.pink.shade200 : Colors.lightBlue.shade200;
          for (final cardIndex in entry.value) {
            colors[cardIndex] = color;
          }
          pairIndex++;
        }
      }
      return colors;
    }

    if (hand.rank == 7) {
      _applyGroupColor(colors, grouped, 4, Colors.deepOrange.shade200);
      return colors;
    }

    if (hand.rank == 3) {
      _applyGroupColor(colors, grouped, 3, Colors.orange.shade200);
      return colors;
    }

    if (hand.rank == 1) {
      _applyGroupColor(colors, grouped, 2, Colors.purple.shade100);
      return colors;
    }

    return colors;
  }

  void _applyGroupColor(
    List<Color?> colors,
    List<MapEntry<int, List<int>>> grouped,
    int groupSize,
    Color color,
  ) {
    for (final entry in grouped) {
      if (entry.value.length == groupSize) {
        for (final index in entry.value) {
          colors[index] = color;
        }
        return;
      }
    }
  }

  void _handleTap(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_GameScreenState>();
    state?._onHumanColumnTap(index);
  }
}

class _ColumnTapTarget extends StatefulWidget {
  const _ColumnTapTarget({
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ColumnTapTarget> createState() => _ColumnTapTargetState();
}

class _ColumnTapTargetState extends State<_ColumnTapTarget> {
  int _activePointers = 0;
  bool _wasMultiTouch = false;
  bool _movedTooFar = false;
  Offset? _tapStart;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _activePointers++;
        if (_activePointers > 1) {
          _wasMultiTouch = true;
        } else {
          _tapStart = event.localPosition;
          _movedTooFar = false;
        }
      },
      onPointerMove: (event) {
        final tapStart = _tapStart;
        if (tapStart != null &&
            (event.localPosition - tapStart).distance > 10) {
          _movedTooFar = true;
        }
      },
      onPointerCancel: (_) {
        _resetGestureState();
      },
      onPointerUp: (_) {
        final shouldTap = widget.enabled &&
            _activePointers == 1 &&
            !_wasMultiTouch &&
            !_movedTooFar;

        _activePointers = math.max(0, _activePointers - 1);
        if (_activePointers == 0) {
          _wasMultiTouch = false;
          _movedTooFar = false;
          _tapStart = null;
        }

        if (shouldTap) {
          widget.onTap();
        }
      },
      child: widget.child,
    );
  }

  void _resetGestureState() {
    _activePointers = 0;
    _wasMultiTouch = false;
    _movedTooFar = false;
    _tapStart = null;
  }
}

class _OverlappingCardStack extends StatelessWidget {
  const _OverlappingCardStack({
    required this.cards,
    required this.cardColors,
    required this.hideTopCard,
    required this.highlightTopCard,
    required this.isCompact,
  });

  final List<Card> cards;
  final List<Color?> cardColors;
  final bool hideTopCard;
  final bool highlightTopCard;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth / (64.0 / 89.0);
        final overlap = isCompact
            ? math.min(cardHeight * 0.38, 28.0)
            : math.min(cardHeight * 0.42, 34.0);
        final stackHeight = cardHeight + overlap * 4;

        return SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int cardIndex = 0; cardIndex < cards.length; cardIndex++)
                Positioned(
                  top: cardIndex * overlap,
                  left: 0,
                  right: 0,
                  child: cardIndex == cards.length - 1 && hideTopCard
                      ? const AppHiddenPlayingCard()
                      : AppPlayingCard(
                          card: cards[cardIndex],
                          highlighted:
                              cardIndex == cards.length - 1 && highlightTopCard,
                          comboColor: cardColors[cardIndex],
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FinalComparisonPanel extends StatelessWidget {
  const _FinalComparisonPanel({required this.rows});

  final List<_SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: row.isHumanWin
                    ? Colors.green.shade100
                    : row.isBotWin
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: row.isHumanWin
                      ? Colors.green.shade500
                      : row.isBotWin
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                ),
              ),
              child: Text(
                row.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingCardsPanel extends StatelessWidget {
  const _RemainingCardsPanel({
    required this.discards,
    required this.isCompact,
    required this.revealHiddenCards,
  });

  final List<FinalDiscard> discards;
  final bool isCompact;
  final bool revealHiddenCards;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Remaining cards',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: discards.map((discard) {
              final concealed = !discard.isHuman && !revealHiddenCards;
              return SizedBox(
                width: isCompact ? 78 : 92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      discard.isHuman ? 'You' : 'Bot',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    concealed
                        ? const AppHiddenPlayingCard()
                        : AppPlayingCard(card: discard.card),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  const _SummaryRow({
    required this.text,
    required this.isHumanWin,
    required this.isBotWin,
  });

  final String text;
  final bool isHumanWin;
  final bool isBotWin;
}
