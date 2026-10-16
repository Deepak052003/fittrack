// Serves the app's files. Adds byte-range replies for /videos/* because
// Safari (iPhone) only plays videos when the server supports them.
export default {
  async fetch(request, env) {
    const response = await env.ASSETS.fetch(request);
    const match = /^bytes=(\d*)-(\d*)$/.exec(request.headers.get('Range')?.trim() ?? '');
    if (!match || response.status !== 200 || (match[1] === '' && match[2] === '')) return response;

    const body = await response.arrayBuffer();
    const size = body.byteLength;
    const start = match[1] === '' ? Math.max(0, size - Number(match[2])) : Number(match[1]);
    const end = match[1] === '' || match[2] === '' ? size - 1 : Math.min(Number(match[2]), size - 1);
    if (start > end) {
      return new Response(null, { status: 416, headers: { 'Content-Range': `bytes */${size}` } });
    }
    const headers = new Headers(response.headers);
    headers.set('Accept-Ranges', 'bytes');
    headers.set('Content-Range', `bytes ${start}-${end}/${size}`);
    headers.set('Content-Length', String(end - start + 1));
    return new Response(body.slice(start, end + 1), { status: 206, headers });
  },
};
