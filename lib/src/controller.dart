import 'dart:async';

import 'package:fleather_mention/fleather_mention.dart';

class MentionState {
  MentionState(this.triggerPos, this.trigger);
  int triggerPos;
  String trigger;
  List<MentionData> suggestions = [];
  String query = "";
  int suggestionIndex = 0;
  bool visible = true;

  int get queryPos => triggerPos + trigger.length;
}

class MentionController {
  final stream = StreamController<MentionState?>.broadcast();
  MentionState? lastState;
  void Function(MentionData) onValidate;
  MentionOptions options;

  MentionController(this.onValidate, this.options);

  void _setState(MentionState? state) {
    lastState = state;
    stream.add(state);
  }

  void setTrigger(int triggerPos, String trigger) {
    final state = MentionState(triggerPos, trigger);
    _setState(state);
    setQuery('');
  }

  void setQuery(String query) {
    final state = lastState;
    if (state == null) throw Exception("Invalid state");
    final suggestions = options.suggestionsBuilder(state.trigger, query);
    state
      ..query = query
      ..suggestionIndex = 0
      ..suggestions = []
      ..visible = true;

    if (suggestions is Future<List<MentionData>>) {
      suggestions.then((value) {
        state.suggestions = value;
        _setState(state);
      });
      return;
    }
    state.suggestions = suggestions;
    _setState(state);
    // ensure our suggestion is actually selectable
    select(0);
  }

  void select(int steps) {
    final state = lastState;
    if (state == null) throw Exception("Invalid state");
    if (state.suggestions.isEmpty) return;
    int moduloLen = state.suggestions.length;
    int newIndex = (state.suggestionIndex + steps) % moduloLen;
    int startIndex = newIndex;
    bool starting = true;
    while (starting || newIndex != startIndex) {
      starting = false;
      final sug = state.suggestions[newIndex];
      if (sug.selectable == true) break;
      if (steps < 0) {
        newIndex -= 1;
      } else {
        newIndex += 1;
      }
      newIndex %= moduloLen;
    }
    if (newIndex >= state.suggestions.length || newIndex < 0) {
      newIndex = 0;
    }
    state.suggestionIndex = newIndex;
    _setState(state);
  }

  void validate() {
    final state = lastState;
    if (state == null) throw Exception("Invalid state");
    onValidate(state.suggestions[state.suggestionIndex]);
  }

  void toggle(bool visible) {
    final state = lastState;
    if (state == null) return;
    state.visible = visible;
    _setState(state);
  }

  void dismiss() {
    _setState(null);
  }
}
