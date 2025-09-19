'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { cn } from '@/lib/utils';

interface ProgramsProps {
  className?: string;
}

export default function Programs({ className }: ProgramsProps) {
  const programs = [
    {
      title: 'Online Programs',
      description: 'Football, bodybuilding, bodyweight & more programs',
      icon: '🏈',
      features: ['Specialized Training', 'Sport-Specific Programs', 'Performance Tracking']
    },
    {
      title: 'Online Coaching',
      description: '24/7 Dedicated Coach, Specialized Program & Nutrition',
      icon: '💪',
      features: ['Personal Coach', 'Custom Nutrition Plans', '24/7 Support']
    },
    {
      title: 'Team Training',
      description: 'Professional team coaching and development programs',
      icon: '👥',
      features: ['Team Coordination', 'Group Sessions', 'Leadership Development']
    },
    {
      title: 'Injury Prevention',
      description: 'Comprehensive injury prevention and recovery programs',
      icon: '🏥',
      features: ['Recovery Plans', 'Preventive Training', 'Medical Support']
    }
  ];

  return (
    <section className={cn("py-20 bg-white", className)}>
      <div className="container mx-auto px-4">
        <div className="max-w-6xl mx-auto">
          {/* Section Header */}
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Our Training Programs
            </h2>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Comprehensive athletic development programs designed to help you reach your peak performance
            </p>
          </div>

          {/* Programs Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {programs.map((program, index) => (
              <Card
                key={index}
                className="group hover:shadow-xl transition-all duration-300 border-gray-200 hover:border-blue-300"
              >
                <CardHeader className="text-center pb-4">
                  <div className="text-4xl mb-4 group-hover:scale-110 transition-transform duration-300">
                    {program.icon}
                  </div>
                  <CardTitle className="text-xl font-semibold text-gray-900 mb-2">
                    {program.title}
                  </CardTitle>
                  <CardDescription className="text-gray-600">
                    {program.description}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-2">
                    {program.features.map((feature, featureIndex) => (
                      <li key={featureIndex} className="flex items-center text-sm text-gray-700">
                        <svg className="w-4 h-4 text-blue-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                        {feature}
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Sport Specific Programs */}
          <div className="mt-20">
            <h3 className="text-2xl font-bold text-center text-gray-900 mb-12">
              Sport-Specific Training Programs
            </h3>
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-8 items-center justify-items-center">
              {['Football', 'Basketball', 'Soccer', 'Tennis', 'Swimming', 'Running', 'Boxing', 'Cycling', 'Volleyball', 'Baseball', 'Golf', 'Wrestling'].map((sport, index) => (
                <div
                  key={index}
                  className="flex flex-col items-center p-4 hover:bg-blue-50 rounded-lg transition-colors duration-300 cursor-pointer"
                >
                  <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-3 group-hover:bg-blue-200 transition-colors duration-300">
                    <span className="text-2xl">⚽</span>
                  </div>
                  <span className="text-sm font-medium text-gray-700 text-center">{sport}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}