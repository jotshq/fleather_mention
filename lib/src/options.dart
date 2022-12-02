import 'dart:async';

import 'package:flutter/widgets.dart';

typedef MentionSuggestionsBuilder = FutureOr<Iterable<MentionData>> Function(
    String trigger, String query);

typedef MentionSuggestionItemBuilder = Widget Function(BuildContext context,
    MentionData data, String query, bool selected, void Function() onTap);

typedef MentionBuilder = Widget Function(
    BuildContext context,
    String trigger,
    String query,
    Iterable<MentionData> suggestions,
    void Function(MentionData data) onTap);

class MentionOptions {
  final Iterable<String> mentionTriggers;
  final MentionSuggestionsBuilder suggestionsBuilder;
  final MentionSuggestionItemBuilder itemBuilder;
  final MentionBuilder builder;

  MentionOptions({
    required this.mentionTriggers,
    required this.suggestionsBuilder,
    required this.itemBuilder,
    required this.builder,
  }) : assert(mentionTriggers.isNotEmpty);
}

class MentionData {
  final String value, trigger;
  final Map<String, dynamic> payload;

  /** if true this is a MentionData that can be selectable
   *  in this case we expect to have a value and a trigger
   *
   *  non selectable items can be used to make separators or sections
   */
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
