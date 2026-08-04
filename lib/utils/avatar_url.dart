import 'package:flutter/material.dart';
import 'package:poolqapp/utils/gravatar.dart';

export 'package:poolqapp/utils/gravatar.dart' show gravatarUrl;

/// Prefer uploaded/Firebase photo, then Gravatar from email, then local asset.
ImageProvider resolveAvatarImage({
  String? photoUrl,
  String? email,
  String assetFallback = 'assets/images/user.png',
  int size = 200,
}) {
  final uploaded = photoUrl?.trim() ?? '';
  if (uploaded.isNotEmpty) {
    return NetworkImage(uploaded);
  }
  final gravatar = gravatarUrl(email, size: size);
  if (gravatar != null) {
    return NetworkImage(gravatar);
  }
  return AssetImage(assetFallback);
}
