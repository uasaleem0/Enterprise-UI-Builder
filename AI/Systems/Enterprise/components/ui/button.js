export default function Button({ as: As='a', href='#', children, className='', style={} }){
  const cls = `inline-flex items-center justify-center rounded-md px-4 py-2 text-white shadow-sm ${className}`.trim();
  return <As href={href} className={cls} style={{ background:'var(--accent)', ...style }}>{children}</As>;
}

