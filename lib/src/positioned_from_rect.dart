import 'dart:math';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// nice info: https://github.com/rvamsikrishna/inview_notifier_list/blob/master/lib/src/inview_state.dart

// Same as renderEditor.getLocalRectForCaret but it returns global rect
// that does take the editor padding into account
Rect? getGlobalRectForCaret(RenderEditor renderEditor, TextPosition position) {
  final targetChild = renderEditor.childAtPosition(position);
  final localPosition = targetChild.globalToLocalPosition(position);

  if (targetChild.debugNeedsLayout || !targetChild.attached) {
    print("null rect");
    return null;
  }
  final childLocalRect = targetChild.getLocalRectForCaret(localPosition);
  return Rect.fromPoints(targetChild.localToGlobal(childLocalRect.topLeft),
      targetChild.localToGlobal(childLocalRect.bottomRight));
}

Widget positionedFromTextPos3(BuildContext context, RenderEditor renderEditor,
    TextPosition position, LayerLink link, Widget child) {
  final targetChild = renderEditor.childAtPosition(position);

  final offset = targetChild.getOffsetForCaret(position);
  // final offset = Offset();
  return Positioned(
    top: 0,
    left: 0,
    child: CompositedTransformFollower(
      link: link,
      child: child,
      offset: offset,
    ),
  );
}

Widget positionedFromTextPos(
    BuildContext context,
    RenderEditor renderEditor,
    TextPosition position,
    double childHeight,
    double childWidth,
    Widget child) {
  // print("posFrom");
  final lineRect = getGlobalRectForCaret(renderEditor, position);
  if (lineRect == null) return const SizedBox();

  final RenderAbstractViewport? viewport =
      RenderAbstractViewport.of(renderEditor);

  if (viewport == null) return const SizedBox();

  final vp = viewport as RenderViewport;

  final editingArea = Rect.fromPoints(vp.localToGlobal(Offset.zero),
      vp.localToGlobal(Offset(vp.size.width, vp.size.height)));
  return positionedFromTextPos2(
      context, lineRect, editingArea, childHeight, childWidth, child);
}

Widget positionedFromTextPos2(BuildContext context, Rect lineRect,
    Rect editingArea, double childHeight, double childWidth, Widget child) {
  // print("posFrom");

  final mediaQueryData = MediaQuery.of(context);
  final screenHeight = mediaQueryData.size.height;
  final screenWidth = mediaQueryData.size.width;

  double? positionFromTop = lineRect.bottom;
  double? positionFromBottom;

  if (positionFromTop + childHeight >
      screenHeight - mediaQueryData.viewInsets.bottom) {
    positionFromTop = null;
    positionFromBottom = screenHeight - lineRect.top;
  }

  double? positionFromLeft = lineRect.left;
  double? positionFromRight;
  positionFromLeft = min(positionFromLeft, screenWidth - 32 - childWidth);
  if (positionFromLeft < 16) positionFromLeft = 16;

  positionFromRight = (screenWidth - 16) - positionFromLeft - childWidth;
  if (positionFromRight < 16) {
    positionFromRight = 16;
  }

  if (positionFromTop != null) {
    if (positionFromTop < editingArea.top) {
      return const SizedBox();
    }
    if (positionFromTop > editingArea.bottom) {
      return const SizedBox();
    }
  }
  if (positionFromBottom != null) {
    if (positionFromBottom <
        screenHeight - editingArea.bottom /*+ gLineRect.height*/) {
      return const SizedBox();
    }
    if (positionFromBottom > screenHeight - editingArea.top) {
      return const SizedBox();
    }
  }

  return Positioned(
    top: positionFromTop,
    bottom: positionFromBottom,
    left: positionFromLeft,
    right: positionFromRight,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: childWidth, maxHeight: childHeight),
      child: child,
    ),
  );
}
