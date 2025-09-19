import Header from '@/components/header';
import Hero from '@/components/hero';
import Programs from '@/components/programs';
import CtaSection from '@/components/cta-section';
import Footer from '@/components/footer';

export default function Home() {
  return (
    <div className="min-h-screen">
      <Header />
      <main>
        <Hero />
        <Programs />
        <CtaSection />
      </main>
      <Footer />
    </div>
  );
}
