# Moltbot for iOS

Native iOS app for Moltbot, your personal AI assistant. Built with Swift 6.0 and SwiftUI, following Apple Human Interface Guidelines.

## Features

- **Voice Wake** - Hands-free voice activation with on-device speech recognition
- **Talk Mode** - Continuous conversation with your AI assistant
- **Gateway Discovery** - Automatic discovery via Bonjour (mDNS)
- **Chat Interface** - Clean, native messaging experience
- **Canvas Mode** - Rich visual interactions and web content rendering
- **Camera Integration** - Capture photos and videos on request
- **Location Services** - Share your location when needed
- **Privacy First** - All data stays on your gateway, no third-party tracking

## Requirements

- iOS 18.0 or later
- iPhone or iPad
- Xcode 16.0+ (for development)
- Swift 6.0
- A running Moltbot gateway on your local network

## Development Setup

### Install Dependencies
```bash
brew install xcodegen swiftlint swiftformat
```

### Generate Xcode Project
```bash
cd apps/ios
xcodegen generate
open Moltbot.xcodeproj
```

### Build and Run
From the repo root:
```bash
pnpm ios:build    # Build the app
pnpm ios:run      # Build and launch in simulator
```

Or in Xcode: `Cmd+R`

## Project Structure

```
apps/ios/
├── Sources/
│   ├── Camera/           # Camera capture functionality
│   ├── Chat/             # Chat UI and gateway transport
│   ├── Gateway/          # Gateway connection and discovery
│   ├── Location/         # Location services
│   ├── Model/            # App state and business logic
│   ├── Onboarding/       # First-time user experience
│   ├── Screen/           # Canvas/screen rendering
│   ├── Settings/         # Settings and preferences
│   ├── Status/           # Status indicators
│   ├── UI/               # Reusable UI components
│   ├── Voice/            # Voice Wake and Talk Mode
│   └── ClawdbotApp.swift # App entry point
├── Tests/                # Unit tests
├── AppStore/             # App Store metadata and assets
└── project.yml           # XcodeGen configuration
```

## Shared Packages

- `../shared/MoltbotKit` - Shared types, constants, and UI components
- `../../Swabble` - Speech wake-word detection framework

## Gateway Connection

### Automatic Discovery (Recommended)
The app uses Bonjour to discover gateways on your local network automatically.

### Manual Configuration
Enter gateway host and port manually in Settings for non-standard network setups.

## Permissions

The app requires:
- **Microphone** - Voice Wake and Talk Mode
- **Speech Recognition** - On-device speech processing
- **Local Network** - Gateway discovery via Bonjour
- **Camera** - Optional, for photo/video capture
- **Location** - Optional, for location sharing

All permissions include clear usage descriptions.

## Building for App Store

### Quick Build
```bash
cd apps/ios
chmod +x scripts/build-release.sh
./scripts/build-release.sh
```

### Manual Process
1. Open Xcode Organizer: `Window > Organizer`
2. Select archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Follow upload wizard

See [AppStore/SUBMISSION_CHECKLIST.md](AppStore/SUBMISSION_CHECKLIST.md) for complete submission guide.

## Testing

### Unit Tests
```bash
# In Xcode: Cmd+U
# Or via CLI:
xcodebuild test -project Moltbot.xcodeproj -scheme Moltbot \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Key Test Areas
- Onboarding flow
- Gateway discovery and connection
- Voice Wake and Talk Mode
- Chat interface
- Accessibility (VoiceOver, Dynamic Type)
- Dark mode

## Accessibility

Full support for:
- VoiceOver screen reader
- Dynamic Type (text sizing)
- Reduced Motion
- Voice Control
- High Contrast modes

## Troubleshooting

**Gateway Not Found**
- Ensure gateway is on same network
- Check firewall settings
- Try manual connection with IP address

**Voice Wake Not Working**
- Check microphone permission
- Verify "Voice Wake" enabled in Settings
- Test with "clawd" or "claude" wake words

**Build Errors**
- Clean: `Cmd+Shift+K`
- Regenerate: `xcodegen generate`
- Update tools: `brew upgrade xcodegen swiftlint`

## Fastlane

```bash
brew install fastlane
cd apps/ios
fastlane lanes
```

See `fastlane/SETUP.md` for App Store Connect authentication and upload lanes.

## Links

- [Documentation](https://docs.molt.bot)
- [GitHub](https://github.com/steipete/moltbot)
- [Website](https://clawd.me)
- [Privacy Policy](https://docs.molt.bot/privacy)

---

Built with the Moltbot community
