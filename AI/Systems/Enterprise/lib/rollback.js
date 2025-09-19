#!/usr/bin/env node

/**
 * Deploy Rollback (best-effort)
 * - Attempts `npx vercel rollback` in the project directory
 */

const { spawn } = require('child_process');

function run(cmd, args, cwd, ms = 120000) {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args, { cwd, shell: process.platform === 'win32' });
    let done = false; let out='';
    const t = setTimeout(()=>{ if(!done){ try{ proc.kill(); } catch{} resolve({ok:false,out}); } }, ms);
    proc.stdout.on('data', d => out += d.toString());
    proc.stderr.on('data', d => out += d.toString());
    proc.on('exit', code => { done=true; clearTimeout(t); resolve({ok: code===0, out}); });
    proc.on('error', ()=>{ done=true; clearTimeout(t); resolve({ok:false,out}); });
  });
}

async function rollbackVercel(projectPath) {
  return await run('npx', ['vercel', 'rollback', '--yes'], projectPath, 180000);
}

module.exports = { rollbackVercel };

