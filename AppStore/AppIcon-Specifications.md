# Modaics App Icon Specifications

## Color Palette - Dark Green Porsche Aesthetic

| Color Name | HEX | Usage |
|------------|-----|-------|
| Midnight Green | #0D3B2E | Primary background |
| Racing Green | #1A5F4A | Secondary elements |
| Emerald Accent | #2ECC71 | Highlights, CTAs |
| Liquid Silver | #E8E8E8 | Text, icons |
| Graphite | #2C2C2C | Dark accents |
| Gold Premium | #D4AF37 | Premium badge accent |

## Icon Sizes Required

### iPhone (iOS)
| Size | Purpose | Filename |
|------|---------|----------|
| 20pt @2x | Notification | icon-20@2x.png |
| 20pt @3x | Notification | icon-20@3x.png |
| 29pt @2x | Settings | icon-29@2x.png |
| 29pt @3x | Settings | icon-29@3x.png |
| 40pt @2x | Spotlight | icon-40@2x.png |
| 40pt @3x | Spotlight | icon-40@3x.png |
| 60pt @2x | App Icon | icon-60@2x.png |
| 60pt @3x | App Icon | icon-60@3x.png |

### iPad (iOS)
| Size | Purpose | Filename |
|------|---------|----------|
| 20pt @1x | Notification | icon-20.png |
| 20pt @2x | Notification | icon-20@2x.png |
| 29pt @1x | Settings | icon-29.png |
| 29pt @2x | Settings | icon-29@2x.png |
| 40pt @1x | Spotlight | icon-40.png |
| 40pt @2x | Spotlight | icon-40@2x.png |
| 76pt @1x | App Icon | icon-76.png |
| 76pt @2x | App Icon | icon-76@2x.png |
| 83.5pt @2x | App Icon Pro | icon-83.5@2x.png |

### App Store
| Size | Purpose | Filename |
|------|---------|----------|
| 1024pt @1x | App Store | icon-1024.png |

## Design Specifications

### Primary Icon Concept
- **Shape**: Rounded square (Apple standard: 20% corner radius)
- **Background**: Gradient from Midnight Green (#0D3B2E) to Racing Green (#1A5F4A)
- **Center Element**: Stylized "M" formed by two interlocking clothing hanger shapes
- **Accent**: Subtle emerald glow effect on edges
- **Finish**: Slight metallic sheen suggesting premium automotive paint

### Icon Construction
```
┌─────────────────────┐
│   Midnight Green    │
│     Gradient        │
│                     │
│    ╭───────╮        │
│    │   M   │  ← Hanger "M" logo
│    ╰───────╯        │
│    Emerald glow     │
│                     │
└─────────────────────┘
```

### Typography
- If text used: San Francisco Pro Display, Medium weight
- Text color: Liquid Silver (#E8E8E8)

## Export Guidelines

1. **Format**: PNG with transparency where needed
2. **Color Space**: sRGB
3. **Layers**: Flattened, no transparency on App Store icon
4. **Resolution**: 72 DPI for screen, 300 DPI for print materials

## Asset Bundle Contents

```
AppIcon.appiconset/
├── Contents.json
├── icon-20.png
├── icon-20@2x.png
├── icon-20@3x.png
├── icon-29.png
├── icon-29@2x.png
├── icon-29@3x.png
├── icon-40.png
├── icon-40@2x.png
├── icon-40@3x.png
├── icon-60@2x.png
├── icon-60@3x.png
├── icon-76.png
├── icon-76@2x.png
├── icon-83.5@2x.png
└── icon-1024.png
```

## Contents.json Template

```json
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "icon-20@2x.png",
      "scale": "2x"
    },
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "icon-20@3x.png",
      "scale": "3x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "filename": "icon-29@2x.png",
      "scale": "2x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "filename": "icon-29@3x.png",
      "scale": "3x"
    },
    {
      "size": "40x40",
      "idiom": "iphone",
      "filename": "icon-40@2x.png",
      "scale": "2x"
    },
    {
      "size": "40x40",
      "idiom": "iphone",
      "filename": "icon-40@3x.png",
      "scale": "3x"
    },
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "icon-60@2x.png",
      "scale": "2x"
    },
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "icon-60@3x.png",
      "scale": "3x"
    },
    {
      "size": "20x20",
      "idiom": "ipad",
      "filename": "icon-20.png",
      "scale": "1x"
    },
    {
      "size": "20x20",
      "idiom": "ipad",
      "filename": "icon-20@2x.png",
      "scale": "2x"
    },
    {
      "size": "29x29",
      "idiom": "ipad",
      "filename": "icon-29.png",
      "scale": "1x"
    },
    {
      "size": "29x29",
      "idiom": "ipad",
      "filename": "icon-29@2x.png",
      "scale": "2x"
    },
    {
      "size": "40x40",
      "idiom": "ipad",
      "filename": "icon-40.png",
      "scale": "1x"
    },
    {
      "size": "40x40",
      "idiom": "ipad",
      "filename": "icon-40@2x.png",
      "scale": "2x"
    },
    {
      "size": "76x76",
      "idiom": "ipad",
      "filename": "icon-76.png",
      "scale": "1x"
    },
    {
      "size": "76x76",
      "idiom": "ipad",
      "filename": "icon-76@2x.png",
      "scale": "2x"
    },
    {
      "size": "83.5x83.5",
      "idiom": "ipad",
      "filename": "icon-83.5@2x.png",
      "scale": "2x"
    },
    {
      "size": "1024x1024",
      "idiom": "ios-marketing",
      "filename": "icon-1024.png",
      "scale": "1x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
```
