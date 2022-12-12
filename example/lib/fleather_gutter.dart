import 'package:fleather/fleather.dart';
import 'package:fleather_mention/fleather_mention.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

// typedef _DragItemUpdate = void Function(_DragInfo item, Offset position, Offset delta);
// typedef _DragItemCallback = void Function(_DragInfo item);

// class _DragInfo extends Drag {
//   _DragInfo({
//     // required _ReorderableItemState item,
//     Offset initialPosition = Offset.zero,
//     this.scrollDirection = Axis.vertical,
//     this.onUpdate,
//     this.onEnd,
//     this.onCancel,
//     this.onDropCompleted,
//     this.proxyDecorator,
//     required this.tickerProvider,
//   }) {
//     final RenderBox itemRenderBox = item.context.findRenderObject()! as RenderBox;
//     listState = item._listState;
//     index = item.index;
//     child = item.widget.child;
//     capturedThemes = item.widget.capturedThemes;
//     dragPosition = initialPosition;
//     dragOffset = itemRenderBox.globalToLocal(initialPosition);
//     itemSize = item.context.size!;
//     itemExtent = _sizeExtent(itemSize, scrollDirection);
//     scrollable = Scrollable.of(item.context);
//   }

//   final Axis scrollDirection;
//   final _DragItemUpdate? onUpdate;
//   final _DragItemCallback? onEnd;
//   final _DragItemCallback? onCancel;
//   final VoidCallback? onDropCompleted;
//   final ReorderItemProxyDecorator? proxyDecorator;
//   final TickerProvider tickerProvider;

//   late SliverReorderableListState listState;
//   late int index;
//   late Widget child;
//   late Offset dragPosition;
//   late Offset dragOffset;
//   late Size itemSize;
//   late double itemExtent;
//   late CapturedThemes capturedThemes;
//   ScrollableState? scrollable;
//   AnimationController? _proxyAnimation;

//   void dispose() {
//     _proxyAnimation?.dispose();
//   }

//   void startDrag() {
//     _proxyAnimation = AnimationController(
//       vsync: tickerProvider,
//       duration: const Duration(milliseconds: 250),
//     )
//     ..addStatusListener((AnimationStatus status) {
//       if (status == AnimationStatus.dismissed) {
//         _dropCompleted();
//       }
//     })
//     ..forward();
//   }

//   @override
//   void update(DragUpdateDetails details) {
//     final Offset delta = _restrictAxis(details.delta, scrollDirection);
//     dragPosition += delta;
//     onUpdate?.call(this, dragPosition, details.delta);
//   }

//   @override
//   void end(DragEndDetails details) {
//     _proxyAnimation!.reverse();
//     onEnd?.call(this);
//   }

//   @override
//   void cancel() {
//     _proxyAnimation?.dispose();
//     _proxyAnimation = null;
//     onCancel?.call(this);
//   }

//   void _dropCompleted() {
//     _proxyAnimation?.dispose();
//     _proxyAnimation = null;
//     onDropCompleted?.call();
//   }

//   Widget createProxy(BuildContext context) {
//     return capturedThemes.wrap(
//       _DragItemProxy(
//         listState: listState,
//         index: index,
//         size: itemSize,
//         animation: _proxyAnimation!,
//         position: dragPosition - dragOffset - _overlayOrigin(context),
//         proxyDecorator: proxyDecorator,
//         child: child,
//       ),
//     );
//   }
// }

// class ReorderableDragStartListener extends StatelessWidget {
//   /// Creates a listener for a drag immediately following a pointer down
//   /// event over the given child widget.
//   ///
//   /// This is most commonly used to wrap part of a list item like a drag
//   /// handle.
//   const ReorderableDragStartListener({
//     super.key,
//     required this.child,
//     required this.index,
//     this.enabled = true,
//   });

//   /// The widget for which the application would like to respond to a tap and
//   /// drag gesture by starting a reordering drag on a reorderable list.
//   final Widget child;

//   /// The index of the associated item that will be dragged in the list.
//   final int index;

//   /// Whether the [child] item can be dragged and moved in the list.
//   ///
//   /// If true, the item can be moved to another location in the list when the
//   /// user taps on the child. If false, tapping on the child will be ignored.
//   final bool enabled;

//   @override
//   Widget build(BuildContext context) {
//     return Listener(
//       onPointerDown: enabled
//           ? (PointerDownEvent event) => _startDragging(context, event)
//           : null,
//       child: child,
//     );
//   }

//   /// Provides the gesture recognizer used to indicate the start of a reordering
//   /// drag operation.
//   ///
//   /// By default this returns an [ImmediateMultiDragGestureRecognizer] but
//   /// subclasses can use this to customize the drag start gesture.
//   @protected
//   MultiDragGestureRecognizer createRecognizer() {
//     return ImmediateMultiDragGestureRecognizer(debugOwner: this);
//   }

//   void _dragStart(Offset pos) {

//   }

//   void _startDragging(BuildContext context, PointerDownEvent event) {
//     final DeviceGestureSettings? gestureSettings =
//         MediaQuery.maybeOf(context)?.gestureSettings;
//     final reco = createRecognizer()
//       ..gestureSettings = gestureSettings
//       ..onStart = _dragStart
//       ..addPointer(event);
//   }
// }

class FleatherGutter extends StatelessWidget {
  final Widget child;
  // final RenderEditor renderEditor;
  final GlobalKey<EditorState> editorKey;
  const FleatherGutter(
      {required this.child, required this.editorKey, super.key});

  @override
  Widget build(BuildContext context) {
    OverlayEntry? oe;
    double lastDy = -1;
    OverlayEntry? oeD;
    double lastDyD = -1;
    // final renderEditor = editorKey.currentState?.renderEditor;

    void addDropOverlay(double dy, double height) {
      final renderEditor = editorKey.currentState?.renderEditor;

      if (oeD != null && dy == lastDyD) return;
      lastDyD = dy;
      if (oeD != null) {
        oeD?.remove();
        oeD = null;
      }

      // ReorderableDragStartListener
      oeD = OverlayEntry(
        builder: (context) {
          print("POS: ${dy}");
          return Positioned(
            top: dy,
            left: renderEditor!.localToGlobal(Offset.zero).dx,
            width: renderEditor.size.width,
            height: 2,
            child: Container(
              // width: 32,
              color: Colors.amber,
            ),
          );
        },
      );
      Overlay.of(context)?.insert(oeD!);
    }

    void addOverlay(double dy, double height) {
      final renderEditor = editorKey.currentState?.renderEditor;

      if (oe != null && dy == lastDy) return;
      lastDy = dy;
      if (oe != null) {
        oe?.remove();
        oe = null;
      }
      final draggable = Draggable<int>(
        // Data is the value this Draggable stores.
        data: 10,
        feedback: Container(
          // color: Colors.deepOrange,
          height: 100,
          width: 100,
          child: const Icon(Icons.directions_run),
        ),
        childWhenDragging: Container(
          height: 32.0,
          width: 32.0,
          color: Colors.pinkAccent,
          child: const Center(
            child: Icon(Icons.drag_handle),
          ),
        ),
        child: Container(
          height: 32.0,
          width: 32.0,
          // color: Colors.lightGreenAccent,
          child: const Center(
            child: Icon(Icons.drag_handle),
          ),
        ),
      );
      // ReorderableDragStartListener
      oe = OverlayEntry(
        builder: (context) {
          print("POS: ${dy}");
          return Positioned(
            top: dy,
            left: renderEditor!.localToGlobal(Offset.zero).dx,
            height: height,
            child: Container(
              width: 32,
              child: Center(child: draggable
                  //Icon(Icons.drag_handle)
                  ),
            ),
          );
        },
      );
      Overlay.of(context)?.insert(oe!);
    }

    return MouseRegion(
        onHover: (event) {
          final renderEditor = editorKey.currentState?.renderEditor;

          final pos = event.position;

          if (renderEditor == null) {
            print("np rendereDi");
            return;
          }

          // renderEditor.getPositionForOffset(offset)
          final lpos = renderEditor.globalToLocal(pos);
          final line = renderEditor.childAtOffset(lpos);
          // final parentData = line.parentData as BoxParentData;
          //final localOffset = local -
          final tl = line.localToGlobal(Offset.zero);

          // print("tl: ${tl} - ${pos} ${parentData.offset}");
          addOverlay(tl.dy, line.size.height);
          // line.getLineBoundary(position)
        },
        child: DragTarget<int>(
          onMove: (details) {
            final renderEditor = editorKey.currentState?.renderEditor;

            print("on move");
            if (renderEditor == null) return;

            final lpos = renderEditor.globalToLocal(details.offset);
            final line = renderEditor.childAtOffset(lpos);
            // final parentData = line.parentData as BoxParentData;
            //final localOffset = local -
            final tl = line.localToGlobal(Offset.zero);
            addDropOverlay(tl.dy, line.size.height);
          },
          builder: (context, candidateData, rejectedData) {
            return child;
          },
        ));
  }
}
