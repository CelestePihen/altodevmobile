/// Size of the buttons on the screen
enum ButtonSize { S, M, L }

extension ButtonSizeExtension on ButtonSize {
  double get height {
    switch (this) {
      case ButtonSize.S:
        return 32.0;
      case ButtonSize.M:
        return 48.0;
      case ButtonSize.L:
        return 64.0;
    }
  }

  double get fontSize => height * 0.35;

  double get iconSize => height * 0.4;

  double get minWidth => height * 3;
}
