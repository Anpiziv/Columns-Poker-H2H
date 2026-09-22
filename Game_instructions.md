# Chinese Poker: Player Instructions

This repository contains a local, single-player Chinese Poker game: you play
against a bot. The game uses one standard 52-card deck and no network connection or account.

## Objective

Build five columns of five cards. Each of your columns is compared with the
bot's column in the same position. You receive one point for every column you
win. The player with more points after all five comparisons wins the game.

A tied column gives neither player a point. The maximum score is therefore
five points.

## Cards and columns

- The deck contains the four suits and ranks 2 through A.
- Aces are high for high-card comparisons, but can be low in an A-2-3-4-5
  straight.
- You and the bot each have five columns.
- Cards are placed face up while columns are being built.
- Your completed fifth cards remain visible to you so you can remember your own
  hand. The bot cannot see your fifth cards, and you cannot see the bot's fifth
  cards, until the game ends.

## Starting deal

The app deals five cards simultaneously for each player, one card for each column. The first card in each pair goes to the player who deals first, and the second goes to the other
player. Each player starts with one face-up card in every column.

The app randomly chooses who goes first for the game. The first player is also
the first player to act in the final exchange phase.

## Building the columns

There are four building rounds after the opening deal. In each round, each
player receives exactly one card for each column, one card at a time:

1. Draw the card shown in the turn panel.
2. Place it in a column that has not received a card during the current round.
3. Wait for the other player to take its turn.

The required column size at the start of each round is:

- Round 2: choose a column with 1 card.
- Round 3: choose a column with 2 cards.
- Round 4: choose a column with 3 cards.
- Round 5: choose a column with 4 cards.

After a card is placed in a column, that column cannot be selected again by
the same player during that round. When all five columns have been used by
both players, the next round begins.

The fifth card completes a five-card poker hand. Each player sees their own
fifth cards but not the opponent's fifth cards. The bot must make decisions
using only the cards it can know: its own cards, your first four cards in each
column, exposed cards, and probability.

## Final exchange

After both players have five full columns, exactly two cards remain in the
deck. The players receive one final card each, in turn order.

For your final card, you may:

- **Keep your columns:** press **Set** without selecting a column. The drawn
  card is discarded.
- **Exchange one card:** tap one of your columns, then press **Set**. The
  drawn card replaces that column's fifth (top) card. The replaced card is
  discarded and cannot be used again.

Only a fifth card can be exchanged. Tap the selected column again to cancel
the selection before pressing **Set**.

The other player follows the same one-card exchange structure. Its exchanged fifth card
stays hidden until the final reveal.

## Poker hand ranking

Each five-card column uses these standard poker categories, from strongest to
weakest:

1. Straight flush: five cards in sequence, all of one suit.
2. Four of a kind: four cards of the same rank.
3. Full house: three cards of one rank and two of another.
4. Flush: five cards of one suit, not in sequence.
5. Straight: five cards in sequence, regardless of suit.
6. Three of a kind: three cards of the same rank.
7. Two pair: two cards of one rank and two of another.
8. One pair: two cards of the same rank.
9. High card: none of the combinations above.

Within the same category, the game compares the relevant ranks and then the
remaining cards (kickers) from highest to lowest. For example, a higher pair
beats a lower pair, and equal pairs are decided by the highest remaining card.
An A-2-3-4-5 straight is treated as a five-high straight. If every evaluated
comparison value is equal, the column is a tie.

## Reading the game screen

- **Turn panel:** shows whose turn it is, the card you must place or exchange,
  and the current action.
- **Your board:** tap an available column to place a drawn card. During the
  final exchange, tap a column to select or deselect it.
- **Opponent board:** shows the bot's visible cards and card backs for hidden
  fifth cards.
- **Game breakdown:** opens the move log. Hidden bot cards remain concealed
  there until the game is over.
- **Set:** confirms the final-exchange decision.
- **Refresh:** starts a new game.

## End of game

When the final exchange is complete, the app reveals the hidden cards and
compares columns 1 through 5. The final score is shown as `you-bot`, and the
comparison panel identifies each column winner or tie.

## Strategy reminders

- Keep track of exposed cards; there is only one copy of each suit and rank.
- Place cards with future hand possibilities in mind, not only the current
  highest card.
- A column that already received a card this round is unavailable until the
  next round.
- The final exchange can improve a completed hand, but keeping the existing
  fifth card may be better when the drawn card does not help.
