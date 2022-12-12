import 'dart:math';

import 'package:example/fleather_gutter.dart';
import 'package:example/floating_widget_span.dart';
import 'package:fleather/fleather.dart';
import 'package:fleather_mention/fleather_mention.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

void main() => runApp(const MyApp());

class DemoList extends StatelessWidget {
  const DemoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
              child: ListView(
            children: [
              ListTile(
                title: Text("A"),
                onTap: () => print("A"),
              ),
              ListTile(
                title: Text("B"),
                onTap: () => print("A"),
              ),
              ListTile(
                title: Text("C"),
                onTap: () => print("A"),
              ),
            ],
          ))
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Portal(
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const MyHomePage(),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final scrollController = ScrollController();
  final controller = FleatherController();
  final focusNode = FocusNode();
  final editorKey = GlobalKey<EditorState>();
  final options = MentionOptions(
    mentionTriggers: ['#', '@'],
    builder: (context, trigger, query, suggestions, onTap) {
      final sel = AutocompleteHighlightedOption.of(context) %
          (suggestions.length > 0 ? suggestions.length : 1);
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
        color: Colors.amber,
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: SizedBox(
              width: 200,
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
      final List<String> data;
      if (trigger == '#') {
        data = ['Android', 'iOS', 'Windows', 'macOs', 'Web', 'Linux'];
      } else {
        data = ['Hibato', 'Madina', 'Quentin', 'Cedric', 'Emilia', 'Cathy'];
      }
      return data
          .where((e) => e.toLowerCase().contains(query.toLowerCase()))
          .map((e) => MentionData(value: e, trigger: trigger))
          .toList();
    },
    itemBuilder: (context, data, query, selected, onTap) {
      if (data.selectable) {
        return ListTile(
          onTap: onTap,
          title: Text(data.value),
          selected: selected,
        );
      } else {
        return Container(
            color: Colors.amberAccent, child: Text(data.value.toUpperCase()));
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fleather mention demo'),
        actions: [TextButton(onPressed: () {}, child: Text("TT"))],
      ),
      body: Container(
        color: Colors.blue,
        padding: EdgeInsets.all(8),
        margin: EdgeInsets.all(8),
        child: Container(
          color: Colors.white,
          child: MentionScrollListener(
            child: CustomScrollView(
              controller: scrollController,
              slivers: <Widget>[
                SliverToBoxAdapter(
                    child: FleatherToolbar.basic(controller: controller)),
                SliverPadding(padding: EdgeInsets.all(8)),
                // Divider(height: 1),
                SliverToBoxAdapter(
                  child: FleatherMention.withEditor(
                    options: options,
                    child: _buildEditor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  FleatherEditor _buildEditor() => FleatherEditor(
        controller: controller,
        scrollController: scrollController,
        scrollable: false,
        focusNode: focusNode,
        editorKey: editorKey,
        // customTextSpan: customTextSpan,
        padding: EdgeInsets.all(32),
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

// class MentionScrollNotifier extends InheritedNotifier {
//   const MentionScrollNotifier({
//     super.key,
//     required this.notifier,
//     required super.child,
//   });

//   final ScrollNotification notification;

//   static MentionScrollNotifier of(BuildContext context) {
//     final MentionScrollNotifier? result =
//         context.dependOnInheritedWidgetOfExactType<MentionScrollNotifier>();
//     assert(result != null, 'No MentionScrollNotifier found in context');
//     return result!;
//     ScrollNotificationObserver
//   }

//   // @override
//   // bool updateShouldNotify(MentionScrollNotifier old) =>
//   //     notification != old.notification;
// }

class MentionScrollListener extends StatelessWidget {
  final Widget child;
  const MentionScrollListener({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollNotificationObserver(child: child);
  }
}

// class CustomTextLinkPortal extends StatelessWidget {
//   final ValueNotifier<bool> vn;
//   const CustomTextLinkPortal(
//     this.vn, {
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder(
//         valueListenable: vn,
//         builder: (BuildContext context, bool visibleValue, Widget? child) {
//           return PortalTarget(
//               visible: visibleValue,
//               child: Container(width: 10, height: 10, color: Colors.blueAccent),
//               anchor: Aligned(
//                   follower: Alignment.topCenter,
//                   target: Alignment.bottomCenter),
//               portalFollower:
//                   Container(width: 10, height: 10, color: Colors.amber));
//         });
//   }
// }
