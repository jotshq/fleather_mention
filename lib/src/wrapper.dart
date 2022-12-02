import 'package:fleather/fleather.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'options.dart';
import 'overlay.dart';
import 'utils.dart';

class MentionDirectionalFocusIntent extends Intent {
  const MentionDirectionalFocusIntent(this.direction);
  final TraversalDirection direction;
}

class MentionSelectIntent extends Intent {
  const MentionSelectIntent();
}

abstract class MentionAction<T extends Intent> extends Action<T> {
  final _FleatherMentionState mo;

  MentionAction(this.mo);

  @override
  bool get isActionEnabled {
    if (mo._mentionOverlay != null) {
      return true;
    }
    return false;
  }

  @override
  bool consumesKey(T intent) {
    // if (mo._mentionOverlay != null) {
    print("consume? YES ${intent}");
    return true;
    // }
    // print("consume? NO ${intent}");
    // return false;
  }
}

class MentionSelectAction extends MentionAction<MentionSelectIntent> {
  MentionSelectAction(super.mo);

  @override
  void invoke(covariant MentionSelectIntent intent) {
    print("ICI");
    mo._selectHighlight();
  }
}

class MentionDirectionalFocusAction
    extends MentionAction<MentionDirectionalFocusIntent> {
  MentionDirectionalFocusAction(super.mo);

  @override
  void invoke(covariant MentionDirectionalFocusIntent intent) {
    print("invoke dec");
    if (intent.direction == TraversalDirection.up) {
      mo._updateHighlight(-1);
    }
    if (intent.direction == TraversalDirection.down) {
      mo._updateHighlight(1);
    }
  }
}

class FleatherMention extends StatefulWidget {
  final Widget child;
  final MentionOptions options;
  final FleatherController controller;
  final FocusNode focusNode;
  final GlobalKey<EditorState> editorKey;

  const FleatherMention._({
    Key? key,
    required this.controller,
    required this.options,
    required this.child,
    required this.focusNode,
    required this.editorKey,
  }) : super(key: key);

  /// Constructs a FleatherMention with a FleatherEditor as it's child.
  /// The given FleatherEditor should have a FocusNode and editor key.
  factory FleatherMention.withEditor(
      {required MentionOptions options, required FleatherEditor child}) {
    assert(child.focusNode != null);
    assert(child.editorKey != null);
    return FleatherMention._(
      controller: child.controller,
      focusNode: child.focusNode!,
      editorKey: child.editorKey!,
      options: options,
      child: child,
    );
  }

  /// Constructs a FleatherMention with a FleatherField as it's child.
  /// The given FleatherField should have a FocusNode and editor key.
  factory FleatherMention.withField(
      {required MentionOptions options, required FleatherField child}) {
    assert(child.focusNode != null);
    assert(child.editorKey != null);
    return FleatherMention._(
      controller: child.controller,
      focusNode: child.focusNode!,
      editorKey: child.editorKey!,
      options: options,
      child: child,
    );
  }

  @override
  State<FleatherMention> createState() => _FleatherMentionState();
}

class _FleatherMentionState extends State<FleatherMention> {
  MentionOverlay? _mentionOverlay;
  bool _hasFocus = false;
  String? _lastQuery, _lastTrigger;
  final ValueNotifier<int> _highlightedOptionIndex = ValueNotifier<int>(0);

  FleatherController get _controller => widget.controller;

  FocusNode get _focusNode => widget.focusNode;

  MentionOptions get _options => widget.options;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDocumentUpdated);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onDocumentUpdated);
    _focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FleatherMention oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != _controller) {
      oldWidget.controller.removeListener(_onDocumentUpdated);
      _controller.addListener(_onDocumentUpdated);
    }
    if (oldWidget.focusNode != _focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  void _onDocumentUpdated() {
    _checkForMentionTriggers();
    _updateOrDisposeOverlayIfNeeded();
  }

  void _checkForMentionTriggers() {
    _lastTrigger = null;
    _lastQuery = null;

    if (!_controller.selection.isCollapsed) return;

    final plainText = _controller.document.toPlainText();
    final indexOfLastMentionTrigger = plainText
        .substring(0, _controller.selection.end)
        .lastIndexOf(RegExp(_options.mentionTriggers.join('|')));

    if (indexOfLastMentionTrigger < 0) return;

    if (plainText
        .substring(indexOfLastMentionTrigger, _controller.selection.end)
        .contains(RegExp(r'\n'))) {
      return;
    }

    _lastQuery = plainText.substring(
        indexOfLastMentionTrigger + 1, _controller.selection.end);
    _lastTrigger = plainText.substring(
        indexOfLastMentionTrigger, indexOfLastMentionTrigger + 1);
  }

  void _onFocusChanged() {
    _hasFocus = _focusNode.hasFocus;
    _updateOrDisposeOverlayIfNeeded();
  }

  void _updateHighlight(int newIndex) {
    _highlightedOptionIndex.value += newIndex;
    //_highlightedOptionIndex.value = _options.isEmpty ? 0 : newIndex % _options.length;
  }

  void _selectHighlight() {
    _mentionOverlay?.doSelect();
    //_highlightedOptionIndex.value += newIndex;

    //_highlightedOptionIndex.value = _options.isEmpty ? 0 : newIndex % _options.length;
  }

  void _updateOverlayForScroll() => _mentionOverlay?.updateForScroll();

  void _updateOrDisposeOverlayIfNeeded() {
    if (!_hasFocus || _lastQuery == null || _lastTrigger == null) {
      _mentionOverlay?.dispose();
      _mentionOverlay = null;
    } else {
      _mentionOverlay?.dispose();
      _mentionOverlay = MentionOverlay(
        highlightedOptionIndex: _highlightedOptionIndex,
        query: _lastQuery!,
        trigger: _lastTrigger!,
        context: context,
        debugRequiredFor: widget.editorKey.currentWidget!,
        itemBuilder: _options.itemBuilder,
        builder: _options.builder,
        suggestionSelected: _handleMentionSuggestionSelected,
        suggestions:
            _options.suggestionsBuilder.call(_lastTrigger!, _lastQuery!),
        textEditingValue: widget.editorKey.currentState!.textEditingValue,
        renderObject: widget.editorKey.currentState!.renderEditor,
      );
      _mentionOverlay!.show();
    }
  }

  void _handleMentionSuggestionSelected(MentionData data) {
    final controller = widget.controller;
    final mentionStartIndex = controller.selection.end - _lastQuery!.length - 1;
    final mentionedTextLength = _lastQuery!.length + 1;
    controller.replaceText(
      mentionStartIndex,
      mentionedTextLength,
      buildEmbeddableObject(data),
      selection: TextSelection.collapsed(offset: mentionStartIndex + 1),
    );
  }

  // we need to capture the up/down arrow for selection
  // only enabling them when we are active.
  // we cannot use the normal focus actions as the focus should be on the
  // textfield (to let the user continue editing text)
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _updateOverlayForScroll();
          return false;
        },
        child: Shortcuts(
            key: GlobalKey(),
            shortcuts: <ShortcutActivator, Intent>{
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const MentionDirectionalFocusIntent(TraversalDirection.down),
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const MentionDirectionalFocusIntent(TraversalDirection.up),
              LogicalKeySet(LogicalKeyboardKey.enter):
                  const MentionSelectIntent(),
            },
            child: Actions(
                actions: <Type, Action<Intent>>{
                  MentionDirectionalFocusIntent:
                      MentionDirectionalFocusAction(this),
                  MentionSelectIntent: MentionSelectAction(this),
                  // DismissIntent
                },
                child: //Focus(autofocus: true, child: Text('count: '))
                    Focus(autofocus: true, child: widget.child))),
      );
}
