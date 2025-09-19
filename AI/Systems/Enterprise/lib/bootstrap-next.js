#!/usr/bin/env node

/**
 * Next.js Bootstrap (optional)
 * - Creates a minimal Next.js app with a homepage generated from synthesis.
 * - Attempts to install next/react/react-dom; falls back silently if install fails.
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const { spawn } = require('child_process');

async function ensureDir(p) { await fsp.mkdir(p, { recursive: true }); }

async function writeIfMissing(p, content) {
  if (!fs.existsSync(p)) await fsp.writeFile(p, content, 'utf8');
}

async function initPackage(projectPath) {
  const pkgPath = path.join(projectPath, 'package.json');
  let pkg = { name: path.basename(projectPath), private: true, version: '0.0.1', scripts: { dev: 'next dev', build: 'next build', start: 'next start' } };
  if (fs.existsSync(pkgPath)) {
    try { pkg = JSON.parse(await fsp.readFile(pkgPath, 'utf8')); } catch {}
    pkg.scripts = Object.assign({}, pkg.scripts, { dev: 'next dev', build: 'next build', start: 'next start' });
  }
  await fsp.writeFile(pkgPath, JSON.stringify(pkg, null, 2), 'utf8');
}

async function installDeps(projectPath) {
  const run = (args, ms=180000) => new Promise((resolve) => {
    const proc = spawn(process.platform === 'win32' ? 'npm.cmd' : 'npm', args, { cwd: projectPath, stdio: 'ignore' });
    let done = false; const timeout = setTimeout(() => { if (!done) { try { proc.kill(); } catch {} resolve(false); } }, ms);
    proc.on('exit', (code) => { done = true; clearTimeout(timeout); resolve(code === 0); });
    proc.on('error', () => { done = true; clearTimeout(timeout); resolve(false); });
  });
  const ok1 = await run(['i', 'next', 'react', 'react-dom', '--silent', '--no-audit', '--no-fund']);
  const ok2 = await run(['i', '-D', 'tailwindcss', 'postcss', 'autoprefixer', '--silent', '--no-audit', '--no-fund']);
  return ok1 && ok2;
}

async function scaffoldNext(projectPath, synthesizedHtml, options = {}) {
  await ensureDir(path.join(projectPath, 'pages'));
  await ensureDir(path.join(projectPath, 'public'));
  // Create a simple index page embedding synthesized content inside a React wrapper
  const reactIndex = `export default function Home(){return (
    <main style={{fontFamily:'system-ui,Segoe UI,Roboto,Arial,sans-serif',padding:'1.5rem'}}>
      <div dangerouslySetInnerHTML={{__html: ${JSON.stringify(synthesizedHtml)}}} />
    </main>
  );}`;
  await fsp.writeFile(path.join(projectPath, 'pages', 'index.js'), reactIndex, 'utf8');
  await writeIfMissing(path.join(projectPath, 'next.config.js'), 'module.exports = { reactStrictMode: true };\n');
  // Optional minimal auth scaffold for new apps
  if (options.auth === true) {
    const apiLogin = `export default function handler(req,res){ if(req.method!=='POST'){return res.status(405).end();} const {username,password}=req.body||{}; if(username && password){ res.setHeader('Set-Cookie','ent_auth=1; Path=/; HttpOnly; SameSite=Lax'); return res.status(200).json({ok:true}); } return res.status(401).json({ok:false}); }`;
    const apiLogout = `export default function handler(req,res){ res.setHeader('Set-Cookie','ent_auth=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT'); return res.status(200).json({ok:true}); }`;
    const loginPage = `import { useState } from 'react'; export default function Login(){ const [u,setU]=useState(''); const [p,setP]=useState(''); async function onSubmit(e){ e.preventDefault(); await fetch('/api/login',{method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({username:u,password:p})}); location.href='/protected'; } return (<main className='p-6 max-w-md mx-auto'><h1 className='text-2xl mb-4'>Login</h1><form onSubmit={onSubmit} className='space-y-3'><input className='border p-2 w-full' placeholder='Username' value={u} onChange={e=>setU(e.target.value)} /><input className='border p-2 w-full' type='password' placeholder='Password' value={p} onChange={e=>setP(e.target.value)} /><button className='px-4 py-2 text-white rounded' style={{background:'var(--accent)'}}>Sign In</button></form></main>); }`;
    const protectedPage = `export default function Protected(){ return (<main className='p-6 max-w-2xl mx-auto'><h1 className='text-2xl mb-4'>Protected</h1><p>This page requires a session.</p><a className='inline-block mt-4 px-4 py-2 text-white rounded' style={{background:'var(--accent)'}} href='/api/logout'>Logout</a></main>); }`;
    const middleware = `import { NextResponse } from 'next/server'; export function middleware(req){ const url=req.nextUrl; if(url.pathname.startsWith('/protected')){ const cookie = req.cookies.get('ent_auth'); if(!cookie){ const loginUrl = new URL('/login', req.url); return NextResponse.redirect(loginUrl); } } return NextResponse.next(); }`;
    await ensureDir(path.join(projectPath,'pages','api'));
    await fsp.writeFile(path.join(projectPath,'pages','api','login.js'), apiLogin, 'utf8');
    await fsp.writeFile(path.join(projectPath,'pages','api','logout.js'), apiLogout, 'utf8');
    await fsp.writeFile(path.join(projectPath,'pages','login.js'), loginPage, 'utf8');
    await fsp.writeFile(path.join(projectPath,'pages','protected.js'), protectedPage, 'utf8');
    await fsp.writeFile(path.join(projectPath,'middleware.js'), middleware, 'utf8');
  }
}

function startNextDev(projectPath, port) {
  const bin = path.join(projectPath, 'node_modules', '.bin', process.platform === 'win32' ? 'next.cmd' : 'next');
  if (!fs.existsSync(bin)) return null;
  const proc = spawn(bin, ['dev', '-p', String(port)], { cwd: projectPath, stdio: 'ignore' });
  return proc;
}

async function bootstrapNext(projectPath, synthesizedHtml, port, options = {}) {
  try { await initPackage(projectPath); } catch {}
  try { await scaffoldNext(projectPath, synthesizedHtml, options); } catch {}
  // Ensure styles and include tokens if present
  try {
    const stylesDir = path.join(projectPath, 'styles');
    await ensureDir(stylesDir);
    const appJs = "import '../styles/globals.css';\nexport default function MyApp({ Component, pageProps }){ return <Component {...pageProps} /> }\n";
    await fsp.writeFile(path.join(projectPath, 'pages', '_app.js'), appJs, 'utf8');
    // Tailwind + tokens
    await fsp.writeFile(path.join(projectPath, 'tailwind.config.js'), "module.exports = { content: ['./pages/**/*.{js,jsx,ts,tsx}','./components/**/*.{js,jsx,ts,tsx}'], theme: { extend: {} }, plugins: [] };\n", 'utf8');
    await fsp.writeFile(path.join(projectPath, 'postcss.config.js'), "module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } };\n", 'utf8');
    let globals = "@tailwind base;\n@tailwind components;\n@tailwind utilities;\n\n:root{--accent:#1e40af;--page-bg:#ffffff;--font:system-ui,Segoe UI,Roboto,Arial,sans-serif;}\nbody{background:var(--page-bg);font-family:var(--font);}\n";
    try {
      const tokensCssPath = path.join(projectPath, 'tokens', 'tokens.css');
      const tokensCss = await fsp.readFile(tokensCssPath, 'utf8');
      globals = tokensCss + '\n' + globals;
    } catch {}
    await fsp.writeFile(path.join(stylesDir, 'globals.css'), globals, 'utf8');
  } catch {}
  // Attempt to generate Tailwind theme from tokens
  try { const { writeTailwindConfig } = require('./tailwind-theme'); await writeTailwindConfig(projectPath); } catch {}
  const installed = await installDeps(projectPath);
  if (!installed) return { ok: false, note: 'deps-install-failed' };
  const proc = startNextDev(projectPath, port);
  if (!proc) return { ok: false, note: 'next-binary-missing' };
  return { ok: true, proc };
}

module.exports = { bootstrapNext };
