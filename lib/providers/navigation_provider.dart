import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _collectionChanged = false;

  int get currentIndex => _currentIndex;
  bool get collectionChanged => _collectionChanged;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void notifyCollectionChanged() {
    _collectionChanged = !_collectionChanged;
    notifyListeners();
  }
} 