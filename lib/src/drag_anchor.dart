import 'package:flutter/material.dart';

@immutable
class DragAnchorPos {
  static const defaultAnchorPos = DragAnchorPos.align(DragAnchorAlign.center);

  final DragAnchor? anchor;
  final DragAnchorAlign? alignment;

  const DragAnchorPos.exactly(DragAnchor this.anchor) : alignment = null;

  const DragAnchorPos.align(this.alignment) : anchor = null;
}

@immutable
class DragAnchor {
  final double left;
  final double top;

  const DragAnchor(this.left, this.top);

  factory DragAnchor.fromPos(DragAnchorPos pos, double width, double height) {
    late double left;
    late double top;

    switch (pos.alignment?._x) {
      case -1:
        left = 0;
        break;
      case 1:
        left = width;
        break;
      default:
        left = width / 2;
    }

    switch (pos.alignment?._y) {
      case 1:
        top = 0;
        break;
      case -1:
        top = height;
        break;
      default:
        top = height / 2;
    }

    return DragAnchor(left, top);
  }
}

enum DragAnchorAlign {
  topLeft(-1, 1),
  topRight(1, 1),
  bottomLeft(-1, -1),
  bottomRight(1, -1),
  center(0, 0),

  /// Top center
  top(0, 1),

  /// Bottom center
  bottom(0, -1),

  /// Left center
  left(-1, 0),

  /// Right center
  right(1, 0);

  final int _x;
  final int _y;

  const DragAnchorAlign(this._x, this._y);
}
