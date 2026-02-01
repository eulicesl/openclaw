#!/bin/bash
set -euo pipefail

# Moltbot iOS - Build for App Store Release
# This script generates the Xcode project, validates it, and creates an archive

echo "🚀 Building Moltbot for App Store Release"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCHEME="Moltbot"
CONFIGURATION="Release"
ARCHIVE_PATH="${PWD}/build/Moltbot.xcarchive"
EXPORT_PATH="${PWD}/build/export"

# Step 1: Check dependencies
echo "📋 Checking dependencies..."
if ! command -v xcodegen &> /dev/null; then
    echo -e "${RED}❌ xcodegen not found. Install with: brew install xcodegen${NC}"
    exit 1
fi

if ! command -v swiftlint &> /dev/null; then
    echo -e "${YELLOW}⚠️  swiftlint not found. Install with: brew install swiftlint${NC}"
fi

if ! command -v swiftformat &> /dev/null; then
    echo -e "${YELLOW}⚠️  swiftformat not found. Install with: brew install swiftformat${NC}"
fi

echo -e "${GREEN}✅ Dependencies OK${NC}"
echo ""

# Step 2: Generate Xcode project
echo "🔨 Generating Xcode project..."
xcodegen generate

if [ ! -f "Moltbot.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Failed to generate Xcode project${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Project generated${NC}"
echo ""

# Step 3: Run linters (if available)
if command -v swiftlint &> /dev/null; then
    echo "🔍 Running SwiftLint..."
    if ! swiftlint lint --config .swiftlint.yml; then
        echo -e "${YELLOW}⚠️  SwiftLint found issues (non-blocking)${NC}"
    else
        echo -e "${GREEN}✅ SwiftLint passed${NC}"
    fi
    echo ""
fi

# Step 4: Clean build folder
echo "🧹 Cleaning build folder..."
rm -rf build
mkdir -p build

echo -e "${GREEN}✅ Build folder ready${NC}"
echo ""

# Step 5: Build archive
echo "📦 Creating archive..."
echo "   Scheme: ${SCHEME}"
echo "   Configuration: ${CONFIGURATION}"
echo ""

xcodebuild archive \
    -project Moltbot.xcodeproj \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Manual \
    | xcpretty || true

if [ ! -d "${ARCHIVE_PATH}" ]; then
    echo -e "${RED}❌ Archive creation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive created: ${ARCHIVE_PATH}${NC}"
echo ""

# Step 6: Validate archive
echo "✅ Validating archive..."

# Check for common issues
if [ ! -f "${ARCHIVE_PATH}/Info.plist" ]; then
    echo -e "${RED}❌ Archive Info.plist missing${NC}"
    exit 1
fi

# Extract bundle ID
BUNDLE_ID=$(plutil -extract ApplicationProperties.CFBundleIdentifier raw "${ARCHIVE_PATH}/Info.plist")
echo "   Bundle ID: ${BUNDLE_ID}"

# Extract version
VERSION=$(plutil -extract ApplicationProperties.CFBundleShortVersionString raw "${ARCHIVE_PATH}/Info.plist")
BUILD=$(plutil -extract ApplicationProperties.CFBundleVersion raw "${ARCHIVE_PATH}/Info.plist")
echo "   Version: ${VERSION} (${BUILD})"

echo -e "${GREEN}✅ Archive validated${NC}"
echo ""

# Step 7: Export for App Store (optional)
echo "📤 Exporting for App Store..."
echo "   This requires valid distribution certificates and provisioning profiles"
echo ""

# Create export options plist
cat > build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>Y5PE65HELJ</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
</dict>
</plist>
EOF

if xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist build/ExportOptions.plist \
    2>&1 | tee build/export.log; then
    echo -e "${GREEN}✅ Export successful: ${EXPORT_PATH}${NC}"
    echo ""
    echo "📱 IPA Location: ${EXPORT_PATH}/${SCHEME}.ipa"
else
    echo -e "${YELLOW}⚠️  Export failed. This is expected without distribution certificates.${NC}"
    echo -e "${YELLOW}   You can upload the archive manually from Xcode Organizer.${NC}"
fi

echo ""
echo "🎉 Build process complete!"
echo ""
echo "Next steps:"
echo "  1. Open Xcode Organizer: Window > Organizer"
echo "  2. Select the archive"
echo "  3. Click 'Distribute App'"
echo "  4. Choose 'App Store Connect'"
echo "  5. Follow the upload wizard"
echo ""
echo "Or use this command to open the archive in Xcode:"
echo "  open ${ARCHIVE_PATH}"
echo ""
