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
  return new Promise((resolve) => {
    const proc = spawn(process.platform === 'win32' ? 'npm.cmd' : 'npm', ['i', 'next', 'react', 'react-dom', '--silent', '--no-audit', '--no-fund'], { cwd: projectPath, stdio: 'ignore' });
    let done = false;
    const timeout = setTimeout(() => { if (!done) { try { proc.kill(); } catch {} resolve(false); } }, 180000);
    proc.on('exit', (code) => { done = true; clearTimeout(timeout); resolve(code === 0); });
    proc.on('error', () => { done = true; clearTimeout(timeout); resolve(false); });
  });
}

async function scaffoldNext(projectPath, synthesizedHtml) {
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
}

function startNextDev(projectPath, port) {
  const bin = path.join(projectPath, 'node_modules', '.bin', process.platform === 'win32' ? 'next.cmd' : 'next');
  if (!fs.existsSync(bin)) return null;
  const proc = spawn(bin, ['dev', '-p', String(port)], { cwd: projectPath, stdio: 'ignore' });
  return proc;
}

async function bootstrapNext(projectPath, synthesizedHtml, port) {
  try { await initPackage(projectPath); } catch {}
  try { await scaffoldNext(projectPath, synthesizedHtml); } catch {}
  // Ensure styles and include tokens if present
  try {
    const stylesDir = path.join(projectPath, 'styles');
    await ensureDir(stylesDir);
    const appJs = "import '../styles/globals.css';\nexport default function MyApp({ Component, pageProps }){ return <Component {...pageProps} /> }\n";
    await fsp.writeFile(path.join(projectPath, 'pages', '_app.js'), appJs, 'utf8');
    let globals = ":root{--accent:#1e40af;--page-bg:#ffffff;--font:system-ui,Segoe UI,Roboto,Arial,sans-serif;} body{background:var(--page-bg);font-family:var(--font);}\n";
    try {
      const tokensCssPath = path.join(projectPath, 'tokens', 'tokens.css');
      const tokensCss = await fsp.readFile(tokensCssPath, 'utf8');
      globals = tokensCss + '\n' + globals;
    } catch {}
    await fsp.writeFile(path.join(stylesDir, 'globals.css'), globals, 'utf8');
  } catch {}
  const installed = await installDeps(projectPath);
  if (!installed) return { ok: false, note: 'deps-install-failed' };
  const proc = startNextDev(projectPath, port);
  if (!proc) return { ok: false, note: 'next-binary-missing' };
  return { ok: true, proc };
}

module.exports = { bootstrapNext };
