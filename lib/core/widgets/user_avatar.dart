import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CurrentUserAvatar extends StatelessWidget {
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  const CurrentUserAvatar({
    super.key,
    this.radius = 20,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _buildAvatar(
        radius: radius,
        borderColor: borderColor,
        borderWidth: borderWidth,
        initials: 'U',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final displayName = ((data?['fullName'] as String?) ?? '').trim();
        final fallbackName = displayName.isNotEmpty
            ? displayName
            : ((FirebaseAuth.instance.currentUser?.displayName ?? '').trim().isNotEmpty
                ? (FirebaseAuth.instance.currentUser!.displayName!).trim()
                : uid);

        final imageUrl = _normalizedPhotoUrl(data);

        return _buildAvatar(
          radius: radius,
          borderColor: borderColor,
          borderWidth: borderWidth,
          imageUrl: imageUrl,
          initials: _initialsFromName(fallbackName),
        );
      },
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String uid;
  final double radius;
  final String? fallbackName;

  const UserAvatar({
    super.key,
    required this.uid,
    this.radius = 20,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      final fallback = (fallbackName ?? 'U').trim();
      return _buildAvatar(
        radius: radius,
        initials: _initialsFromName(fallback),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final docName = ((data?['fullName'] as String?) ?? '').trim();
        final resolvedName = (fallbackName ?? '').trim().isNotEmpty
            ? fallbackName!.trim()
            : (docName.isNotEmpty ? docName : uid);

        final imageUrl = _normalizedPhotoUrl(data);

        return _buildAvatar(
          radius: radius,
          imageUrl: imageUrl,
          initials: _initialsFromName(resolvedName),
        );
      },
    );
  }
}

String? _normalizedPhotoUrl(Map<String, dynamic>? data) {
  if (data == null) return null;

  final candidates = [
    data['photoUrl'],
    data['photoURL'],
    data['profilePhotoUrl'],
    data['avatarUrl'],
  ];

  String baseUrl = '';
  for (final value in candidates) {
    if (value is String && value.trim().isNotEmpty) {
      baseUrl = value.trim();
      break;
    }
  }

  if (baseUrl.isEmpty) return null;
  if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
    return null;
  }

  final updatedAt = data['photoUpdatedAt'] ?? data['updatedAt'];
  if (updatedAt is Timestamp) {
    final ts = updatedAt.millisecondsSinceEpoch;
    final sep = baseUrl.contains('?') ? '&' : '?';
    return '$baseUrl${sep}v=$ts';
  }

  return baseUrl;
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

Widget _buildAvatar({
  required double radius,
  String? imageUrl,
  required String initials,
  Color? borderColor,
  double borderWidth = 0,
}) {
  Widget content;
  if (imageUrl != null) {
    content = ClipOval(
      child: Image.network(
        imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsFallback(initials, radius);
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildInitialsFallback(initials, radius);
        },
      ),
    );
  } else {
    content = _buildInitialsFallback(initials, radius);
  }

  Widget avatar = CircleAvatar(
    radius: radius,
    backgroundColor: Colors.grey.shade200,
    child: content,
  );

  if (borderColor != null && borderWidth > 0) {
    avatar = Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderColor,
      ),
      child: avatar,
    );
  }

  return avatar;
}

Widget _buildInitialsFallback(String initials, double radius) {
  return Center(
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w700,
        fontSize: radius * 0.55,
      ),
    ),
  );
}
