import 'package:flutter/foundation.dart';

class TabNavigationService {
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static void setTabIndex(int index) {
    tabIndex.value = index;
  }
}
