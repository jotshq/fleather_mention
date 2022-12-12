import 'package:fleather_mention/src/controller.dart';
import 'package:flutter/material.dart';

class MentionDirectionalFocusIntent extends Intent {
  const MentionDirectionalFocusIntent(this.direction);
  final TraversalDirection direction;
}

abstract class MentionAction<T extends Intent> extends Action<T> {
  final MentionController _mentionController;

  MentionAction(this._mentionController);

  @override
  bool get isActionEnabled {
    if (_mentionController.lastState != null) {
      return true;
    }
    return false;
  }

  @override
  bool consumesKey(T intent) {
    return true;
  }
}

class MentionSelectAction extends MentionAction<SelectIntent> {
  MentionSelectAction(super.mo);

  @override
  void invoke(covariant SelectIntent intent) {
    _mentionController.validate();
  }
}

class MentionDismissAction extends MentionAction<DismissIntent> {
  MentionDismissAction(super.mo);

  @override
  void invoke(covariant DismissIntent intent) {
    _mentionController.dismiss();
  }
}

class MentionDirectionalFocusAction
    extends MentionAction<MentionDirectionalFocusIntent> {
  MentionDirectionalFocusAction(super.mo);

  @override
  void invoke(covariant MentionDirectionalFocusIntent intent) {
    if (intent.direction == TraversalDirection.up) {
      _mentionController.select(-1);
    }
    if (intent.direction == TraversalDirection.down) {
      _mentionController.select(1);
    }
  }
}
