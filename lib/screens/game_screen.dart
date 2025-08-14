import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tic_tac_toe/provider/room_data_provider.dart';
import 'package:tic_tac_toe/screens/main_menu_screen.dart';
import 'package:tic_tac_toe/views/scoreboard.dart';
import '../resources/socket_methods.dart';
import '../views/tictactoe_board.dart';
import '../views/waiting_lobby.dart';

class GameScreen extends StatefulWidget {
  static String routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SocketMethods _socketMethods = SocketMethods();
  bool _listenersInitialized = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _initializeListeners();
  }

  void _initializeListeners() {
    if (!_listenersInitialized) {
      _socketMethods.updateRoomListener(context);
      _socketMethods.updatePlayersStateListener(context);
      _socketMethods.pointIncreaseListener(context);
      _socketMethods.endGameListener(context);
      _socketMethods.tappedListener(context);
      _socketMethods.opponentLeftListener(context);
      _socketMethods.drawRoundListener(context);
      _listenersInitialized = true;
    }
  }

  @override
  void dispose() {
    // Clear all listeners when disposing
    _socketMethods.clearListeners();
    super.dispose();
  }

  Future<bool> _onPopScope() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Game?'),
            content: const Text(
              'Do you want to quit the match or resume playing?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Stay in game
                },
                child: const Text(
                  'Resume',
                  style: TextStyle(fontSize: 20, color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () {
                  final roomDataProvider = Provider.of<RoomDataProvider>(
                    context,
                    listen: false,
                  );

                  // Get MY actual socket ID from the socket client
                  String? mySocketId = _socketMethods.socketClient.id;

                  // Emit player left event
                  if (mySocketId != null) {
                    _socketMethods.socketClient.emit('playerLeft', {
                      'roomId': roomDataProvider.roomData['_id'],
                      'playerId': mySocketId, // Use actual socket ID
                    });
                  }

                  // Clear listeners and navigate immediately
                  _socketMethods.clearListeners();
                  Navigator.of(context).pop(true);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    MainMenuScreen.routeName,
                    (route) => false,
                  );
                },
                child: const Text(
                  'Quit',
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    RoomDataProvider roomDataProvider = Provider.of<RoomDataProvider>(context);
    return PopScope(
      canPop: false, // Block auto pop out
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onPopScope();
        }
      },
      child: Scaffold(
        body: roomDataProvider.roomData['isJoin']
            ? const WaitingLobby()
            : SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Scoreboard(),
                    const TicTacToeBoard(),
                    Text(
                      '${roomDataProvider.roomData['turn']['nickname']}\'s Turn',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
