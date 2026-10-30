import 'dart:convert';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarBase64;
  final String name;
  final double radius;

  const UserAvatar({super.key, this.avatarBase64, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(avatarBase64!));
      } catch (_) {}
    }
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundImage: image,
      child: image == null
          ? Text(initial, style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.bold))
          : null,
    );
  }
}