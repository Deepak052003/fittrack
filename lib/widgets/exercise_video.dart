import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'video_embed_stub.dart'
    if (dart.library.js_interop) 'video_embed_web.dart';

/// Our own clip for an exercise, with a thumbnail.
class OwnVideo {
  const OwnVideo(this.poster);

  final ImageProvider? poster;
}

// Looked up once per exercise while the app is open.
final _lookups = <String, Future<OwnVideo?>>{};

/// Finds `web/videos/<id>.mp4`; null means there is no clip yet.
Future<OwnVideo?> findOwnVideo(Exercise e) => _lookups[e.id] ??= () async {
  if (!kIsWeb) return null;
  final (video, jpg) = await (
    hasLocalFile(e.videoFile, 'video/'),
    hasLocalFile(e.posterFile, 'image/'),
  ).wait;
  // Offline or flaky network: forget the result so the next look retries.
  if (video == null || jpg == null) {
    _lookups.remove(e.id);
    return null;
  }
  if (!video) return null;
  if (jpg) return OwnVideo(NetworkImage(e.posterFile));
  // No .jpg yet: grab a frame from the clip (slower).
  final bytes = await videoPoster(e.videoFile);
  return OwnVideo(bytes == null ? null : MemoryImage(bytes));
}();

/// The exercise's short clip, muted and looping (or an icon until one exists).
class ExerciseClip extends StatelessWidget {
  const ExerciseClip({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final group = exercise.group;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            group.color.withValues(alpha: 0.22),
            group.color2.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Icon(group.icon, size: 72, color: group.color),
    );

    // Glass frame: 1px light edge and a soft shadow.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glassEdge(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FutureBuilder<OwnVideo?>(
            future: findOwnVideo(exercise),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ColoredBox(color: Colors.black);
              }
              return snapshot.data == null
                  ? placeholder
                  : ColoredBox(
                      color: Colors.black,
                      child: buildLoopingVideo(exercise.videoFile),
                    );
            },
          ),
        ),
      ),
    );
  }
}
