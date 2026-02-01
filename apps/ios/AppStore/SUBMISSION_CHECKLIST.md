# App Store Submission Checklist

## Pre-Submission Requirements

### 1. App Store Connect Setup
- [ ] Create app record in App Store Connect
- [ ] Set bundle identifier: `bot.molt.ios`
- [ ] Configure app metadata (name, subtitle, description)
- [ ] Upload app icon (1024x1024px, no transparency)
- [ ] Add screenshots for all required device sizes
- [ ] Set primary category: Productivity
- [ ] Set content rating: 4+

### 2. Build & Code Signing
- [ ] Archive build with valid distribution certificate
- [ ] Enable automatic code signing or manual with distribution profile
- [ ] Set correct development team (Y5PE65HELJ)
- [ ] Validate build in Xcode before upload
- [ ] Upload build to App Store Connect via Xcode or Transporter

### 3. Required Documentation
- [ ] Privacy Policy URL: https://docs.molt.bot/privacy
- [ ] Support URL: https://docs.molt.bot/support
- [ ] Marketing URL: https://clawd.me
- [ ] Privacy Manifest (PrivacyInfo.xcprivacy) included
- [ ] App Store metadata completed (metadata.json)

### 4. Privacy & Permissions
- [ ] All permission usage descriptions are clear and accurate
- [ ] NSLocalNetworkUsageDescription explains Bonjour usage
- [ ] NSCameraUsageDescription explains photo/video capture
- [ ] NSMicrophoneUsageDescription explains Voice Wake feature
- [ ] NSSpeechRecognitionUsageDescription explains on-device recognition
- [ ] NSLocationWhenInUseUsageDescription explains location sharing
- [ ] NSLocationAlwaysAndWhenInUseUsageDescription for background location
- [ ] Privacy Manifest declares all data collection
- [ ] Privacy Manifest declares tracking status (false)

### 5. Review Information
Provide test account details and instructions for reviewers:

**Test Gateway Setup:**
1. Reviewers need access to a running Moltbot gateway
2. Provide test gateway credentials:
   - Host: [test-gateway-host]
   - Port: 18789
   - Token: [test-token]
   - Password: [test-password]
3. Or provide instructions to run gateway locally

**Demo Account:**
- Instance ID: [test-instance-id]
- Expected behavior: App connects to gateway, chat works, voice features available

**Important Notes for Reviewers:**
- This app requires a self-hosted gateway to function
- Without gateway access, the app will show "No Gateways Found"
- All features are privacy-focused and run on user's infrastructure
- No third-party analytics or tracking

### 6. Content & Features
- [ ] All features are functional and stable
- [ ] No placeholder content or "Coming Soon" features
- [ ] App doesn't crash or hang
- [ ] All buttons and UI elements work correctly
- [ ] Onboarding flow is complete
- [ ] Error states are handled gracefully
- [ ] App handles network errors appropriately
- [ ] Background modes work as expected (audio for Voice Wake)

### 7. Apple Human Interface Guidelines (HIG)
- [ ] Uses native iOS UI patterns
- [ ] Supports all required iPhone sizes
- [ ] Supports all required iPad sizes
- [ ] Supports Dark Mode
- [ ] Supports Dynamic Type (text sizing)
- [ ] Includes proper accessibility labels
- [ ] VoiceOver support implemented
- [ ] Haptic feedback for key actions
- [ ] Status bar handling correct
- [ ] Safe area handling correct

### 8. Technical Requirements
- [ ] Minimum deployment target: iOS 18.0
- [ ] Swift 6.0 with strict concurrency enabled
- [ ] No compiler warnings
- [ ] No deprecated API usage
- [ ] Background modes declared correctly (audio)
- [ ] UIBackgroundModes includes "audio" for Voice Wake
- [ ] Bonjour services declared: _moltbot-gw._tcp
- [ ] No private API usage

### 9. App Review Guidelines Compliance
- [ ] 1.1 Objectionable Content - No offensive content
- [ ] 1.2 User Safety - Privacy focused, no tracking
- [ ] 2.1 Performance - App is stable and responsive
- [ ] 2.3 Accurate Metadata - Description matches functionality
- [ ] 2.5 Software Requirements - iOS 18.0+, follows HIG
- [ ] 3.1 In-App Purchase - No IAP (free app)
- [ ] 3.2 Other Business Model - No monetization
- [ ] 4.0 Design - Follows Apple HIG
- [ ] 5.1 Privacy - Comprehensive privacy policy, no tracking
- [ ] 5.2 Intellectual Property - Original content
- [ ] 5.3 Gaming, Gambling, Lotteries - N/A
- [ ] 5.4 VPN Apps - N/A (uses local network, not VPN)

### 10. Export Compliance
- [ ] App doesn't use encryption (uses standard SSL/TLS only)
- [ ] Or: App uses encryption but qualifies for exemption
- [ ] Export compliance documentation provided if needed

### 11. Final Testing
- [ ] Test on physical device (not just simulator)
- [ ] Test onboarding flow from fresh install
- [ ] Test all permission requests
- [ ] Test gateway discovery
- [ ] Test manual gateway connection
- [ ] Test Voice Wake feature
- [ ] Test Talk Mode
- [ ] Test Chat interface
- [ ] Test Canvas rendering
- [ ] Test Camera capture
- [ ] Test Location services
- [ ] Test background behavior
- [ ] Test app in Low Power Mode
- [ ] Test with VoiceOver enabled
- [ ] Test with Reduced Motion enabled

## Common Rejection Reasons & Solutions

### 1. Requires Gateway to Function
**Issue:** App is useless without gateway access  
**Solution:** Provide test gateway credentials to reviewers in "Review Notes"

### 2. Permission Usage Unclear
**Issue:** Permission descriptions not specific enough  
**Solution:** All descriptions now clearly explain feature purpose

### 3. Crashes or Doesn't Work
**Issue:** App crashes when gateway not available  
**Solution:** Graceful error handling implemented, clear empty states

### 4. Privacy Policy Missing
**Issue:** Privacy policy URL doesn't work  
**Solution:** Ensure https://docs.molt.bot/privacy is accessible

### 5. Metadata Doesn't Match
**Issue:** App Store description doesn't match actual features  
**Solution:** Updated metadata.json with accurate description

## Submission Process

1. **Build Archive**
   ```bash
   cd apps/ios
   xcodegen generate
   xcodebuild archive -project Moltbot.xcodeproj -scheme Moltbot
   ```

2. **Validate Archive**
   - Open Organizer in Xcode
   - Select archive
   - Click "Validate App"
   - Fix any issues

3. **Upload to App Store Connect**
   - Click "Distribute App"
   - Select "App Store Connect"
   - Choose automatic signing
   - Upload

4. **Configure App Store Connect**
   - Add build to version
   - Complete all metadata
   - Add screenshots
   - Submit for review

5. **Monitor Review Status**
   - Check App Store Connect daily
   - Respond to any messages from Review Team within 24 hours
   - Be prepared to provide additional information

## Post-Approval

- [ ] Announce release on social media
- [ ] Update documentation with App Store link
- [ ] Monitor crash reports and user feedback
- [ ] Plan for next update with improvements
