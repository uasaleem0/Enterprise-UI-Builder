#!/usr/bin/env node

/**
 * Next.js Multi-Page Synthesis
 * - Creates minimal Next.js app with a shared layout and page files for crawled URLs
 * - Uses simple CSS variables for theme (extracted accent/background)
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

async function ensureDir(p) { await fsp.mkdir(p, { recursive: true }); }

function pathToFile(routePath) {
  // Map '/about' -> 'about.js', '/docs/getting-started' -> 'docs/getting-started.js'
  const clean = routePath.replace(/^\//,'').replace(/\/$/,'');
  return clean.length ? clean + '.js' : 'index.js';
}

function layoutJs(theme, nav) {
  return `import Link from 'next/link';
export default function Layout({ children }){
  return (
    <div style={{fontFamily:'system-ui,Segoe UI,Roboto,Arial,sans-serif',background:'${theme.pageBg}',minHeight:'100vh'}}>
      <div style={{maxWidth:1080,margin:'0 auto',padding:'1.5rem'}}>
        <header style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'1rem 0'}}>
          <div style={{fontWeight:700}}>Enterprise Candidate</div>
          <nav>
            {${JSON.stringify(nav)}.slice(0,6).map((t,i)=> (
              <Link key={i} href="#" style={{marginRight:'1rem',color:'${theme.accent}',textDecoration:'none'}}>{t}</Link>
            ))}
          </nav>
        </header>
        <main>{children}</main>
        <footer style={{padding:'2rem 0',color:'#555'}}>Enterprise System · Candidate</footer>
      </div>
    </div>
  );
}`;
}

function pageJs(title, ctas) {
  return `import Layout from '../_layout';
export default function Page(){
  return (
    <Layout>
      <section style={{padding:'3rem 0',background:'rgba(0,0,0,0.02)',borderRadius:8}}>
        <h1 style={{fontSize:'2.25rem',margin:'0 0 .5rem 0'}}>${title || 'Welcome'}</h1>
        <p>Generated from extraction artifacts. Accent color and font applied.</p>
        {( ${JSON.stringify(ctas)} || []).slice(0,2).map((t,i)=>(<a key={i} href="#" style={{display:'inline-block',marginRight:12,marginTop:12,background:'var(--accent)',' + "color:'white',padding:'0.6rem 1rem',borderRadius:6,textDecoration:'none'}}>{t}</a>))}
      </section>
    </Layout>
  );
}`;
}

async function synthesizeNext(projectPath, site, struct, theme) {
  const pagesDir = path.join(projectPath, 'pages');
  await ensureDir(pagesDir);
  // Write shared layout
  await fsp.writeFile(path.join(pagesDir, '_layout.js'), layoutJs(theme, struct?.nav || []), 'utf8');
  // Write simple components (Header/Hero/CardGrid/Footer) using Tailwind
  const compDir = path.join(projectPath, 'components');
  await ensureDir(compDir);
  await fsp.writeFile(path.join(compDir, 'Header.js'), "export default function Header({title='Enterprise Candidate'}){ return (<header className='flex items-center justify-between py-4'><div className='font-bold'>{title}</div></header>); }\n", 'utf8');
  await fsp.writeFile(path.join(compDir, 'Hero.js'), "import Button from '../components/ui/button'; export default function Hero({heading='Welcome', ctas=[]}){ return (<section className='rounded-md bg-[rgba(0,0,0,0.02)]' style={{paddingTop:'var(--pad-hero,3rem)', paddingBottom:'var(--pad-hero,3rem)'}}><h1 className='text-3xl mb-2'>{heading}</h1><p>Generated from extraction artifacts. Accent color and font applied.</p><div className='mt-3 space-x-3'>{ctas.slice(0,2).map((t,i)=>(<Button key={i} href='#'>{t}</Button>))}</div></section>); }\n", 'utf8');
  await fsp.writeFile(path.join(compDir, 'CardGrid.js'), "export default function CardGrid({items=[]}){ return (<div className='grid grid-cols-1 md:grid-cols-3 gap-4 my-6'>{items.slice(0,6).map((t,i)=>(<div key={i} className='p-4 border rounded-md bg-white/60'>{t}</div>))}</div>); }\n", 'utf8');
  await fsp.writeFile(path.join(compDir, 'Footer.js'), "export default function Footer(){ return (<footer className='py-6 text-gray-600'>Enterprise System · Candidate</footer>); }\n", 'utf8');
  // Write pages from site map
  const list = site.pages && site.pages.length ? site.pages : [{ url: 'http://localhost:3000/', title: struct?.headings?.[0] || 'Home' }];
  for (const p of list) {
    try {
      const file = pathToFile(new URL(p.url).pathname);
      const out = path.join(pagesDir, file);
      await ensureDir(path.dirname(out));
      await fsp.writeFile(out, pageJs(p.title || struct?.headings?.[0] || 'Welcome', struct?.ctas || []), 'utf8');
    } catch {}
  }
  return { ok: true, pagesDir };
}

module.exports = { synthesizeNext };
