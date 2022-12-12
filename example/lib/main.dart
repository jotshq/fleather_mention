import 'dart:async';
import 'dart:math';

import 'package:example/fleather_gutter.dart';
import 'package:example/floating_widget_span.dart';
import 'package:fleather/fleather.dart';
import 'package:fleather_mention/fleather_mention.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/enhanced_composited_transform.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_portal/src/portal_theater.dart';
import 'package:flutter_portal/src/portal_link.dart';

void main() => runApp(const MyApp());

final portalLink = PortalLink();

final doc = [
  {"insert": "Fleather"},
  {
    "insert": "\n",
  },
  {"insert": "Fleather"},
  {
    "insert": "\n",
  },
  {"insert": "Fleather"},
  {
    "insert": "\n",
  },
  {
    "insert":
        "Fle@ ather is a @free and open-source rich text editor for Flutter and uses Quill.js delta as underlying data format via Parchment."
  },
  {
    "insert": "\n",
  },
  {
    "insert": "\n",
  },
  {
    "insert": "\n",
  },
  {
    "insert": "\n",
  },
  {
    "insert": "\n",
  },
  {
    "insert": "\n",
  },
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Portal(
          child: PortalTheater(
        debugName: "app",
        portalLink: portalLink,
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const MyHomePage(),
        ),
      ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final anchors = [TextAnchor(TextPosition(offset: 28))];
  bool init = false;
  final controller = FleatherController(ParchmentDocument.fromJson(doc));
  final focusNode = FocusNode();
  final editorKey = GlobalKey<EditorState>();
  OverlayEntry? oe2;

  final options = MentionOptions(
    mentionTriggers: ['#', '@'],
    mentionBuilder: (controller, mentionStart, mentionLength, data) {
      final link = 'mention://${data.trigger}/${data.value}';
      return EmbedMentionData.link(data.value, link);
    },
    overlayBuilder:
        (context, trigger, query, suggestions, suggestionIndex, onTap) {
      final sel = suggestionIndex;
      int i = 0;
      final children = <Widget>[];
      for (var s in suggestions) {
        children.add(ListTile(
          onTap: () => onTap(s),
          title: Text(s.value),
          selected: i == sel,
        ));

        i++;
      }

      final c = Container(
        width: 200,
        color: Colors.amber,
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: SizedBox(
              // width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      );
      return c;
    },
    suggestionsBuilder: (trigger, query) {
      final List<MentionData> data;
      // if (trigger == '#') {
      //   data = ['Android', 'iOS', 'Windows', 'macOs', 'Web', 'Linux'];
      // } else {
      //   data = ['Hibato', 'Madina', 'Quentin', 'Cedric', 'Emilia', 'Cathy'];
      // }
      data = [
        MentionData(value: "-b-", trigger: trigger, selectable: false),
        MentionData(value: "-b-", trigger: trigger, selectable: false),
        MentionData(value: "a", trigger: trigger),
        MentionData(value: "-b-", trigger: trigger, selectable: false),
        MentionData(value: "b", trigger: trigger),
        MentionData(value: "-b-", trigger: trigger, selectable: false),
        MentionData(value: "c", trigger: trigger),
        MentionData(value: "-b-", trigger: trigger, selectable: false),
        MentionData(value: "d", trigger: trigger),
        MentionData(value: "-b-", trigger: trigger, selectable: false),
        MentionData(value: "d2", trigger: trigger),
        MentionData(value: "e", trigger: trigger),
        MentionData(value: "-b-", trigger: trigger, selectable: false),
        MentionData(value: "db3", trigger: trigger),
        MentionData(value: "db4", trigger: trigger),
        MentionData(value: "-b-", trigger: trigger, selectable: false),
      ];
      return data
          .where((e) => e.value.toLowerCase().contains(query.toLowerCase()))
          // .map((e) => MentionData(value: e, trigger: trigger))
          .toList();
    },
    // itemBuilder: (context, data, query, selected, onTap) {
    //   if (data.selectable) {
    //     return ListTile(
    //       onTap: onTap,
    //       title: Text(data.value),
    //       selected: selected,
    //     );
    //   } else {
    //     return Container(
    //         color: Colors.amberAccent, child: Text(data.value.toUpperCase()));
    //   }
    // },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fleather mention demo'),
        actions: [TextButton(onPressed: () {}, child: Text("TT"))],
      ),
      body: Column(
        children: <Widget>[
          FleatherToolbar.basic(controller: controller),
          Divider(height: 1),
          Expanded(
            child:
                // FleatherGutter(
                // editorKey: editorKey,
                // child:
                FleatherMention.withEditor(
              options: options,
              child: _buildEditor(),
            ),
            // ),
          ),
        ],
      ),
    );
  }

  FleatherEditor _buildEditor() => FleatherEditor(
        controller: controller,
        focusNode: focusNode,
        editorKey: editorKey,
        // customTextSpan: customTextSpan,
        padding: EdgeInsets.all(32),
        portalTheater: () => portalLink.theater!,
        embedBuilder: (context, node) {
          final mentionWidget = mentionEmbedBuilder(
            context,
            node,
            onTap: (data) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(data.value))),
          );
          if (mentionWidget != null) {
            return mentionWidget;
          }
          throw UnimplementedError();
        },
      );
}
