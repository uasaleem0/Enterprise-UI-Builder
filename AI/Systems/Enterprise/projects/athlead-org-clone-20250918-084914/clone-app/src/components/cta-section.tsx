'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { cn } from '@/lib/utils';

interface CtaSectionProps {
  className?: string;
}

export default function CtaSection({ className }: CtaSectionProps) {
  return (
    <section className={cn("py-20 bg-blue-50", className)}>
      <div className="container mx-auto px-4">
        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Free Consultation CTA */}
            <Card className="group hover:shadow-2xl transition-all duration-300 border-2 border-blue-100 hover:border-blue-300 bg-white">
              <CardHeader className="text-center pb-4">
                <div className="w-20 h-20 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:bg-blue-200 transition-colors duration-300">
                  <svg className="w-10 h-10 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                  </svg>
                </div>
                <CardTitle className="text-2xl md:text-3xl font-bold text-gray-900 mb-4">
                  FREE Consultation
                </CardTitle>
                <CardDescription className="text-lg text-gray-600 leading-relaxed">
                  Book a personalized consultation with our expert coaches to discuss your fitness goals and create a customized training plan.
                </CardDescription>
              </CardHeader>
              <CardContent className="text-center">
                <Button
                  size="lg"
                  className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-4 text-lg font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 w-full group-hover:scale-105"
                >
                  BOOK NOW a FREE consultation
                </Button>
                <p className="text-sm text-gray-500 mt-4">
                  ✓ No commitment required ✓ Expert guidance ✓ Personalized approach
                </p>
              </CardContent>
            </Card>

            {/* Memberships CTA */}
            <Card className="group hover:shadow-2xl transition-all duration-300 border-2 border-blue-100 hover:border-blue-300 bg-white">
              <CardHeader className="text-center pb-4">
                <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:bg-green-200 transition-colors duration-300">
                  <svg className="w-10 h-10 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                  </svg>
                </div>
                <CardTitle className="text-2xl md:text-3xl font-bold text-gray-900 mb-4">
                  Premium Memberships
                </CardTitle>
                <CardDescription className="text-lg text-gray-600 leading-relaxed">
                  Choose from our comprehensive membership plans designed to help you achieve your athletic goals with ongoing support.
                </CardDescription>
              </CardHeader>
              <CardContent className="text-center">
                <Button
                  variant="outline"
                  size="lg"
                  className="border-2 border-green-600 text-green-600 hover:bg-green-50 px-8 py-4 text-lg font-semibold rounded-lg transition-all duration-300 w-full group-hover:scale-105"
                >
                  View our memberships
                </Button>
                <p className="text-sm text-gray-500 mt-4">
                  ✓ Flexible plans ✓ Expert coaching ✓ 24/7 support
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Statistics or Trust Indicators */}
          <div className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            <div className="space-y-2">
              <div className="text-3xl md:text-4xl font-bold text-blue-600">500+</div>
              <div className="text-gray-600 font-medium">Athletes Trained</div>
            </div>
            <div className="space-y-2">
              <div className="text-3xl md:text-4xl font-bold text-blue-600">95%</div>
              <div className="text-gray-600 font-medium">Success Rate</div>
            </div>
            <div className="space-y-2">
              <div className="text-3xl md:text-4xl font-bold text-blue-600">24/7</div>
              <div className="text-gray-600 font-medium">Support Available</div>
            </div>
            <div className="space-y-2">
              <div className="text-3xl md:text-4xl font-bold text-blue-600">10+</div>
              <div className="text-gray-600 font-medium">Sports Covered</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}