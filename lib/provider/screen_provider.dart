import 'package:flutter/material.dart';

class ScreenProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void selectScreen(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
