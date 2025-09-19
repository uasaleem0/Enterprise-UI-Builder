#!/usr/bin/env node

/**
 * Vercel Deploy (best-effort)
 * - Tries to run `npx vercel` and returns URL if detected in output
 */

const { spawn } = require('child_process');

function run(cmd, args, cwd, ms = 180000) {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args, { cwd, shell: process.platform === 'win32' });
    let done = false; let out = '';
    const timeout = setTimeout(() => { if (!done) { try { proc.kill(); } catch {} resolve({ ok:false, out }); } }, ms);
    proc.stdout.on('data', d => { out += d.toString(); });
    proc.stderr.on('data', d => { out += d.toString(); });
    proc.on('exit', (code) => { done = true; clearTimeout(timeout); resolve({ ok: code === 0, out }); });
    proc.on('error', () => { done = true; clearTimeout(timeout); resolve({ ok:false, out }); });
  });
}

async function deployVercel(projectPath, prod = false) {
  // Attempt preview deploy first
  const args = prod ? ['--yes', '--prod'] : ['--yes'];
  const res = await run('npx', ['vercel', ...args], projectPath, 240000);
  if (!res.ok) return { ok:false, note:'vercel-failed' };
  const m = res.out.match(/(https?:\/\/[^\s]+\.vercel\.app)/i);
  return { ok:true, url: m ? m[1] : null, raw: res.out };
}

module.exports = { deployVercel };

