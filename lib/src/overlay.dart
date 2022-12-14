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
          if (state == null || state.visible == false) {
            return const SizedBox();
          }

          return Positioned(
              top: 0,
              left: 0,
              child: EnhancedCompositedTransformFollower(
                //TODO. this is incorrect.
                targetSize: const Size(0, 24),
                showWhenUnlinked: false,
                link: layerLink,
                anchor: const Aligned(
                    follower: Alignment.topLeft,
                    target: Alignment.bottomLeft,
                    shiftToWithinBound: AxisFlag(x: true),
                    backup: Aligned(
                        follower: Alignment.bottomLeft,
                        target: Alignment.topLeft,
                        shiftToWithinBound: AxisFlag(x: true))),
                child: options.overlayBuilder(
                    context,
                    state.trigger,
                    state.query,
                    state.suggestions,
                    state.suggestionIndex,
                    suggestionSelected),
              ));
        });
  }
}
