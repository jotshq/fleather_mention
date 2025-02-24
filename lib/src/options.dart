import 'dart:async';

import 'package:fleather/fleather.dart';
import 'package:flutter/widgets.dart';

class EmbedMentionData {
  // text or an embed object
  Object data;
  List<ParchmentAttribute> attrs;

  EmbedMentionData.text(String text, String link)
      : this._(data: text, attrs: [ParchmentAttribute.link.fromString(link)]);

  EmbedMentionData.link(String text, String link)
      : data = text,
        attrs = [ParchmentAttribute.link.fromString(link)];

  EmbedMentionData.embed(Object embed)
      : data = embed,
        attrs = [];

  EmbedMentionData.removeTrigger()
      : data = '',
        attrs = [];

  EmbedMentionData._({required this.data, this.attrs = const []});
}

typedef MentionSuggestionsBuilder = FutureOr<List<MentionData>> Function(
    String trigger, String query);

typedef MentionSuggestionItemBuilder = Widget Function(BuildContext context,
    MentionData data, String query, bool selected, void Function() onTap);

typedef MentionOverlayBuilder = Widget Function(
    BuildContext context,
    String trigger,
    String query,
    List<MentionData> suggestions,
    int suggestionIndex,
    void Function(MentionData data) onTap);

typedef EmbedMentionBuilder = EmbedMentionData? Function(
    FleatherController controller,
    int mentionStart,
    int mentionLength,
    MentionData data);

class MentionOptions {
  final List<String> mentionTriggers;

  final MentionSuggestionsBuilder suggestionsBuilder;
  // final MentionSuggestionItemBuilder itemBuilder;
  final MentionOverlayBuilder overlayBuilder;
  final EmbedMentionBuilder mentionBuilder;

  MentionOptions({
    required this.mentionTriggers,
    required this.suggestionsBuilder,
    // required this.itemBuilder,
    required this.overlayBuilder,
    required this.mentionBuilder,
  }) : assert(mentionTriggers.isNotEmpty);
}

class MentionData {
  final String value, trigger;
  final Map<String, dynamic> payload;

  /// if true this is a MentionData that can be selectable
  /// in this case we expect to have a value and a trigger
  ///
  /// non-selectable items can be used to make separators or sections
  ///
  final bool selectable;

  const MentionData(
      {required this.value,
      required this.trigger,
      this.selectable = true,
      this.payload = const {}});

  factory MentionData.fromJson(Map<String, dynamic> map) =>
      MentionData(value: map['value'], trigger: map['trigger'], payload: map);

  Map<String, dynamic> toJson() =>
      {...payload, 'value': value, 'trigger': trigger};
}
