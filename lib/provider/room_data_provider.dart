import 'package:flutter/material.dart';

import '../models/player.dart';

class RoomDataProvider extends ChangeNotifier {
  /// to notify listeners
  Map<String, dynamic> _roomData = {};

  /// to keep track of elements marked in grid
  List<String> _displayElement = ['', '', '', '', '', '', '', '', ''];
  int _filledBoxes = 0;
  Player _player1 = Player(
    nickname: '',
    socketID: '',
    points: 0,
    playerType: 'X',
  );

  Player _player2 = Player(
    nickname: '',
    socketID: '',
    points: 0,
    playerType: 'O',
  );

  Map<String, dynamic> get roomData => _roomData;
  List<String> get displayElements => _displayElement;
  int get filledBoxes => _filledBoxes;
  Player get player1 => _player1;
  Player get player2 => _player2;

  void updateRoomData(Map<String, dynamic> data) {
    _roomData = data;
    notifyListeners();
  }

  void updatePlayer1(Map<String, dynamic> player1Data) {
    /// take data -> convert to map -> store in _player1
    _player1 = Player.fromMap(player1Data);
    notifyListeners();
  }

  void updatePlayer2(Map<String, dynamic> player2Data) {
    _player2 = Player.fromMap(player2Data);
    notifyListeners();
  }

  void updateDisplayElements(int index, String choice) {
    if (_displayElement[index] == '') {
      // Change this line
      _displayElement[index] = choice; // Change this line
      _filledBoxes += 1; // Change this line
    } else {
      _displayElement[index] = choice; // Change this line
    }
    notifyListeners();
  }

  void setFilledBoxesTo0() {
    _filledBoxes = 0; // Change this line
    notifyListeners();
  }
}
