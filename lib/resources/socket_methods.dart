import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/src/socket.dart';
import 'package:tic_tac_toe/provider/room_data_provider.dart';
import 'package:tic_tac_toe/resources/game_methods.dart';
import 'package:tic_tac_toe/resources/socket_client.dart';
import 'package:tic_tac_toe/screens/game_screen.dart';
import 'package:tic_tac_toe/utils/utils.dart';

class SocketMethods {
  final _socketClient = SocketClient.instance!.socket!;
  static bool _dialogShown = false; // Add this flag

  Socket get socketClient => _socketClient;

  /// EMITS
  void createRoom(String nickname) {
    if (nickname.trim().isNotEmpty) {
      _socketClient.emit('createRoom', {'nickname': nickname});
    }
  }

  void joinRoom(String nickname, String roomId) {
    if (nickname.trim().isNotEmpty && roomId.trim().isNotEmpty) {
      _socketClient.emit('joinRoom', {'nickname': nickname, 'roomId': roomId});
    }
  }

  /// to update the cells with 'X' / 'O'
  void tapGrid(int index, String roomId, List<String> displayElements) {
    if (displayElements[index] == '') {
      _socketClient.emit('tap', {'index': index, 'roomId': roomId});
    }
  }

  /// LISTERNERS
  /// create room success listener
  void createRoomSuccessListener(BuildContext context) {
    _socketClient.off('createRoomSuccess'); // Clear existing listener
    _socketClient.on('createRoomSuccess', (room) {
      Provider.of<RoomDataProvider>(
        context,
        listen: false,
      ).updateRoomData(room);
      Navigator.pushNamed(context, GameScreen.routeName);
    });
  }

  /// join room success listener
  void joinRoomSuccessListener(BuildContext context) {
    _socketClient.off('joinRoomSuccess'); // Clear existing listener
    _socketClient.on('joinRoomSuccess', (room) {
      Provider.of<RoomDataProvider>(
        context,
        listen: false,
      ).updateRoomData(room);
      Navigator.pushNamed(context, GameScreen.routeName);
    });
  }

  /// error occured success listener
  void errorOccuredListener(BuildContext context) {
    _socketClient.off('errorOccured'); // Clear existing listener
    _socketClient.on('errorOccured', (data) {
      showSnackBar(context, data);
    });
  }

  void clearListeners() {
    _socketClient.off("createRoomSuccess");
    _socketClient.off("joinRoomSuccess");
    _socketClient.off("errorOccured");
    _socketClient.off("updatePlayers");
    _socketClient.off("updateRoom");
    _socketClient.off("tapped");
    _socketClient.off("pointIncrease");
    _socketClient.off("endGame");
    _socketClient.off("drawRound");
    _socketClient.off("gameOver");
  }

  /// FUNCTIONS
  void updatePlayersStateListener(BuildContext context) {
    _socketClient.off('updatePlayers'); // Clear existing listener
    _socketClient.on('updatePlayers', (playerData) {
      Provider.of<RoomDataProvider>(
        context,
        listen: false,
      ).updatePlayer1(playerData[0]);

      Provider.of<RoomDataProvider>(
        context,
        listen: false,
      ).updatePlayer2(playerData[1]);
    });
  }

  /// to update the room after both players have joined
  void updateRoomListener(BuildContext context) {
    _socketClient.off('updateRoom'); // Clear existing listener
    _socketClient.on('updateRoom', (data) {
      Provider.of<RoomDataProvider>(
        context,
        listen: false,
      ).updateRoomData(data);
    });
  }

  void tappedListener(BuildContext context) {
    _socketClient.off('tapped'); // Clear existing listener
    _socketClient.on('tapped', (data) {
      RoomDataProvider roomDataProvider = Provider.of<RoomDataProvider>(
        context,
        listen: false,
      );
      roomDataProvider.updateDisplayElements(data['index'], data['choice']);
      roomDataProvider.updateRoomData(data['room']);

      String? mySocketId = _socketClient.id;

      /// getting current user's socket id
      String currentTurnSocketId = data['room']['turn']['socketID'];

      if (mySocketId == currentTurnSocketId) {
        Future.delayed(Duration(milliseconds: 100), () {
          GameMethods().checkWinner(context, _socketClient);
        });
      }
    });
  }

  void pointIncreaseListener(BuildContext context) {
    _socketClient.off('pointIncrease'); // Clear existing listener
    _socketClient.on('pointIncrease', (playerData) {
      if (_dialogShown) return; // Prevent multiple dialogs
      _dialogShown = true;

      var roomDataProvider = Provider.of<RoomDataProvider>(
        context,
        listen: false,
      );

      /// if winner is player 1
      if (playerData['socketID'] == roomDataProvider.player1.socketID) {
        roomDataProvider.updatePlayer1(playerData);
        showGameDialog(context, '${playerData['nickname']} won the round!');
      } else {
        roomDataProvider.updatePlayer2(playerData);
        showGameDialog(context, '${playerData['nickname']} won the round!');
      }

      // Reset flag after a delay
      Future.delayed(Duration(seconds: 1), () {
        _dialogShown = false;
      });
    });
  }

  void endGameListener(BuildContext context) {
    _socketClient.off('endGame'); // Clear existing listener
    _socketClient.on('endGame', (playerData) {
      if (_dialogShown) return; // Prevent multiple dialogs
      _dialogShown = true;

      //winGameDialog(context, '${playerData['nickname']} won the game!');

      // Handle null case for ties
      String message;
      if (playerData == null || playerData['nickname'] == null) {
        message = "It's a Tie!";
      } else {
        message = '${playerData['nickname']} won the game!';
      }
      showCelebrationAnimation(context);
      winGameDialog(context, message);
      // Reset flag after a delay
      Future.delayed(Duration(seconds: 2), () {
        _dialogShown = false;
      });
    });
  }

  void drawRoundListener(BuildContext context) {
    _socketClient.off('drawRound'); // Clear existing listener
    _socketClient.on('drawRound', (_) {
      if (_dialogShown) return; // Prevent multiple dialogs
      _dialogShown = true;

      showGameDialog(context, 'Draw');

      // Reset flag after a delay
      Future.delayed(Duration(seconds: 1), () {
        _dialogShown = false;
      });
    });
  }

  void opponentLeftListener(BuildContext context) {
    _socketClient.off('gameOver'); // Clear existing listener
    _socketClient.on('gameOver', (data) {
      if (_dialogShown) return; // Prevent multiple dialogs
      _dialogShown = true;

      if (data['reason'] == 'opponent_left') {
        winGameDialog(context, '${data['winner']} wins! (Opponent left)');
      }

      // Reset flag after a delay
      Future.delayed(Duration(seconds: 1), () {
        _dialogShown = false;
      });
    });
  }

  void disconnectSocket() {
    clearListeners(); // Clear all listeners before disconnecting
    _socketClient.disconnect();
    _socketClient.close();
    _socketClient.dispose();
  }
}
