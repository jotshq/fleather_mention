import 'dart:math';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

// Same as renderEditor.getLocalRectForCaret but it returns global rect
// that does take the editor padding into account
Rect _getGlobalRectForCaret(RenderEditor renderEditor, TextPosition position) {
  final targetChild = renderEditor.childAtPosition(position);
  final localPosition = targetChild.globalToLocalPosition(position);

  final childLocalRect = targetChild.getLocalRectForCaret(localPosition);
  return Rect.fromPoints(targetChild.localToGlobal(childLocalRect.topLeft),
      targetChild.localToGlobal(childLocalRect.bottomRight));
}

Widget positionedFromTextPos(
    BuildContext context,
    RenderEditor renderEditor,
    TextPosition position,
    double childHeight,
    double childWidth,
    Widget child) {
  final gLineRect = _getGlobalRectForCaret(renderEditor, position);

  final mediaQueryData = MediaQuery.of(context);
  final screenHeight = mediaQueryData.size.height;
  final screenWidth = mediaQueryData.size.width;

  double? positionFromTop = gLineRect.bottom;
  double? positionFromBottom;

  if (positionFromTop + childHeight >
      screenHeight - mediaQueryData.viewInsets.bottom) {
    positionFromTop = null;
    positionFromBottom = screenHeight - gLineRect.top;
  }

  double? positionFromLeft = gLineRect.left;
  double? positionFromRight;
  positionFromLeft = min(positionFromLeft, screenWidth - 32 - childWidth);
  if (positionFromLeft < 16) positionFromLeft = 16;

  positionFromRight = (screenWidth - 16) - positionFromLeft - childWidth;
  if (positionFromRight < 16) {
    positionFromRight = 16;
  }

  try {
    final pp = renderEditor.parent as RenderBox;
    final p = pp.parent as RenderBox;
    final editingAreaTop = p.localToGlobal(Offset.zero);
    // hide the overlay when the line is not displayed
    if (positionFromTop != null) {
      if (positionFromTop < editingAreaTop.dy) {
        return const SizedBox();
      }
    }
    if (positionFromBottom != null) {
      if (positionFromBottom < 0) return const SizedBox();
      if (positionFromBottom > screenHeight - editingAreaTop.dy) {
        return const SizedBox();
      }
    }
  } catch (err) {
    print("This should not happened: cannot find correct parent renderbox");
  }

  return Positioned(
    top: positionFromTop,
    bottom: positionFromBottom,
    left: positionFromLeft,
    right: positionFromRight,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: childWidth, maxHeight: childHeight),
      child: ClipRRect(child: child),
    ),
  );
}
