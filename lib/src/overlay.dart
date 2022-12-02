import 'dart:async';
import 'dart:math';

import 'package:fleather/fleather.dart';
import 'package:fleather_mention/fleather_mention.dart';
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
    overlayEntry = OverlayEntry(
        builder: (context) => FutureBuilder<Iterable<MentionData>>(
              future: Future.value(suggestions),
              builder: (context, snapshot) {
                final data = snapshot.data;
                currentSuggestions = data;
                if (data == null) {
                  return const SizedBox();
                }
                final suggestions = _MentionSuggestionList(
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

class _MentionSuggestionList extends StatelessWidget {
  final RenderEditor renderObject;
  final Iterable<MentionData> suggestions;
  final String query, trigger;
  final TextEditingValue textEditingValue;
  final Function(MentionData)? suggestionSelected;
  final MentionSuggestionItemBuilder itemBuilder;
  final MentionBuilder builder;

  const _MentionSuggestionList({
    Key? key,
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
    final endpoints =
        renderObject.getEndpointsForSelection(textEditingValue.selection);
    final editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );
    final baseLineHeight =
        renderObject.preferredLineHeight(textEditingValue.selection.base);
    //final listMaxWidth = editingRegion.width / 2;
    final mediaQueryData = MediaQuery.of(context);
    final screenHeight = mediaQueryData.size.height;
    final screenWidth = mediaQueryData.size.width;

    double? positionFromTop = endpoints[0].point.dy + editingRegion.top;
    double? positionFromBottom;

    if (positionFromTop + listMaxHeight >
        screenHeight - mediaQueryData.viewInsets.bottom) {
      positionFromTop = null;
      positionFromBottom = screenHeight - editingRegion.bottom + baseLineHeight;
    }

    double? positionFromLeft = endpoints[0].point.dx + editingRegion.left;
    double? positionFromRight;
    positionFromLeft = min(positionFromLeft, screenWidth - 32 - listMaxWidth);
    if (positionFromLeft < 16) positionFromLeft = 16;

    positionFromRight = (screenWidth - 16) - positionFromLeft - listMaxWidth;
    if (positionFromRight < 16) {
      positionFromRight = 16;
    }

    return Positioned(
      top: positionFromTop,
      bottom: positionFromBottom,
      left: positionFromLeft,
      right: positionFromRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxWidth: listMaxWidth, maxHeight: listMaxHeight),
        child: _buildOverlayWidget(context),
      ),
    );
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
