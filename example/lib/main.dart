import 'package:fleather/fleather.dart';
import 'package:fleather_mention/fleather_mention.dart';
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
      body: Column(
        children: <Widget>[
          FleatherToolbar.basic(controller: controller),
          Divider(height: 1),
          Expanded(
            child: FleatherMention.withEditor(
              options: options,
              child: _buildEditor(),
            ),
          ),
        ],
      ),
    );
  }

  FleatherEditor _buildEditor() => FleatherEditor(
        controller: controller,
        focusNode: focusNode,
        editorKey: editorKey,
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
