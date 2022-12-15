import 'dart:async';

import 'package:fleather/fleather.dart';
import 'package:fleather_mention/src/controller.dart';
import 'package:fleather_mention/src/delta_utils.dart';
import 'package:fleather_mention/src/shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'options.dart';
import 'overlay.dart';

class FleatherMention extends StatefulWidget {
  final Widget child;
  final MentionOptions options;
  final FleatherController controller;
  final FocusNode focusNode;
  final GlobalKey<EditorState> editorKey;
  final bool readOnly;

  const FleatherMention._({
    Key? key,
    required this.controller,
    required this.options,
    required this.child,
    required this.focusNode,
    required this.editorKey,
    required this.readOnly,
  }) : super(key: key);

  /// Constructs a FleatherMention with a FleatherEditor as it's child.
  /// The given FleatherEditor should have a FocusNode and editor key.
  factory FleatherMention.withEditor({
    required MentionOptions options,
    required FleatherEditor child,
  }) {
    assert(child.focusNode != null);
    assert(child.editorKey != null);
    return FleatherMention._(
      controller: child.controller,
      focusNode: child.focusNode!,
      editorKey: child.editorKey!,
      options: options,
      readOnly: child.readOnly,
      child: child,
    );
  }

  /// Constructs a FleatherMention with a FleatherField as it's child.
  /// The given FleatherField should have a FocusNode and editor key.
  factory FleatherMention.withField({
    required MentionOptions options,
    required FleatherField child,
  }) {
    assert(child.focusNode != null);
    assert(child.editorKey != null);
    return FleatherMention._(
      controller: child.controller,
      focusNode: child.focusNode!,
      editorKey: child.editorKey!,
      options: options,
      readOnly: child.readOnly,
      child: child,
    );
  }

  @override
  State<FleatherMention> createState() => _FleatherMentionState();
}

class _FleatherMentionState extends State<FleatherMention> {
  bool _hasFocus = false;
  OverlayEntry? _overlayEntry;

  late final MentionController _mentionController;
  StreamSubscription<ParchmentChange>? _sub;
  StreamSubscription<MentionState?>? _sub2;

  TextAnchor anchor = TextAnchor(const TextPosition(offset: 0));

  @override
  void initState() {
    super.initState();
    _mentionController =
        MentionController(_handleMentionSuggestionSelected, widget.options);
    _sub2 = _mentionController.stream.stream.listen(_onMentionStateChange);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.controller.addAnchor(anchor);
    });

    widget.controller.document.changes.listen(_onDocChanges);
    widget.controller.addListener(_onChanges);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _hideOverlay();
    widget.controller.removeAnchor(anchor);
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onChanges);
    _sub?.cancel();
    _sub2?.cancel();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FleatherMention oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _sub?.cancel();
      oldWidget.controller.removeAnchor(anchor);
      widget.controller.addAnchor(anchor);
      widget.controller.document.changes.listen(_onDocChanges);
      oldWidget.controller.removeListener(_onChanges);
      widget.controller.addListener(_onChanges);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  void _checkForMentionTrigger(ParchmentChange change) {
    if (widget.readOnly) return;
    if (change.source == ChangeSource.remote) return;
    final d = change.change;
    if (d.length < 1) return;
    int len = 0;
    for (var i = 0; i < d.length; i++) {
      final o = d[i];
      if (o.isDelete) return;
      if (o.isRetain) {
        len += o.length;
      }
      if (o.isInsert) {
        if (o.isPlain) {
          final t = o.data as String;
          if (widget.options.mentionTriggers.contains(t)) {
            anchor.pos = TextPosition(offset: len + t.length);
            _mentionController.setTrigger(len, t);
          }
        }
        return;
      }
    }
  }

  void _onDocChanges(ParchmentChange change) {
    if (widget.readOnly) return;
    _checkForMentionTrigger(change);
  }

  void _onChanges() {
    if (widget.readOnly) return;
    final state = _mentionController.lastState;
    if (state == null) return;
    final sel = widget.controller.selection;
    if (!sel.isCollapsed) {
      _mentionController.dismiss();
      return;
    }
    if (sel.baseOffset < state.queryPos) {
      _mentionController.dismiss();
      return;
    }
    if (sel.baseOffset > state.queryPos + 20) {
      _mentionController.dismiss();
      return;
    }

    final d = widget.controller.document.toDelta();
    try {
      final v = deltaStringForRange(d, state.queryPos, sel.baseOffset);
      if (v.contains("\n")) {
        // this should not happen (new line are supposedly caught)
        _mentionController.dismiss();
        return;
      }
      _mentionController.setQuery(v);
    } catch (err) {
      // print("ERR: ${err}");
      _mentionController.dismiss();
      return;
    }
  }

  void _handleMentionSuggestionSelected(MentionData data) {
    final state = _mentionController.lastState;
    if (state == null) throw Exception("Invalid state");
    final controller = widget.controller;
    final mentionStartIndex = state.triggerPos;
    final mentionedTextLength = state.trigger.length + state.query.length;

    final object = widget.options.mentionBuilder(
        controller, mentionStartIndex, mentionedTextLength, data);
    if (object != null) {
      var len = 1;
      if (object.data is String) {
        final s = object.data as String;
        len = s.length;
      }
      controller.replaceText(
        mentionStartIndex,
        mentionedTextLength,
        object.data,
        selection: TextSelection.collapsed(offset: mentionStartIndex + len),
      );
      for (var attr in object.attrs) {
        final t = object.data as String;
        controller.formatText(mentionStartIndex, t.length, attr);
      }
    }
  }

  void _onFocusChanged() {
    _hasFocus = widget.focusNode.hasFocus;
    _mentionController.toggle(_hasFocus);
    // _updateOrDisposeOverlayIfNeeded();
  }

  void _onMentionStateChange(MentionState? state) {
    if (state == null) {
      _hideOverlay();
      return;
    }
    _showOverlay();
  }

  void _hideOverlay() {
    if (_overlayEntry == null) return;
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final CapturedThemes themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(
        context,
        rootNavigator: true,
      ).context,
    );
    _overlayEntry = OverlayEntry(
        builder: (context) => themes.wrap(
              MentionOverlay(
                mentionController: _mentionController,
                options: widget.options,
                layerLink: anchor.layerLink,
                suggestionSelected: _mentionController.onValidate,
              ),
            ));
    Overlay.of(context, rootOverlay: true)?.insert(_overlayEntry!);
  }

  // we need to capture the up/down arrow for selection
  // only enabling them when we are active.
  // we cannot use the normal focus actions as the focus should be on the
  // textfield (to let the user continue editing text)
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        key: GlobalKey(),
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.arrowDown):
              const MentionDirectionalFocusIntent(TraversalDirection.down),
          LogicalKeySet(LogicalKeyboardKey.arrowUp):
              const MentionDirectionalFocusIntent(TraversalDirection.up),
          LogicalKeySet(LogicalKeyboardKey.enter): const SelectIntent(),
          LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        },
        child: Actions(actions: <Type, Action<Intent>>{
          MentionDirectionalFocusIntent:
              MentionDirectionalFocusAction(_mentionController),
          SelectIntent: MentionSelectAction(_mentionController),
          DismissIntent: MentionDismissAction(_mentionController),
          // DismissIntent
        }, child: widget.child));
  }
}
