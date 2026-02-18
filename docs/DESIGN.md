# Modaics Design System

The Dark Green Porsche Aesthetic - Premium Sustainable Fashion Design Language

---

## 🎨 Design Philosophy

> *"Like a Porsche in a forest - luxury meets nature"*

Modaics' design system combines the sophistication of luxury automotive design with the organic warmth of sustainable fashion. The dark green palette evokes premium craftsmanship while gold accents signal exclusivity and quality.

### Core Principles

1. **Premium without Pretension** - Luxury that feels accessible
2. **Organic Elegance** - Natural colors with refined presentation
3. **Sustainable Signaling** - Visual cues that communicate eco-consciousness
4. **Dark Mode First** - Optimized for OLED displays and battery efficiency

---

## 🌲 Color Palette

### Primary Colors (Forest Greens)

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Forest Deep** | `#0D1F14` | rgb(13, 31, 20) | Main app background, deepest layer |
| **Forest Rich** | `#142E1C` | rgb(20, 46, 28) | Secondary surfaces, sheets |
| **Forest Mid** | `#1C3824` | rgb(28, 56, 36) | Cards, elevated surfaces |
| **Forest Soft** | `#24422B` | rgb(36, 66, 43) | Subtle backgrounds, hover states |
| **Forest Light** | `#2E523A` | rgb(46, 82, 58) | Borders, dividers |

### Accent Colors (Luxury Golds)

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Luxe Gold** | `#D9BD6B` | rgb(217, 189, 107) | Primary accent, CTAs, icons |
| **Luxe Gold Bright** | `#EBD185` | rgb(235, 209, 133) | Highlights, hover states |
| **Luxe Gold Deep** | `#B89E4A` | rgb(184, 158, 74) | Shadows, pressed states |
| **Luxe Gold Subtle** | `#D9BD6B33` | rgba(217, 189, 107, 0.2) | Borders, dividers |

### Sustainability Colors (Emerald Greens)

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Emerald** | `#33B873` | rgb(51, 184, 115) | Success, eco-positive actions |
| **Emerald Bright** | `#47D187` | rgb(71, 209, 135) | Active states, notifications |
| **Emerald Deep** | `#258B5A` | rgb(37, 139, 90) | Shadows, pressed states |
| **Emerald Glow** | `#33B87340` | rgba(51, 184, 115, 0.25) | Success glows |

### Text Colors (Sage Whites)

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Sage White** | `#F5F3EE` | rgb(245, 243, 238) | Primary text |
| **Sage Muted** | `#BFC7B8` | rgb(191, 199, 184) | Secondary text |
| **Sage Subtle** | `#8C9585` | rgb(140, 149, 133) | Tertiary text, placeholders |
| **Gold Text** | `#D2B85C` | rgb(210, 184, 92) | Luxury accents, prices |

### Utility Colors

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Organic Green** | `#59AD59` | rgb(89, 173, 89) | Success messages |
| **Earth Amber** | `#D9A640` | rgb(217, 166, 64) | Warnings, alerts |
| **Coral Error** | `#D97368` | rgb(217, 115, 104) | Errors, destructive actions |
| **Nature Teal** | `#4DA69E` | rgb(77, 166, 158) | Info, links |

### Color Usage Patterns

```swift
// Background hierarchy
ZStack {
    Color.forestDeep        // Deepest layer
    
    VStack {
        Color.forestRich    // Secondary surface
            .cornerRadius(16)
        
        Color.forestMid     // Card surface
            .cornerRadius(12)
    }
}

// Accent usage
Text("Premium")
    .foregroundStyle(.luxeGoldGradient)  // Gold gradient text

Button("Buy Now") {}
    .buttonStyle(ForestPrimaryButtonStyle())  // Gold button

// Status colors
Label("Eco-Friendly", systemImage: "leaf")
    .foregroundColor(.emerald)  // Sustainability

Label("Limited Stock", systemImage: "exclamationmark.triangle")
    .foregroundColor(.earthAmber)  // Warning
```

---

## 🔤 Typography

### Font Family

**Primary**: SF Pro (San Francisco) - Apple's system font  
**Rationale**: Native performance, excellent readability, automatic dynamic type support

### Type Scale

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| **Hero** | 48pt | Thin (100) | 56pt | Splash screens, major headlines |
| **Display** | 36pt | Thin (100) | 44pt | Page titles |
| **Title 1** | 28pt | Light (300) | 36pt | Section headers |
| **Title 2** | 22pt | Light (300) | 30pt | Card titles |
| **Headline** | 18pt | Semibold (600) | 26pt | Emphasis, prices |
| **Body Large** | 17pt | Regular (400) | 25pt | Primary body text |
| **Body** | 15pt | Regular (400) | 23pt | Secondary text |
| **Caption** | 13pt | Medium (500) | 19pt | Labels, metadata |
| **Footnote** | 12pt | Regular (400) | 18pt | Timestamps, fine print |

### Typography Patterns

```swift
// Display text (luxury headlines)
Text("Sustainable Fashion")
    .font(.forestDisplay(36))
    .foregroundColor(.sageWhite)

// Title with gold accent
Text("$") + Text("450")
    .font(.forestHeadline(28))
    .foregroundStyle(.luxeGoldGradient)

// Body text hierarchy
VStack(alignment: .leading, spacing: 8) {
    Text("Vintage Prada Nylon")
        .font(.forestHeadline(18))
        .foregroundColor(.sageWhite)
    
    Text("Excellent condition • Authentic")
        .font(.forestBody(15))
        .foregroundColor(.sageMuted)
    
    Text("Listed 2 days ago")
        .font(.forestCaption(13))
        .foregroundColor(.sageSubtle)
}
```

### Dynamic Type Support

```swift
// Automatically scales with user preferences
Text("Content")
    .font(.forestBody(15))
    .dynamicTypeSize(.large ... .xxLarge)  // Supports accessibility sizes
```

---

## 🧩 Components

### Buttons

#### Primary Button (Gold)

```swift
Button("Purchase") {}
    .buttonStyle(ForestPrimaryButtonStyle())
```

**Specs:**
- Background: Linear gradient (Luxe Gold Bright → Luxe Gold)
- Text: Forest Deep (dark), Semibold 16pt
- Corner Radius: 12pt
- Height: 56pt
- Shadow: 0pt 4pt 12pt rgba(0,0,0,0.3)

**States:**
- Default: Full opacity
- Pressed: 0.9 scale, darker gradient
- Disabled: 0.5 opacity, gray overlay
- Loading: Shimmer animation over gold

#### Secondary Button (Emerald)

```swift
Button("Save for Later") {}
    .buttonStyle(ForestSecondaryButtonStyle())
```

**Specs:**
- Background: Linear gradient (Emerald → Emerald Deep)
- Text: Sage White, Semibold 16pt
- Corner Radius: 12pt
- Height: 48pt

#### Ghost Button (Outline)

```swift
Button("View Details") {}
    .buttonStyle(ForestGhostButtonStyle())
```

**Specs:**
- Background: Transparent with 5% gold fill
- Border: 1.5pt Luxe Gold at 50% opacity
- Text: Luxe Gold, Medium 16pt
- Corner Radius: 12pt

#### Icon Button

```swift
Button(action: {}) {
    Image(systemName: "heart")
        .font(.system(size: 20, weight: .medium))
}
.buttonStyle(ForestIconButtonStyle())
```

**Specs:**
- Size: 44pt × 44pt (minimum touch target)
- Background: Forest Mid with 50% opacity
- Icon: Sage White
- Corner Radius: 12pt

### Cards

#### Standard Card

```swift
VStack(alignment: .leading, spacing: 12) {
    // Card content
}
.padding(20)
.forestCard()
```

**Specs:**
- Background: Forest Mid at 80% opacity
- Border: 1pt Luxe Gold at 20% opacity
- Corner Radius: 16pt
- Shadow: 0pt 6pt 12pt rgba(0,0,0,0.2)

#### Elevated Card

```swift
VStack {
    // Content
}
.forestCard(isElevated: true)
```

**Specs:**
- Additional shadow: 0pt 12pt 24pt rgba(0,0,0,0.3)
- Scale: 1.02 on hover/press

#### Image Card

```swift
ZStack {
    AsyncImage(url: imageUrl)
    
    LinearGradient(
        colors: [.clear, .forestDeep.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    VStack {
        Spacer()
        Text("Item Title")
            .font(.forestHeadline(16))
    }
    .padding(16)
}
.forestCard()
```

### Input Fields

#### Text Field

```swift
TextField("Email", text: $email)
    .textFieldStyle(ForestTextFieldStyle())
```

**Specs:**
- Background: Surface Input (#0F2810)
- Border: 1pt Forest Soft, 2pt Luxe Gold when focused
- Text: Sage White, 16pt
- Placeholder: Sage Subtle
- Corner Radius: 12pt
- Height: 56pt
- Padding: 16pt horizontal

#### Search Field

```swift
HStack {
    Image(systemName: "magnifyingglass")
        .foregroundColor(.sageSubtle)
    
    TextField("Search items...", text: $searchText)
        .foregroundColor(.sageWhite)
}
.padding(12)
.background(Color.forestRich)
.cornerRadius(ForestRadius.round)
```

### Chips & Tags

#### Filter Chip

```swift
FilterChip(
    title: "Outerwear",
    isSelected: $isSelected
)
```

**Specs:**
- Background: Forest Mid (selected: Luxe Gold at 20%)
- Border: 1pt Luxe Gold at 50% opacity (selected: 100%)
- Text: Sage Muted (selected: Luxe Gold)
- Corner Radius: 8pt
- Height: 32pt
- Padding: 12pt horizontal

#### Status Tag

```swift
HStack(spacing: 4) {
    Image(systemName: "checkmark.circle.fill")
    Text("Verified")
}
.font(.forestCaption(12))
.foregroundColor(.emerald)
.padding(.horizontal, 8)
.padding(.vertical, 4)
.background(Color.emerald.opacity(0.15))
.cornerRadius(6)
```

### Lists

#### Standard List

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
.listStyle(.plain)
.background(Color.forestDeep)
```

**Specs:**
- Row height: 80pt minimum
- Separator: 1pt Forest Soft
- Selection: Forest Soft background

### Navigation

#### Navigation Bar

```swift
.navigationTitle("Discover")
.navigationBarTitleDisplayMode(.large)
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: {}) {
            Image(systemName: "bell")
                .foregroundStyle(.luxeGoldGradient)
        }
    }
}
.toolbarBackground(Color.forestDeep, for: .navigationBar)
.toolbarBackground(.visible, for: .navigationBar)
```

**Specs:**
- Background: Forest Deep
- Title: Display 34pt, Sage White
- Icons: Luxe Gold, 24pt

#### Tab Bar

```swift
TabView {
    // Tabs
}
.accentColor(.luxeGold)  // Selected color
.onAppear {
    let appearance = UITabBarAppearance()
    appearance.backgroundColor = UIColor(Color.forestRich)
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
}
```

**Specs:**
- Background: Forest Rich
- Selected: Luxe Gold
- Unselected: Sage Subtle

---

## ✨ Effects & Animations

### Shimmer Loading

```swift
SomeView()
    .forestShimmer(isLoading: isLoading)
```

**Specs:**
- Duration: 1.8s
- Gradient: Clear → Luxe Gold 30% → Luxe Gold Bright 50% → Luxe Gold 30% → Clear
- Angle: 30°

### Glow Effects

```swift
// Gold glow for premium elements
.glow(color: .luxeGold, radius: 8)

// Emerald glow for eco elements
.glow(color: .emerald, radius: 8)
```

### Spring Animations

```swift
// Premium interactions
withAnimation(.forestSpring) {
    isExpanded.toggle()
}

// Quick feedback
withAnimation(.forestQuick) {
    isPressed = true
}
```

### Shadows

```swift
// Subtle card shadow
.shadow(color: ForestShadow.subtle, radius: 12, x: 0, y: 6)

// Elevated modal shadow
.shadow(color: ForestShadow.strong, radius: 24, x: 0, y: 12)

// Gold glow shadow
.shadow(color: .luxeGold.opacity(0.3), radius: 16)
```

---

## 📐 Spacing System

| Token | Value | Usage |
|-------|-------|-------|
| **xs** | 4pt | Tight spacing, icon gaps |
| **small** | 8pt | Related elements |
| **medium** | 12pt | Default component padding |
| **large** | 16pt | Card padding |
| **xlarge** | 20pt | Section gaps |
| **xxlarge** | 24pt | Major sections |
| **section** | 32pt | Page sections |

### Spacing Patterns

```swift
VStack(spacing: ForestSpacing.section) {
    HeaderView()
    
    VStack(spacing: ForestSpacing.large) {
        ForEach(items) { item in
            ItemCard(item: item)
                .padding(.horizontal, ForestSpacing.large)
        }
    }
}
.padding(.vertical, ForestSpacing.xxlarge)
```

---

## 🔲 Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| **small** | 8pt | Chips, small buttons |
| **medium** | 12pt | Buttons, input fields |
| **large** | 16pt | Cards, modals |
| **xlarge** | 20pt | Large cards, sheets |
| **round** | 999pt | Pills, avatars |

---

## 🖼️ Images

### Image Styles

```swift
// Rounded corners
AsyncImage(url: url)
    .cornerRadius(ForestRadius.large)

// Circular avatar
AsyncImage(url: avatarUrl)
    .clipShape(Circle())
    .overlay(
        Circle()
            .stroke(Color.luxeGold.opacity(0.5), lineWidth: 2)
    )

// Aspect ratios
.aspectRatio(4/5, contentMode: .fill)  // Product images
.aspectRatio(16/9, contentMode: .fill) // Banners
```

### Placeholders

```swift
AsyncImage(url: url) { image in
    image.resizable()
} placeholder: {
    ZStack {
        Color.forestMid
        ProgressView()
            .tint(.luxeGold)
    }
}
```

---

## 📱 Responsive Design

### Breakpoints

| Device | Width | Adjustments |
|--------|-------|-------------|
| iPhone SE | 375pt | Compact spacing, smaller type |
| iPhone 15 | 393pt | Default |
| iPhone 15 Pro Max | 430pt | Expanded spacing |
| iPad | 768pt+ | Two-column layouts |

### Adaptive Layouts

```swift
@Environment(\.horizontalSizeClass) var sizeClass

var body: some View {
    if sizeClass == .compact {
        MobileLayout()
    } else {
        TabletLayout()
    }
}
```

---

## ♿ Accessibility

### Color Contrast

All text meets WCAG AA standards:
- Sage White on Forest Deep: 15.3:1 ✅
- Luxe Gold on Forest Deep: 8.7:1 ✅
- Sage Muted on Forest Mid: 4.6:1 ✅

### Dynamic Type

```swift
Text("Content")
    .font(.forestBody(15))
    .dynamicTypeSize(.xSmall ... .accessibility3)
```

### VoiceOver

```swift
Image(systemName: "leaf.fill")
    .accessibilityLabel("Eco-friendly item")
    .accessibilityHint("This item has a high sustainability score")
```

### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .forestSpring
}
```

---

## 🧩 Component Library Code

### Complete Button Styles

```swift
// Primary Button
public struct ForestPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.forestCaption(16))
            .foregroundColor(.forestDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient.primaryButton
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.forestQuick, value: configuration.isPressed)
    }
}

// Ghost Button
public struct ForestGhostButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.forestCaption(16))
            .foregroundColor(.luxeGold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.medium)
                    .stroke(.luxeGold.opacity(0.5), lineWidth: 1.5)
                    .background(.luxeGold.opacity(configuration.isPressed ? 0.15 : 0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.forestQuick, value: configuration.isPressed)
    }
}
```

---

**Last Updated**: February 2025  
**Version**: 1.0.0
