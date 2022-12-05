import 'dart:async';
import 'dart:math';

import 'package:fleather/fleather.dart';
import 'package:fleather_mention/fleather_mention.dart';
import 'package:fleather_mention/src/positioned_from_rect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'options.dart';

class MentionOverlay {
  final BuildContext context;
  final RenderEditor renderObject;
  final Widget debugRequiredFor;
  final FutureOr<Iterable<MentionData>> suggestions;
  final String query, trigger;
  final TextEditingValue textEditingValue;
  final Function(MentionData)? suggestionSelected;
  final MentionSuggestionItemBuilder itemBuilder;
  final MentionBuilder builder;

  OverlayEntry? overlayEntry;
  int? selected;
  final ValueNotifier<int> highlightedOptionIndex;
  Iterable<MentionData>? currentSuggestions;

  MentionOverlay({
    required this.highlightedOptionIndex,
    required this.textEditingValue,
    required this.context,
    required this.renderObject,
    required this.debugRequiredFor,
    required this.suggestions,
    required this.itemBuilder,
    required this.builder,
    required this.query,
    required this.trigger,
    this.suggestionSelected,
  });

  void show() {
    final parentContext = context;
    overlayEntry = OverlayEntry(
        builder: (context) => FutureBuilder<Iterable<MentionData>>(
              future: Future.value(suggestions),
              builder: (context, snapshot) {
                final data = snapshot.data;
                currentSuggestions = data;
                if (data == null) {
                  return const SizedBox();
                }
                // ScrollNotificationObserver.of(parentContext)?.addListener(
                //   (notification) {
                //     print("notif: ${notification}");
                //   },
                // );
                // ScrollNotificationObserver.of(myCtx)?.
                final suggestions = _MentionSuggestionList(
                  parentContext: parentContext,
                  renderObject: renderObject,
                  suggestions: data,
                  textEditingValue: textEditingValue,
                  suggestionSelected: suggestionSelected,
                  itemBuilder: itemBuilder,
                  builder: builder,
                  query: query,
                  trigger: trigger,
                );
                return AutocompleteHighlightedOption(
                    highlightIndexNotifier: highlightedOptionIndex,
                    child: suggestions);
              },
            ));
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)
        ?.insert(overlayEntry!);
  }

  void doSelect() {
    final c = currentSuggestions;
    // print("IC");
    if (c == null) return;
    final m = c.elementAt(highlightedOptionIndex.value);
    // print("M: ${m}");
    suggestionSelected?.call(m);
  }

  void updateForScroll() => overlayEntry?.markNeedsBuild();

  void hide() => overlayEntry?.remove();

  void dispose() {
    hide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayEntry?.dispose();
      overlayEntry = null;
    });
  }
}

const double listMaxHeight = 240;
const double listMaxWidth = 400;

class ScrollUpdater extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final BuildContext parentContext;

  const ScrollUpdater(
      {required this.builder, required this.parentContext, super.key});

  @override
  State<ScrollUpdater> createState() => _ScrollUpdaterState();
}

class _ScrollUpdaterState extends State<ScrollUpdater> {
  ScrollNotification? notification;
  ScrollNotificationObserverState? sno;

  void _onScroll(notification) {
    WidgetsBinding.instance.addPostFrameCallback((Duration d) {
      setState(() {
        notification = notification;
      });
    });
    // print("notif2: ${notification}");
  }

  @override
  void didChangeDependencies() {
    if (sno != null) {
      sno!.removeListener(_onScroll);
    }
    sno = ScrollNotificationObserver.of(widget.parentContext);
    sno?.addListener(_onScroll);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    sno?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

class _MentionSuggestionList extends StatelessWidget {
  final RenderEditor renderObject;
  final Iterable<MentionData> suggestions;
  final String query, trigger;
  final TextEditingValue textEditingValue;
  final Function(MentionData)? suggestionSelected;
  final MentionSuggestionItemBuilder itemBuilder;
  final MentionBuilder builder;
  final BuildContext parentContext;

  const _MentionSuggestionList({
    Key? key,
    required this.parentContext,
    required this.renderObject,
    required this.suggestions,
    required this.textEditingValue,
    required this.itemBuilder,
    required this.builder,
    required this.query,
    required this.trigger,
    this.suggestionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final builder = positionedFromTextPos(
        context,
        renderObject,
        TextPosition(offset: textEditingValue.selection.start),
        listMaxHeight,
        listMaxWidth,
        _buildOverlayWidget(context));
    return builder;
    return ScrollUpdater(
        parentContext: parentContext, builder: (context) => builder);
  }

  Widget _buildOverlayWidget(BuildContext context) {
    return builder(context, trigger, query, suggestions, suggestionSelected!);
  }

  Widget _defaultBuilder(BuildContext context, String trigger, String query) {
    final children = <Widget>[];
    final sel = AutocompleteHighlightedOption.of(context) % suggestions.length;
    print("SEL: ${sel}");
    int i = 0;

    for (var s in suggestions) {
      children.add(_buildListItem(context, s, query, sel == i));
      i++;
    }

    final c = Card(
      child: SingleChildScrollView(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
    return c;
  }

  Widget _buildListItem(
          BuildContext context, MentionData data, String text, bool selected) =>
      itemBuilder(
          context, data, query, selected, () => suggestionSelected?.call(data));
}
