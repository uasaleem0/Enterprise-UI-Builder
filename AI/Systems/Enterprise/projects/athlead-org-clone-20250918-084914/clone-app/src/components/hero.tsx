'use client';

import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface HeroProps {
  className?: string;
}

export default function Hero({ className }: HeroProps) {
  return (
    <section className={cn("relative bg-gradient-to-br from-blue-50 to-white py-20 lg:py-32", className)}>
      <div className="container mx-auto px-4">
        <div className="max-w-4xl mx-auto text-center">
          {/* Main Headline */}
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 mb-8 leading-tight">
            We Help you become{' '}
            <span className="text-blue-600">FASTER</span>,{' '}
            <span className="text-blue-600">STRONGER</span>,{' '}
            <span className="text-blue-600">CONFIDENT</span>, and{' '}
            <span className="text-blue-600">INJURY FREE</span>
          </h1>

          {/* Tagline */}
          <p className="text-xl md:text-2xl text-gray-600 mb-12 font-medium">
            We coach, We train, We educate.
          </p>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center w-full max-w-4xl">
            <Button
              size="lg"
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-4 md:px-8 md:py-6 text-base md:text-lg font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 w-full sm:w-auto"
            >
              <span className="block sm:hidden">BOOK FREE consultation</span>
              <span className="hidden sm:block">BOOK NOW a FREE consultation with our Coaches!</span>
            </Button>

            <Button
              variant="outline"
              size="lg"
              className="border-2 border-blue-600 text-blue-600 hover:bg-blue-50 px-6 py-4 md:px-8 md:py-6 text-base md:text-lg font-semibold rounded-lg transition-all duration-300 w-full sm:w-auto"
            >
              View our memberships
            </Button>
          </div>
        </div>
      </div>

      {/* Background Pattern */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-10 -right-10 w-80 h-80 bg-blue-100 rounded-full opacity-20"></div>
        <div className="absolute -bottom-10 -left-10 w-96 h-96 bg-blue-50 rounded-full opacity-30"></div>
      </div>
    </section>
  );
}