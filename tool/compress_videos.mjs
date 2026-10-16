// Shrinks new clips in web/videos/ to HD (max 1280x720, 30 fps, 15 s, no audio)
// and writes a <name>.jpg thumbnail next to each. Clips that already have an
// up-to-date thumbnail are skipped.
import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, renameSync, rmSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import ffmpeg from 'ffmpeg-static';

const videos = fileURLToPath(new URL('../web/videos', import.meta.url));

const run = (args) => spawnSync(ffmpeg, ['-y', '-loglevel', 'error', ...args], { stdio: 'inherit' }).status === 0;
const mb = (bytes) => (bytes / 1048576).toFixed(1) + ' MB';

for (const name of readdirSync(videos).filter((f) => f.endsWith('.mp4'))) {
  const video = join(videos, name);
  const poster = video.replace(/\.mp4$/, '.jpg');
  if (existsSync(poster) && statSync(poster).mtimeMs >= statSync(video).mtimeMs) continue;

  const before = statSync(video).size;
  const tmp = video + '.tmp.mp4';
  const ok = run([
    '-i', video, '-t', '15', '-an',
    '-vf', "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2",
    '-fpsmax', '30', '-c:v', 'libx264', '-preset', 'slow', '-crf', '26',
    '-pix_fmt', 'yuv420p', '-movflags', '+faststart', tmp,
  ]);
  if (!ok) { rmSync(tmp, { force: true }); console.error(`FAILED ${name}`); continue; }
  // Keep the clip as it was if it is already smaller.
  if (statSync(tmp).size < before) renameSync(tmp, video);
  else rmSync(tmp);

  // Thumbnail from ~1 s in (or the first frame for very short clips).
  for (const at of ['1', '0']) {
    if (run(['-ss', at, '-i', video, '-frames:v', '1', '-vf', 'scale=480:-2', '-q:v', '4', poster]) && existsSync(poster)) break;
  }
  console.log(`${name}: ${mb(before)} -> ${mb(statSync(video).size)}`);
}
