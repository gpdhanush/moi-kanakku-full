G.K Tech — Premium Interactive IT Company Website

Build a premium, modern, cinematic public website for an IT services and software product company called G.K Tech.

The website should feel like a high-end technology company website with the visual quality of modern award-winning interactive websites such as lykus.app, but do not copy its design, layout, branding, content, animations, or assets.

Create an original visual identity for G.K Tech.

---

1. Company Information

Company

G.K Tech

Contact Person

Kiruba

Phone

+91 95978 83290

Email

jkirena@gmail.com

Address

Velachery, Chennai - 600042, Tamil Nadu, India

G.K Tech provides technology services and develops its own software products.

---

2. Business Categories

G.K Tech provides:

- Web Development
- Mobile Application Development
- Custom Software Development
- UI/UX Design
- Backend & API Development
- AI Solutions
- AI Automation
- Business Automation
- Cloud Solutions
- Database Solutions
- Maintenance & Support
- Digital Product Development

G.K Tech also develops and owns multiple software products.

One of the main products is:

Moi Kanakku

Moi Kanakku is a personal function-gift money tracking application that helps users record and manage money given and received during weddings, birthdays, housewarming ceremonies, festivals and other family functions.

Design the architecture so additional products can be added later without changing the overall website structure.

---

3. Main Objective

The website should:

1. Build trust
2. Showcase G.K Tech services
3. Showcase software products
4. Showcase client projects
5. Display testimonials
6. Generate leads
7. Allow visitors to contact G.K Tech
8. Allow visitors to start WhatsApp conversations
9. Allow visitors to book Google Meet meetings
10. Provide an AI assistant
11. Present the company as a professional technology partner

The website must look like a real production company website, NOT a generic AI-generated landing page.

---

4. Design Direction

Create a:

- Premium
- Modern
- Cinematic
- Minimal
- Professional
- Technology-focused
- Human-friendly
- High-end
- Responsive

visual language.

Use:

- Large typography
- Strong visual hierarchy
- Generous whitespace
- Dark premium background
- Subtle gradients
- Soft lighting
- Depth
- Glass effects only where appropriate
- 3D visual elements
- Smooth transitions
- Scroll-driven animation
- Parallax
- Micro-interactions

Avoid excessive:

- Rounded cards
- Gradients
- Glassmorphism
- Shadows
- Neon colors
- Random animations
- Decorative elements

Every animation must have a purpose.

---

5. Hero Section

Create an immersive full-screen hero.

Headline:

We build digital products that move businesses forward.

Supporting text:

Web. Mobile. Software. AI.

Primary CTA:

Start a Project

Secondary CTA:

Explore Our Work

Include an interactive 3D-inspired visual / abstract technology object.

The hero should have:

- Slow floating animation
- Subtle parallax
- Pointer interaction on desktop
- Scroll-based movement
- Text reveal
- Image/3D transition

When scrolling:

- Hero text moves naturally
- Visual scales
- Visual rotates or changes position
- Next section gradually appears
- No aggressive scroll hijacking

---

6. Smooth Scrolling

Implement smooth scrolling throughout the website.

Use a reusable smooth-scroll architecture.

Recommended technologies:

- Lenis
- GSAP
- ScrollTrigger
- Framer Motion where useful

Do not create random scroll listeners in every component.

Create reusable utilities/hooks.

Example architecture:

src/
├── animations/
│   ├── scroll.ts
│   ├── reveal.ts
│   ├── magnetic.ts
│   └── transitions.ts
│
├── hooks/
│   ├── useSmoothScroll.ts
│   ├── useScrollReveal.ts
│   └── useMediaQuery.ts
│
└── components/
    └── motion/

---

7. Reusable Component Architecture

This is extremely important.

DO NOT duplicate UI code.

Create reusable components and reuse them throughout the website.

Examples:

components/
├── layout/
│   ├── Navbar
│   ├── Footer
│   ├── PageContainer
│   └── Section
│
├── navigation/
│   ├── Navbar
│   ├── MobileMenu
│   └── Breadcrumb
│
├── buttons/
│   ├── PrimaryButton
│   ├── SecondaryButton
│   ├── MagneticButton
│   └── IconButton
│
├── motion/
│   ├── Reveal
│   ├── RevealText
│   ├── FadeIn
│   ├── Parallax
│   ├── Stagger
│   └── PageTransition
│
├── cards/
│   ├── ServiceCard
│   ├── ProductCard
│   ├── ProjectCard
│   ├── TestimonialCard
│   └── TechnologyCard
│
├── sections/
│   ├── HeroSection
│   ├── ServicesSection
│   ├── ProductsSection
│   ├── ProjectsSection
│   ├── TestimonialsSection
│   ├── ProcessSection
│   ├── FAQSection
│   └── ContactSection
│
├── forms/
│   ├── ContactForm
│   ├── MeetingForm
│   └── ProjectEnquiryForm
│
└── 3d/
    ├── Scene
    ├── FloatingObject
    └── ProductVisual

All components should have clean TypeScript props.

---

8. Navigation

Create a fixed premium navigation.

Desktop:

G.K TECH

Services
Products
Work
About
Testimonials
Contact

[ Start a Project ]

Navbar should:

- Become slightly smaller while scrolling
- Have subtle backdrop blur
- Maintain strong readability
- Animate smoothly

Mobile:

Use a fullscreen animated menu.

---

9. Services Section

Create a large editorial services section.

Do not use a basic 3-column SaaS card grid.

Use scroll-driven typography.

Example:

01

WEB
EXPERIENCES

Then:

02

MOBILE
APPLICATIONS

Then:

03

CUSTOM
SOFTWARE

Then:

04

AI &
AUTOMATION

Then:

05

UI / UX
DESIGN

Each service should have:

- Short description
- Technology
- CTA
- Visual interaction

Use reusable "ServiceCard" / "ServiceSection" components.

---

10. Products Section

Create a dedicated product showcase.

Title:

Our Products

Subtitle:

Technology products built to solve real-world problems.

Display products using reusable "ProductCard" components.

Initial product:

Moi Kanakku

Description:

A simple and powerful way to record, manage and track function gifts and money given or received.

Category:

Personal Finance / Family Functions

CTA:

Explore Moi Kanakku

Create product detail routing:

/products/moi-kanakku

Architecture must support future products:

/products/product-2
/products/product-3
/products/product-4

Do not hardcode the product layout separately for every product.

Use a reusable product data model.

---

11. Projects Section

Create:

Selected Work

Show client projects separately from company products.

Filters:

- All
- Web
- Mobile
- Software
- AI
- Business

Use reusable "ProjectCard".

Each project can contain:

- Image
- Title
- Category
- Description
- Technologies
- Client
- Year
- Project URL

Use large visual layouts and scroll animation.

---

12. Technology Section

Create an interactive technology ecosystem.

Show technologies such as:

- Flutter
- React
- Next.js
- Angular
- Node.js
- TypeScript
- JavaScript
- MySQL
- REST APIs
- AI
- Cloud

Use subtle floating/motion effects.

Do not make it look like a simple logo wall.

---

13. Process Section

Create:

How We Build

Steps:

01 — Discover
02 — Plan
03 — Design
04 — Build
05 — Test
06 — Launch
07 — Support

Use horizontal scroll or scroll-driven progression.

The active step should visually expand while scrolling.

Use a reusable "ProcessStep" component.

---

14. About Section

Create a premium company introduction.

Headline:

Technology should solve problems, not create them.

Explain that G.K Tech builds:

- Business applications
- Mobile applications
- Websites
- Software products
- AI solutions
- Digital experiences

Keep the copy concise and professional.

---

15. Testimonials

Create a premium testimonial section.

Title:

What Our Clients Say

Each testimonial supports:

name
company
designation
photo
rating
review
project

Create reusable "TestimonialCard".

Support:

- Horizontal scrolling
- Auto rotation
- Manual navigation
- Smooth transitions

Do not make it an overly aggressive carousel.

Testimonials must be data-driven so they can later come from an API/database.

---

16. AI Assistant

Add a floating AI assistant.

Position:

Bottom-right.

Example:

G.K Tech AI

How can we help?

• Build a website
• Build a mobile app
• Develop custom software
• AI & automation
• Learn about our products
• Get a project estimate
• Book a meeting
• Talk to G.K Tech

The AI assistant should understand G.K Tech company information.

It should be designed so a backend AI API can later be connected.

Create reusable components:

AIButton
AIChat
AIMessage
AIQuickAction
AIInput

For the initial frontend prototype, use mock responses.

Do NOT expose API keys in frontend code.

---

17. WhatsApp Integration

Create a floating WhatsApp action.

Use the company's WhatsApp number when configured.

Support contextual messages.

Examples:

General:

"Hi G.K Tech, I would like to know more about your services."

Website:

"Hi G.K Tech, I am interested in developing a website."

Mobile:

"Hi G.K Tech, I am interested in developing a mobile application."

Moi Kanakku:

"Hi G.K Tech, I would like to know more about Moi Kanakku."

Create reusable:

"WhatsAppButton"

Allow the message to be passed dynamically.

---

18. Meeting Booking

Create:

Book a Meeting

Allow visitors to:

1. Select service
2. Select preferred date
3. Select preferred time
4. Enter name
5. Enter email
6. Enter phone
7. Add message
8. Submit

Design the frontend so it can later integrate with:

Google Calendar API + Google Meet

After successful booking:

Meeting Confirmed

Date:
Time:

Google Meet
[ Join Meeting ]

[ Add to Google Calendar ]

For the initial Lovable implementation, use mock booking data if backend/API credentials are unavailable.

Never expose Google API credentials in frontend code.

---

19. Contact Us

Create a premium contact section.

Headline:

Have an idea? Let's build it.

Contact details:

Kiruba

+91 95978 83290

jkirena@gmail.com

Velachery, Chennai - 600042

Contact form:

- Name
- Company
- Email
- Phone
- Service
- Project type
- Budget
- Message
- Attachment

CTA:

Send Enquiry

After submission show a clean success state.

---

20. FAQ

Create an animated FAQ section.

Questions should cover:

- What services does G.K Tech provide?
- Do you build mobile applications?
- Do you build custom software?
- Do you provide AI solutions?
- How long does a project take?
- Can you maintain an existing application?
- Can I book a meeting?
- How can I contact G.K Tech?
- What is Moi Kanakku?

Use reusable "FAQItem".

---

21. Footer

Premium footer:

G.K TECH

We build digital products
that move businesses forward.

Services
Products
Projects
About
Testimonials
Contact

WhatsApp
Email
Phone

Velachery,
Chennai - 600042

©️ G.K Tech
All rights reserved.

Include social links where available.

---

22. Floating Actions

Create reusable floating action system.

Desktop:

- AI
- WhatsApp
- Book Meeting

Mobile:

Use a compact expandable floating button.

Do not cover important content.

---

23. Loading Experience

Create a minimal premium loading animation.

Example:

G.K TECH

Building digital experiences...

[ progress ]

Do not make loading unnecessarily long.

If assets are cached or loading is already complete, skip the heavy loading experience.

---

24. 3D Visual System

Use 3D visuals strategically.

Do not put expensive 3D scenes in every section.

Use:

- Hero
- Product showcase
- Selected work transitions
- CTA ending

Use optimized models.

Support:

- GLB / GLTF
- Draco
- Lazy loading
- Adaptive DPR
- Responsive rendering

On low-performance devices, provide a simplified fallback.

---

25. Scroll Animation Rules

Animations should feel:

- Smooth
- Cinematic
- Natural
- Fast
- Premium

Use:

- Fade
- Translate
- Scale
- Rotation
- Clip-path
- Parallax
- Stagger
- Horizontal scroll
- 3D transform

Avoid:

- Excessive bouncing
- Long animations
- Random movement
- Scroll hijacking
- Constant motion

Animation duration should generally stay within a comfortable range.

---

26. Accessibility

Support:

"prefers-reduced-motion"

When enabled:

- Disable complex 3D movement
- Reduce parallax
- Reduce transitions
- Preserve content
- Preserve navigation

Ensure:

- Keyboard navigation
- Proper focus states
- Semantic HTML
- Accessible labels
- Good color contrast
- Form validation messages

---

27. Responsive Design

The website must be designed independently for:

- Mobile
- Tablet
- Laptop
- Desktop
- Large desktop
- 4K

Do not simply shrink desktop layouts.

Mobile should have:

- Simplified 3D
- Reduced particle effects
- Touch-friendly buttons
- Simplified navigation
- Optimized typography
- Reduced animation complexity

---

28. Data Architecture

Even if the first version uses local/mock data, structure the frontend as if it will connect to an API.

Example:

data/
├── services.ts
├── products.ts
├── projects.ts
├── testimonials.ts
├── technologies.ts
├── faq.ts
└── company.ts

Do not hardcode the same information across components.

Example:

Product {
  id
  slug
  name
  description
  category
  logo
  image
  features
  technologies
  url
  status
}

Use the same reusable model for all products.

---

29. Future Admin/API Compatibility

The website should eventually support:

Admin
   ↓
Node.js API
   ↓
MySQL
   ↓
Public Website

Prepare frontend components to consume API data later.

Do not tightly couple UI components to static mock data.

---

30. SEO

Implement:

- Proper metadata
- Open Graph
- Twitter/X cards
- Semantic headings
- Sitemap
- Robots.txt
- Canonical URLs
- Structured data where appropriate

Product pages should have individual SEO metadata.

Example:

/products/moi-kanakku

should have its own title and description.

---

31. Performance

Performance is extremely important.

Implement:

- Lazy loading
- Dynamic imports
- Image optimization
- WebP/AVIF
- 3D model optimization
- Code splitting
- Responsive image sizes
- Adaptive 3D quality
- Avoid unnecessary React renders

Do not allow animation libraries or 3D assets to block initial page rendering.

Target an excellent Lighthouse score.

---

32. Component Reusability Rule

IMPORTANT:

Before creating a new UI component, check whether an existing reusable component can be extended.

Do not create:

"ProductCard1"

"ProductCard2"

"ProductCard3"

Instead create:

"ProductCard"

with configurable props.

Same principle applies to:

- Buttons
- Cards
- Sections
- Animations
- Forms
- Modals
- Testimonials
- FAQ
- Project cards
- Product cards
- Navigation
- CTAs

Build once, reuse everywhere.

---

33. Design System

Create centralized design tokens.

Define:

- Colors
- Typography
- Spacing
- Border radius
- Shadows
- Motion duration
- Motion easing
- Breakpoints

Do not scatter arbitrary values throughout the code.

The website should have one consistent visual language.

---

34. Final Experience

The final website should feel like:

A premium technology company + digital studio + software product company.

It should communicate:

TRUST
TECHNOLOGY
QUALITY
INNOVATION
HUMAN CONNECTION

The visitor should naturally move through this journey:

DISCOVER
   ↓
UNDERSTAND
   ↓
EXPLORE SERVICES
   ↓
DISCOVER PRODUCTS
   ↓
SEE CLIENT WORK
   ↓
READ TESTIMONIALS
   ↓
ASK AI
   ↓
WHATSAPP
   ↓
BOOK MEETING
   ↓
START PROJECT

Do not build only a beautiful landing page.

Build a scalable foundation that can grow into the official public website for G.K Tech and support multiple products, services, projects, testimonials, leads, AI conversations and meeting bookings.

Before finishing, verify:

- No duplicated components
- No broken links
- No TypeScript errors
- No console errors
- Responsive at all major breakpoints
- Mobile navigation works
- Contact form works
- WhatsApp CTA works
- Meeting booking UI works
- AI assistant UI works
- Testimonials work
- Product pages work
- Reduced-motion mode works
- Loading experience works
- Production build succeeds