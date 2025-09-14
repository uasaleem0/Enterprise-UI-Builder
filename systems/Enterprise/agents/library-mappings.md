# JavaScript Library Mappings for Website Cloning

## Enterprise Implementation Stack
- **Framework**: Next.js 14+ with TypeScript
- **Styling**: Tailwind CSS + Shadcn/ui components
- **Animation**: Framer Motion + CSS transforms
- **Validation**: React Hook Form + Zod schemas

## Common Website Functionality → Enterprise Implementation

### **SMOOTH SCROLLING & NAVIGATION**
- **jQuery smooth scroll** → `scroll-behavior: smooth` + `scrollIntoView()`
- **AOS (Animate On Scroll)** → Framer Motion `useInView` hook
- **Locomotive Scroll** → Custom smooth scroll with `transform: translateY()`
- **Fullpage.js** → Next.js routing + Framer Motion page transitions
- **Waypoints** → Intersection Observer API
- **ScrollMagic** → Framer Motion scroll-triggered animations

### **ANIMATIONS & TRANSITIONS**
- **GSAP** → Framer Motion equivalents
- **Anime.js** → Framer Motion + CSS transforms
- **Lottie** → `@lottiefiles/react-lottie-player`
- **CSS animations** → Tailwind animation classes
- **Velocity.js** → Framer Motion physics-based animations
- **Barba.js** → Next.js page transitions + Framer Motion

### **UI COMPONENTS**
- **Bootstrap** → Shadcn/ui components
- **Material-UI** → Shadcn/ui + custom styling
- **Semantic UI** → Shadcn/ui equivalents
- **Foundation** → Tailwind CSS utility classes
- **Bulma** → Tailwind CSS grid/flexbox
- **Ant Design** → Shadcn/ui + custom components

### **FORMS & VALIDATION**
- **jQuery Validation** → React Hook Form + Zod
- **Formik** → React Hook Form (preferred)
- **Yup validation** → Zod schemas
- **Parsley.js** → React Hook Form built-in validation
- **Joi validation** → Zod schemas
- **Cleave.js** → React input formatting hooks

### **SLIDERS & CAROUSELS**
- **Swiper.js** → `embla-carousel-react` or custom with Framer Motion
- **Slick Carousel** → `embla-carousel-react`
- **Owl Carousel** → Custom carousel with Framer Motion
- **Glide.js** → `embla-carousel-react`
- **Flickity** → Custom draggable carousel
- **Splide** → `embla-carousel-react`

### **MODALS & OVERLAYS**
- **Bootstrap Modal** → Shadcn/ui Dialog component
- **Fancybox** → Shadcn/ui Dialog + image viewer
- **Lightbox2** → Custom lightbox with Framer Motion
- **Magnific Popup** → Shadcn/ui Dialog variants
- **Sweet Alert** → Shadcn/ui Toast/Alert components
- **Toastr** → Shadcn/ui Toast component

### **DATE & TIME**
- **jQuery Datepicker** → Shadcn/ui Calendar component
- **Moment.js** → `date-fns` (modern alternative)
- **Flatpickr** → Shadcn/ui Calendar/DatePicker
- **Pikaday** → Custom date picker with Shadcn/ui
- **React DatePicker** → Shadcn/ui Calendar component
- **Day.js** → `date-fns` or native Date methods

### **CHARTS & VISUALIZATION**
- **Chart.js** → `recharts` (React-friendly)
- **D3.js** → `@visx/visx` (React + D3)
- **Highcharts** → `recharts` or `@visx/visx`
- **ApexCharts** → `recharts` with custom styling
- **Google Charts** → `recharts` equivalents
- **Plotly** → `@visx/visx` custom implementations

### **MAPS & LOCATION**
- **Google Maps** → `@googlemaps/react-wrapper`
- **Leaflet** → `react-leaflet`
- **Mapbox** → `react-map-gl`
- **HERE Maps** → Custom integration with React
- **OpenStreetMap** → `react-leaflet`

### **MEDIA & RICH CONTENT**
- **YouTube API** → `react-youtube` component
- **Vimeo Player** → `@vimeo/player` with React wrapper
- **HTML5 Video** → Custom video component
- **Plyr** → Custom media player with controls
- **Video.js** → Custom React video component
- **PhotoSwipe** → Custom gallery with Framer Motion

### **INTERACTIVE ELEMENTS**
- **Draggable** → `@dnd-kit/core` (React drag & drop)
- **Sortable** → `@dnd-kit/sortable`
- **Resizable** → `react-resizable`
- **Cropper** → `react-image-crop`
- **Hammer.js** → Touch event handlers
- **Interact.js** → Custom touch/drag handlers

### **SEARCH & FILTERING**
- **Lunr.js** → `fuse.js` (better fuzzy search)
- **Elasticsearch** → API integration with React
- **Algolia** → `@algolia/react-instantsearch-dom`
- **List.js** → Custom filtering with React state
- **Isotope** → Custom grid filtering with Framer Motion

### **UTILITIES**
- **Lodash** → Native JavaScript + custom utilities
- **Underscore** → Native JavaScript methods
- **RxJS** → React hooks + custom observables
- **Ramda** → Native functional programming
- **Axios** → Native `fetch()` with error handling
- **Socket.io** → `socket.io-client` with React hooks

### **PERFORMANCE & LOADING**
- **Lazy loading** → `next/image` + Intersection Observer
- **Infinite scroll** → Custom hook with Intersection Observer
- **Masonry** → CSS Grid + `react-window` for virtualization
- **Virtual scrolling** → `react-window` or `react-virtualized`
- **Image compression** → `next/image` optimization
- **Code splitting** → Next.js dynamic imports

## 🌟 PREMIUM WORLD-CLASS LIBRARIES (2024)

### **ANIMATION POWERHOUSES** (90%+ token efficiency)
- **Motion** (formerly Framer Motion) → 90% less code than alternatives, 60fps default
- **GSAP** → 20x faster than jQuery, now 100% FREE (all plugins included)
- **Lottie** → 5x faster loading than traditional formats, 29.9k GitHub stars
- **Anime.js** → Lightweight, 49.2k GitHub stars
- **Three.js** → WebGL/3D animations, 101k GitHub stars

### **ENTERPRISE UI LIBRARIES** (92k+ GitHub stars)
- **Ant Design** → 92k+ stars, enterprise-grade, comprehensive TypeScript
- **Material-UI (MUI)** → 93k+ stars, premium tier with advanced data grids
- **Chakra UI** → 37k+ stars, excellent developer experience
- **Shadcn/ui** → Copy-paste philosophy, private registry support, monorepo ready
- **Park UI** → 1.8k stars, built on Ark UI + Panda CSS (2024 release)

### **MCP INTEGRATIONS** (Model Context Protocol)
- **Microsoft MCP** → Official GitHub, Azure, development tools integration
- **MCP-UI SDK** → Interactive web components for AI assistants
- **Awesome MCP Servers** → Curated professional development servers

### **PERFORMANCE CHAMPIONS**
- **Tailwind CSS** → 78k+ stars, 8M+ weekly downloads
- **DaisyUI** → 15k+ stars, 50+ components, simple syntax
- **Flowbite** → 400+ components, Laravel/Vue.js compatible
- **React Suite** → 8k+ stars, 97k weekly downloads

## Implementation Priority Matrix

### **🏆 ENTERPRISE PRIORITY** (World-class professional sites)
- **Motion animations** → 90% token reduction, silky smooth 60fps
- **Shadcn/ui components** → Copy-paste ownership, private registry
- **GSAP complex animations** → Industry standard, now completely free
- **Lottie brand animations** → After Effects integration, 5x faster
- **MCP integration** → AI-powered development workflow

### **HIGH PRIORITY** (Essential for most sites)
- Smooth scrolling → `scroll-behavior: smooth`
- Form validation → React Hook Form + Zod
- Responsive modals → Shadcn/ui Dialog
- Image optimization → `next/image`
- Basic animations → Motion (Framer Motion)

### **MEDIUM PRIORITY** (Common but site-dependent)
- Carousels → `embla-carousel-react`
- Date pickers → Shadcn/ui Calendar
- Charts → `recharts`
- Drag & drop → `@dnd-kit/core`
- Search → `fuse.js`

### **LOW PRIORITY** (Specialized functionality)
- Maps → `react-leaflet`
- Video players → Custom components
- Advanced animations → Complex Motion + GSAP
- Real-time features → Socket.io integration

## Detection Strategy

When analyzing target websites, the system will:

1. **Scan for library signatures** in HTML/JS source
2. **Identify functional patterns** (smooth scroll, carousels, etc.)
3. **Map to Enterprise equivalents** using this reference
4. **Implement with preferred stack** (Shadcn/ui + Framer Motion)
5. **Validate functionality match** against original behavior

## Code Example Template

```typescript
// Library Detection Pattern
const detectLibrary = (sourceCode: string) => {
  const signatures = {
    'jquery': /jquery|jQuery|\$\(/,
    'gsap': /gsap|TweenMax|TweenLite/,
    'swiper': /swiper|Swiper/,
    'aos': /AOS\.init|data-aos/
  };

  return Object.entries(signatures)
    .filter(([lib, regex]) => regex.test(sourceCode))
    .map(([lib]) => lib);
};

// Implementation Mapping
const mapToEnterprise = (detectedLibs: string[]) => {
  const mappings = {
    'jquery': 'React hooks + native JS',
    'gsap': 'Framer Motion',
    'swiper': 'embla-carousel-react',
    'aos': 'Framer Motion useInView'
  };

  return detectedLibs.map(lib => mappings[lib] || 'Custom implementation');
};
```

---

**This mapping ensures the Enterprise system can clone any website's functionality using modern, maintainable React/TypeScript implementations.**