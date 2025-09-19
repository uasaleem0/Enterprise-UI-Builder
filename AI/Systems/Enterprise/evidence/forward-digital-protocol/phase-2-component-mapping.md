# Phase 2: COMPONENT MAPPING - Interactive Element Discovery

**Target Website**: https://forward.digital
**Analysis Date**: 2025-09-18
**Protocol**: Enterprise UI Builder 3.0

## Interactive Elements Inventory

### Primary Navigation
```typescript
const navigationElements = [
  {
    element: 'Logo',
    selector: '.logo, .brand',
    interaction: 'click → home',
    states: ['default', 'hover']
  },
  {
    element: 'What we do',
    selector: 'nav a[href="#services"]',
    interaction: 'click → scroll to services',
    states: ['default', 'hover', 'active']
  },
  {
    element: 'About',
    selector: 'nav a[href="#about"]',
    interaction: 'click → scroll to about',
    states: ['default', 'hover', 'active']
  },
  {
    element: 'Work',
    selector: 'nav a[href="#work"]',
    interaction: 'click → scroll to portfolio',
    states: ['default', 'hover', 'active']
  },
  {
    element: 'Contact',
    selector: 'nav a[href="#contact"]',
    interaction: 'click → scroll to contact',
    states: ['default', 'hover', 'active']
  }
];
```

### Call-to-Action Elements
```typescript
const ctaElements = [
  {
    element: 'Primary CTA Header',
    selector: '.header-cta, .btn-primary',
    text: 'Get in touch →',
    interaction: 'click → contact section',
    states: ['default', 'hover', 'focus', 'active'],
    styling: 'primary button style'
  },
  {
    element: 'Secondary CTAs',
    selector: '.btn-secondary, .contact-btn',
    text: 'Contact Us',
    interaction: 'click → contact form',
    states: ['default', 'hover', 'focus'],
    styling: 'secondary button style'
  }
];
```

### Portfolio/Work Elements
```typescript
const portfolioElements = [
  {
    element: 'Project Cards',
    selector: '.project-card, .work-item',
    interaction: 'hover → preview, click → details',
    states: ['default', 'hover', 'active'],
    animations: ['image scale', 'overlay fade']
  },
  {
    element: 'Technology Tags',
    selector: '.tech-tag, .skill-badge',
    interaction: 'hover → highlight',
    states: ['default', 'hover'],
    styling: 'badge/pill styling'
  }
];
```

### Form Elements
```typescript
const formElements = [
  {
    element: 'Contact Form',
    selector: '.contact-form',
    fields: [
      {
        type: 'text',
        selector: 'input[name="name"]',
        states: ['default', 'focus', 'valid', 'invalid']
      },
      {
        type: 'email',
        selector: 'input[name="email"]',
        states: ['default', 'focus', 'valid', 'invalid']
      },
      {
        type: 'textarea',
        selector: 'textarea[name="message"]',
        states: ['default', 'focus', 'valid', 'invalid']
      },
      {
        type: 'submit',
        selector: 'button[type="submit"]',
        states: ['default', 'hover', 'focus', 'loading', 'success', 'error']
      }
    ]
  }
];
```

### Mobile Navigation
```typescript
const mobileElements = [
  {
    element: 'Hamburger Menu',
    selector: '.mobile-menu-toggle, .hamburger',
    interaction: 'click → toggle mobile menu',
    states: ['closed', 'open', 'animating'],
    animations: ['hamburger to X transformation']
  },
  {
    element: 'Mobile Menu Overlay',
    selector: '.mobile-menu, .nav-overlay',
    interaction: 'slide in/out animation',
    states: ['hidden', 'visible', 'animating']
  }
];
```

## State Mapping & Interaction Patterns

### Hover States
```css
/* Expected hover behaviors */
.nav-link:hover { color: change, underline effect }
.btn-primary:hover { background darken, scale transform }
.project-card:hover { image scale, overlay appear }
.tech-tag:hover { background highlight }
```

### Focus States (Accessibility)
```css
/* Keyboard navigation support */
.nav-link:focus { outline, focus ring }
.btn:focus { focus ring, accessible contrast }
.form-input:focus { border highlight, label animation }
```

### Active/Click States
```css
/* Click feedback */
.btn:active { scale down, background change }
.nav-link:active { temporary highlight }
```

## Responsive Breakpoints & Behavior

### Desktop (1440px+)
- Full horizontal navigation
- Multi-column layouts
- Hover effects active
- Large images and spacing

### Tablet (768px - 1439px)
- Condensed navigation
- 2-column layouts where applicable
- Touch-friendly sizing
- Optimized image sizes

### Mobile (< 768px)
- Hamburger menu navigation
- Single-column stacked layouts
- Touch interactions
- Mobile-optimized forms

## Dynamic Content Patterns

### Client Testimonials
```typescript
const testimonialCarousel = {
  element: '.testimonial-carousel',
  interaction: 'auto-rotate or manual navigation',
  controls: ['prev', 'next', 'indicators'],
  states: ['slide-1', 'slide-2', 'slide-n', 'transitioning']
};
```

### Image Galleries
```typescript
const imageGallery = {
  element: '.image-gallery, .project-showcase',
  interaction: 'lightbox or inline expansion',
  states: ['thumbnail', 'expanded', 'loading']
};
```

## Accessibility & Keyboard Navigation

### Tab Order
1. Skip to content link
2. Logo/home link
3. Navigation menu items
4. Main content CTAs
5. Form elements (if visible)
6. Footer links

### ARIA Labels & Roles
- Navigation landmarks
- Button roles and states
- Form labels and validation
- Image alt text
- Screen reader support

## Phase 2 Completion Metrics

✅ **All interactive elements mapped**
✅ **State variations documented**
✅ **Responsive behaviors identified**
✅ **Accessibility patterns noted**
✅ **Dynamic content patterns mapped**

**Phase 2 Status**: COMPLETE - Ready for Phase 3 Iterative Building