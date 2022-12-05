import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import 'const.dart';
import 'options.dart';

EmbeddableObject buildEmbeddableObject(MentionData data) =>
    EmbeddableObject(mentionEmbedKey, inline: true, data: data.toJson());
