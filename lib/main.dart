import 'package:flutter/material.dart';

import 'game_screen.dart';

void main() {
  runApp(const ChinesePokerApp());
}

class ChinesePokerApp extends StatelessWidget {
  const ChinesePokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chinese Poker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
