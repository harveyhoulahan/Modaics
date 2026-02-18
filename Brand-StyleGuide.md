# Brand Style Guide

## Modaics Visual Identity

---

## Logo Usage

### Primary Logo
The Modaics logo combines wordmark "Modaics" with a subtle emerald accent on the "ics" suffix, representing our technology-forward approach to fashion.

### Clear Space
Maintain minimum clear space around the logo equal to the height of the letter "M" in the wordmark.

### Minimum Sizes
- **Digital**: 32px height
- **Print**: 0.5 inch height

### Incorrect Usage
❌ Don't stretch or distort the logo  
❌ Don't change the logo colors  
❌ Don't add effects like shadows or glows (except approved versions)  
❌ Don't rotate the logo  
❌ Don't place on busy backgrounds without contrast

---

## Color System

### Primary Colors

**Midnight Green**
- HEX: #0D3B2E
- RGB: 13, 59, 46
- CMYK: 78, 0, 22, 77
- Usage: Primary backgrounds, headers

**Racing Green**
- HEX: #1A5F4A
- RGB: 26, 95, 74
- CMYK: 73, 0, 22, 63
- Usage: Secondary elements, cards, hover states

**Emerald**
- HEX: #2ECC71
- RGB: 46, 204, 113
- CMYK: 77, 0, 45, 20
- Usage: CTAs, accents, success states, highlights

### Neutral Colors

**Liquid Silver**
- HEX: #E8E8E8
- RGB: 232, 232, 232
- Usage: Primary text on dark backgrounds

**Graphite**
- HEX: #2C2C2C
- RGB: 44, 44, 44
- Usage: Subtle backgrounds, dividers

### Accent Colors

**Gold Premium**
- HEX: #D4AF37
- RGB: 212, 175, 55
- Usage: Premium badges, special features, achievements

### Gradient Combinations

**Primary Gradient**
```css
background: linear-gradient(135deg, #0D3B2E 0%, #1A5F4A 100%);
```

**Emerald Glow**
```css
background: linear-gradient(135deg, #2ECC71 0%, #27AE60 100%);
```

**Silver Metallic**
```css
background: linear-gradient(135deg, #E8E8E8 0%, #B8B8B8 100%);
```

---

## Typography

### Primary Font: Playfair Display

**Weights Available:**
- Regular (400)
- Medium (500)
- Semi-bold (600)
- Bold (700)

**Usage:**
- Headlines (H1-H3)
- Logo wordmark
- Editorial content
- Quote highlights

**Google Fonts Import:**
```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&display=swap" rel="stylesheet">
```

### Secondary Font: Inter

**Weights Available:**
- Light (300)
- Regular (400)
- Medium (500)
- Semi-bold (600)
- Bold (700)

**Usage:**
- Body text
- UI elements
- Captions
- Buttons
- Navigation

**Google Fonts Import:**
```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

### Type Scale

| Element | Font | Size | Weight | Line Height |
|---------|------|------|--------|-------------|
| H1 | Playfair Display | 72px / 4.5rem | 600 | 1.1 |
| H2 | Playfair Display | 48px / 3rem | 600 | 1.2 |
| H3 | Playfair Display | 32px / 2rem | 500 | 1.3 |
| H4 | Inter | 24px / 1.5rem | 600 | 1.4 |
| Body Large | Inter | 20px / 1.25rem | 400 | 1.6 |
| Body | Inter | 16px / 1rem | 400 | 1.6 |
| Small | Inter | 14px / 0.875rem | 400 | 1.5 |
| Caption | Inter | 12px / 0.75rem | 500 | 1.4 |

---

## UI Components

### Buttons

**Primary Button**
```css
background: #2ECC71;
color: #0A2A21;
padding: 16px 32px;
border-radius: 50px;
font-weight: 600;
transition: all 0.3s ease;
```
Hover: Darken 10%, add subtle shadow

**Secondary Button**
```css
background: transparent;
color: #E8E8E8;
border: 1px solid rgba(232, 232, 232, 0.3);
padding: 16px 32px;
border-radius: 50px;
```
Hover: Add subtle background, change border to emerald

### Cards

**Standard Card**
```css
background: rgba(26, 95, 74, 0.3);
border: 1px solid rgba(255, 255, 255, 0.05);
border-radius: 20px;
padding: 40px;
backdrop-filter: blur(10px);
```
Hover: Border color changes to emerald, subtle lift

### Inputs

**Text Input**
```css
background: rgba(255, 255, 255, 0.05);
border: 1px solid rgba(255, 255, 255, 0.1);
border-radius: 50px;
padding: 16px 24px;
color: #E8E8E8;
```
Focus: Border color #2ECC71

---

## Imagery Style

### Photography Guidelines

**Product Photography:**
- Clean, minimal backgrounds
- Soft, natural lighting
- Focus on texture and craftsmanship
- 45-degree angle or flat lay

**Lifestyle Photography:**
- Diverse representation (age, size, ethnicity)
- Authentic, candid moments
- Urban and natural settings
- Environmental context (subtle)

**Do's:**
✓ Use natural light when possible
✓ Show diversity and inclusion
✓ Focus on quality over quantity
✓ Include environmental elements subtly
✓ Authentic expressions and poses

**Don'ts:**
✗ Overly staged or artificial
✗ Cluttered backgrounds
✗ Fast fashion aesthetic
✗ Heavy filters or editing
✗ Stereotypical "eco" imagery (too much green)

### Color Grading
- Slightly desaturated
- Warm highlights, cool shadows
- Maintain skin tone accuracy
- Consistent color temperature across assets

---

## Voice & Tone

### Brand Voice Characteristics

**Sophisticated Yet Approachable**
- Premium feel without being pretentious
- Use elegant language that's still accessible
- Avoid jargon unless explaining it

**Sustainability-Focused**
- Positive and hopeful, not guilt-inducing
- Empowering rather than preachy
- Celebrate small wins

**Fashion-Forward**
- Trend-aware but timeless
- Style-conscious language
- Appreciation for quality and design

**Community-Driven**
- Inclusive "we" language
- Welcoming to newcomers
- Celebratory of community achievements

### Writing Guidelines

**DO:**
- Use active voice
- Keep sentences concise
- Address the user directly
- Use specific numbers and data
- Include clear calls-to-action

**DON'T:**
- Use passive voice excessively
- Overpromise or exaggerate
- Use guilt as a motivator
- Include overly technical language
- Be vague about benefits

### Sample Phrases

**Instead of:** "Buy secondhand clothes"  
**Use:** "Discover pre-loved fashion"

**Instead of:** "Reduce your carbon footprint"  
**Use:** "Watch your positive impact grow"

**Instead of:** "Sell your old clothes"  
**Use:** "Transform your closet into currency"

**Instead of:** "Sustainable fashion app"  
**Use:** "Your digital wardrobe for sustainable fashion"

---

## App Store Presence

### App Name
**Modaics**
- Clean, memorable
- Combines "Moda" (fashion) + "ics" (technology)
- Easy to pronounce and spell

### Subtitle
**Sustainable Fashion Marketplace**
- Clear value proposition
- SEO-friendly keywords
- Character limit compliant

### Taglines
1. "Your Digital Wardrobe for Sustainable Fashion"
2. "Style Meets Sustainability"
3. "Transform Your Closet Into Currency"
4. "Fashion That Feels As Good As It Looks"

---

## Animation & Motion

### Timing
- **Micro-interactions**: 150-200ms
- **UI transitions**: 300ms
- **Page transitions**: 400-500ms
- **Hero animations**: 800-1000ms

### Easing
```css
/* Standard ease */
cubic-bezier(0.4, 0.0, 0.2, 1)

/* Decelerate (entering) */
cubic-bezier(0.0, 0.0, 0.2, 1)

/* Accelerate (exiting) */
cubic-bezier(0.4, 0.0, 1, 1)

/* Bounce (playful elements) */
cubic-bezier(0.68, -0.55, 0.265, 1.55)
```

### Preferred Animations
- Fade and slide for page transitions
- Scale on hover for interactive elements
- Subtle rotation for loading states
- Parallax for depth (hero sections)

---

## Accessibility

### Color Contrast
- All text must meet WCAG AA standards
- Minimum contrast ratio: 4.5:1 for normal text
- Minimum contrast ratio: 3:1 for large text

### Interactive Elements
- Minimum touch target: 44x44 points
- Visible focus states
- Clear hover states

### Typography
- Minimum body text size: 16px
- Line height minimum: 1.5
- Avoid all-caps for body text

---

## File Naming Conventions

### Images
```
modaics-[category]-[description]-[size].[ext]

Examples:
modaics-icon-appstore-1024.png
modaics-screenshot-search-iphone15.png
modaics-social-launch-instagram.png
```

### Documents
```
Modaics_[Type]_[Description]_[Version].[ext]

Examples:
Modaics_PressRelease_Launch_v1.docx
Modaics_Presentation_Investor_v2.pptx
```

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 18, 2026 | Modaics Team | Initial brand guidelines |

---

**Questions about brand usage?**  
Contact: brand@modaics.com
