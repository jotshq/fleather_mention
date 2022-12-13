import 'package:fleather_mention/fleather_mention.dart';
import 'package:fleather_mention/src/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/enhanced_composited_transform.dart';
import 'package:flutter_portal/flutter_portal.dart';

import 'options.dart';

class MentionOverlay extends StatelessWidget {
  final MentionController mentionController;
  final MentionOptions options;
  final EnhancedLayerLink layerLink;
  final void Function(MentionData) suggestionSelected;

  const MentionOverlay(
      {Key? key,
      required this.options,
      required this.layerLink,
      required this.mentionController,
      required this.suggestionSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MentionState?>(
        stream: mentionController.stream.stream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? mentionController.lastState;
          print("Data ${state}");
          if (state == null || state.visible == false) {
            return const SizedBox();
          }
          return Positioned(
              top: 0,
              left: 0,
              child: EnhancedCompositedTransformFollower(
                targetSize: const Size(0, 24),
                showWhenUnlinked: false,
                link: layerLink,
                anchor: const Aligned(
                    follower: Alignment.topLeft,
                    target: Alignment.bottomLeft,
                    shiftToWithinBound: AxisFlag(x: true, y: false)),
                child: _buildOverlayWidget(context, state),
              ));
        });
  }

  Widget _buildOverlayWidget(BuildContext context, MentionState state) {
    print(state.suggestions);
    // return Container(width: 10, height: 10, color: Colors.amber);
    return options.overlayBuilder(context, state.trigger, state.query,
        state.suggestions, state.suggestionIndex, suggestionSelected);
  }

  // Widget _defaultBuilder(BuildContext context, String trigger, String query) {
  //   final children = <Widget>[];
  //   final sel = AutocompleteHighlightedOption.of(context) % suggestions.length;
  //   print("SEL: ${sel}");
  //   int i = 0;

  //   for (var s in suggestions) {
  //     children.add(_buildListItem(context, s, query, sel == i));
  //     i++;
  //   }

  //   final c = Card(
  //     child: SingleChildScrollView(
  //       child: IntrinsicWidth(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: children,
  //         ),
  //       ),
  //     ),
  //   );
  //   return c;
  // }

  // Widget _buildListItem(
  //         BuildContext context, MentionData data, String text, bool selected) =>
  //     itemBuilder(
  //         context, data, query, selected, () => suggestionSelected?.call(data));
}
