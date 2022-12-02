import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_portal/flutter_portal.dart';

import 'const.dart';
import 'options.dart';

class MentionWidget extends StatefulWidget {
  final MentionData data;
  final void Function(MentionData)? onTap;

  const MentionWidget(this.data, this.onTap, {super.key});

  @override
  State<MentionWidget> createState() => _MentionWidgetState();
}

class _MentionWidgetState extends State<MentionWidget> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        hover = true;
      }),
      onExit: (_) => setState(() {
        hover = false;
      }),
      child: GestureDetector(
        onTap: () => widget.onTap?.call(widget.data),
        child: PortalTarget(
            visible: hover,
            portalFollower:
                Container(height: 42, width: 42, color: Colors.amberAccent),
            anchor: const Aligned(
              follower: Alignment.topLeft,
              target: Alignment.bottomLeft,
              widthFactor: 1,
              backup: Aligned(
                follower: Alignment.bottomLeft,
                target: Alignment.topLeft,
                widthFactor: 1,
              ),
            ),
            child: Text('${widget.data.trigger}${widget.data.value}')),
      ),
    );
  }
}

Widget? mentionEmbedBuilder(BuildContext context, EmbedNode node,
    {Function(MentionData)? onTap}) {
  if (node.value.type == mentionEmbedKey && node.value.inline) {
    try {
      final data = MentionData.fromJson(node.value.data);
      return MentionWidget(data, onTap);
    } catch (_) {}
  }
  return null;
}
