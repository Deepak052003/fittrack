import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

/// True if [url] exists with a content type starting with [type]
/// (missing files return the app page instead); null if the network failed.
Future<bool?> hasLocalFile(String url, String type) async {
  final abort = web.AbortController();
  try {
    final res = await web.window
        .fetch(
          url.toJS,
          web.RequestInit(
            headers: web.Headers()..append('Range', 'bytes=0-0'),
            signal: abort.signal,
          ),
        )
        .toDart;
    return res.ok && (res.headers.get('content-type') ?? '').startsWith(type);
  } catch (_) {
    return null;
  } finally {
    abort.abort(); // Only the headers are needed.
  }
}

/// A JPEG frame from the video, used as its thumbnail.
Future<Uint8List?> videoPoster(String url) async {
  final video = web.HTMLVideoElement()
    ..muted = true
    ..playsInline = true
    ..preload = 'auto'
    ..src = url;
  try {
    await _loaded(video.onLoadedData.first, video);
    final duration = video.duration;
    video.currentTime = duration.isFinite ? min(1.0, duration / 4) : 0;
    await _loaded(video.onSeeked.first, video);
    final w = video.videoWidth, h = video.videoHeight;
    if (w == 0 || h == 0) return null;
    final scale = min(1.0, 640 / w);
    final canvas = web.HTMLCanvasElement()
      ..width = (w * scale).round()
      ..height = (h * scale).round();
    canvas.context2D.drawImage(video, 0, 0, canvas.width, canvas.height);
    return UriData.parse(canvas.toDataURL('image/jpeg', 0.8.toJS))
        .contentAsBytes();
  } catch (_) {
    return null;
  } finally {
    video
      ..removeAttribute('src')
      ..load();
  }
}

/// Waits for [event], failing on a video error or after 10 s.
Future<void> _loaded(Future<web.Event> event, web.HTMLVideoElement video) =>
    Future.any([
      event,
      video.onError.first.then((_) => throw StateError('video error')),
    ]).timeout(const Duration(seconds: 10));

/// Muted looping clip; taps pass through to the app.
Widget buildLoopingVideo(String url) {
  final viewType = 'loop-$url';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final video = web.HTMLVideoElement();
      video.onLoadedData.first.then((_) => _matchBackground(video));
      return video
        ..src = url
        ..muted = true
        ..autoplay = true
        ..loop = true
        ..playsInline = true
        ..setAttribute('muted', '')
        ..setAttribute('playsinline', '')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.pointerEvents = 'none'
        ..style.backgroundColor = 'black';
    });
  }
  return HtmlElementView(viewType: viewType);
}

/// Fills the bars around a non-16:9 clip with its corner color (e.g. white).
void _matchBackground(web.HTMLVideoElement video) {
  try {
    final ctx =
        (web.HTMLCanvasElement()
              ..width = 1
              ..height = 1)
            .context2D
          ..drawImage(video, 0, 0, 4, 4, 0, 0, 1, 1);
    final p = ctx.getImageData(0, 0, 1, 1).data.toDart;
    video.style.backgroundColor = 'rgb(${p[0]}, ${p[1]}, ${p[2]})';
  } catch (_) {}
}
