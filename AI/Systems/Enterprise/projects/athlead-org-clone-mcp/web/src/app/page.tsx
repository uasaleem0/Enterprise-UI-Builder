export default function Home() {
  return (
    <main className="min-h-screen bg-white text-slate-900">
      <header className="border-b border-slate-200">
        <div className="mx-auto max-w-7xl px-6 py-3 flex items-center justify-between">
          <div className="text-xl font-semibold">Athlead (Clone)</div>
          <nav className="hidden md:block">
            <ul className="flex gap-6 text-sm">
              <li><a href="#" className="hover:underline">Home</a></li>
              <li><a href="#" className="hover:underline">Team Athlead</a></li>
              <li><a href="#" className="hover:underline">Memberships</a></li>
              <li><a href="#" className="hover:underline">Calories Calculator</a></li>
              <li><a href="#" className="hover:underline">Contact</a></li>
              <li><a href="#" className="hover:underline">Login</a></li>
              <li><a href="#" className="hover:underline">Sign up</a></li>
            </ul>
          </nav>
        </div>
      </header>

      <section className="bg-gradient-to-b from-white to-slate-50">
        <div className="mx-auto max-w-7xl px-6 py-24">
          <h1 className="text-4xl md:text-6xl font-bold leading-[1.2] max-w-3xl">
            We Help you become <span className="text-sky-600">FASTER</span>, <span className="text-sky-600">STRONGER</span>, <span className="text-sky-600">CONFIDENT</span>, and <span className="text-sky-600">INJURY FREE</span>
          </h1>
          <p className="mt-5 text-slate-700 max-w-2xl">
            Online Programs | Football, bodybuilding, bodyweight & more programs. Learn more.
          </p>
          <div className="mt-8 flex items-center gap-6">
            <a
              href="#"
              className="inline-flex items-center gap-2 rounded-md bg-[#1E293B] px-7 py-3 text-white shadow-md hover:bg-[#0F172A] focus:outline-none focus:ring-2 focus:ring-sky-400"
            >
              BOOK NOW a FREE consultation with our Coaches!
              <span aria-hidden>→</span>
            </a>
            <a href="#" className="text-slate-700 hover:underline">View our memberships</a>
          </div>
          <div className="mt-10 h-64 w-full rounded-lg bg-gradient-to-r from-slate-200 to-slate-100" />
        </div>
      </section>

      <footer className="mt-24 border-t border-slate-200">
        <div className="mx-auto max-w-7xl px-6 py-8 text-sm text-slate-500">
          © {new Date().getFullYear()} Athlead (Clone)
        </div>
      </footer>
    </main>
  );
}



