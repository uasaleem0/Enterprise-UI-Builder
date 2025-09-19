export function Card({ children, className='' }){
  return <div className={`rounded-md border bg-white/60 p-4 ${className}`.trim()}>{children}</div>;
}
export function CardTitle({ children, className='' }){
  return <h3 className={`text-lg font-semibold mb-1 ${className}`.trim()}>{children}</h3>;
}
export function CardContent({ children, className='' }){
  return <div className={className}>{children}</div>;
}

