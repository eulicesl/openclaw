# App Icon Requirements

## Required Sizes

- 1024x1024px - App Store (no alpha channel, no transparency)
- 180x180px - iPhone @3x
- 120x120px - iPhone @2x
- 167x167px - iPad Pro @2x
- 152x152px - iPad @2x
- 76x76px - iPad @1x
- 60x60px - Spotlight @2x
- 40x40px - Spotlight @1x
- 58x58px - Settings @2x
- 29x29px - Settings @1x

## Design Guidelines

The Moltbot icon should:
- Feature the space lobster mascot ("Molty")
- Use bold, recognizable silhouette
- Work well at small sizes
- Avoid text or small details
- Use vibrant colors that stand out
- Match the brand identity at clawd.me
- Follow Apple's app icon guidelines:
  - No transparency
  - Fill entire canvas
  - Avoid placing UI elements
  - Don't add your own rounded corners (iOS adds them)

## Brand Colors

Primary: Moltbot brand purple/blue gradient
Accent: Warm orange/red for energy
Background: Deep space blue or black

## Asset Catalog Structure

```
Assets.xcassets/
  AppIcon.appiconset/
    Contents.json
    icon_1024x1024.png
    icon_180x180.png
    icon_120x120.png
    ... (all required sizes)
```
