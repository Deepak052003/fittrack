// Release build + sw.js. `--skip-flutter` only regenerates sw.js.
// Set FLUTTER=<path> to use a different Flutter SDK.
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const out = join(root, 'build', 'web');

// Files the service worker does not precache.
const NOT_PRECACHED = [
  /^canvaskit\//,
  /^videos\//,
  /\.map$/,
  /^index\.html$/, // precached as "./"
  /^sw\.js$/,
  /^flutter\.js$/,
  /^flutter_service_worker\.js$/,
  /^assets\/NOTICES$/,
  /^_headers$/,
  /^_redirects$/,
];

// Prefers the project's SDK (C:\flutter, as in .vscode/settings.json) over PATH.
function findFlutter() {
  if (process.env.FLUTTER) return process.env.FLUTTER;
  const local = 'C:\\flutter\\bin\\flutter.bat';
  if (process.platform === 'win32' && existsSync(local)) return local;
  const which = process.platform === 'win32' ? 'where' : 'which';
  if (spawnSync(which, ['flutter']).status === 0) return 'flutter';
  throw new Error('Flutter not found. Add it to PATH or set the FLUTTER env var.');
}

function listFiles(dir) {
  return readdirSync(dir, { recursive: true, withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => relative(dir, join(entry.parentPath, entry.name)).split(sep).join('/'))
    .filter((path) => !path.split('/').some((part) => part.startsWith('.')))
    .sort();
}

if (!process.argv.includes('--skip-flutter')) {
  const command = `"${findFlutter()}" build web --release --no-web-resources-cdn`;
  console.log(`> ${command}`);
  const result = spawnSync(command, { cwd: root, stdio: 'inherit', shell: true });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

const files = listFiles(out).filter((path) => path !== 'sw.js');

// Content hash: a new deploy changes sw.js, so browsers update.
const hash = createHash('sha256');
for (const path of files) {
  hash.update(path);
  hash.update(readFileSync(join(out, path)));
}
const version = hash.digest('hex').slice(0, 16);

const bootstrap = readFileSync(join(out, 'flutter_bootstrap.js'), 'utf8');
const engine = /"engineRevision"\s*:\s*"([0-9a-f]+)"/.exec(bootstrap)?.[1];
if (!engine) throw new Error('engineRevision not found in flutter_bootstrap.js');

const precache = ['./', ...files.filter((path) => !NOT_PRECACHED.some((re) => re.test(path)))];

const worker = readFileSync(join(root, 'pwa', 'sw.template.js'), 'utf8')
  .replace('%%VERSION%%', version)
  .replace('%%ENGINE%%', engine)
  .replace('%%PRECACHE%%', JSON.stringify(precache, null, 2));
writeFileSync(join(out, 'sw.js'), worker);

// Not uploaded to Cloudflare.
writeFileSync(join(out, '.assetsignore'), ['*.symbols', '*.map', '.last_build_id', ''].join('\n'));

console.log(`\nsw.js generated: version ${version}, engine ${engine.slice(0, 10)}, ${precache.length} precached files.`);
console.log(`Output: ${out}`);
