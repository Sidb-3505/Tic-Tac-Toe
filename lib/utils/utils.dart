import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../resources/game_methods.dart';
import '../resources/socket_methods.dart';
import '../screens/main_menu_screen.dart';

void showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(content)));
}

void showGameDialog(BuildContext context, String text) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              GameMethods().clearBoard(context);
            },
            child: const Text('Next Round'),
          ),
        ],
      );
    },
  );
}

void showCelebrationAnimation(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Stack(
      alignment: Alignment.center,
      children: [
        ConfettiWidget(
          confettiController: ConfettiController(
            duration: const Duration(seconds: 1),
          )..play(),
          blastDirectionality: BlastDirectionality.explosive,
        ),
        Lottie.asset('assets/celebration.json'),
      ],
    ),
  );
}

void winGameDialog(BuildContext context, String text) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              // Add a small delay before navigating
              Future.delayed(Duration(milliseconds: 100), () {
                SocketMethods().disconnectSocket();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  MainMenuScreen.routeName, // the screen you want at the top
                  (route) => false, // remove all existing routes
                );
              });
            },
            child: const Text('Quit', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              // Add rematch logic here later
            },
            child: const Text('Rematch', style: TextStyle(color: Colors.blue)),
          ),
        ],
      );
    },
  );
}
