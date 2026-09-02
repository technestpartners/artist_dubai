#!/usr/bin/env bash
set -e

# ==============================================================================
# Local TestFlight Deployment Script for Dubai Artists (Flutter iOS)
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================================"
echo "🚀 Building & Uploading Dubai Artists to TestFlight"
echo "========================================================"

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: flutter command not found in PATH."
    exit 1
fi

# 1. Fetch dependencies
echo "📦 Running flutter pub get..."
flutter pub get

# 2. Update CocoaPods
echo "🍎 Running pod install in ios/..."
cd ios
if command -v bundle &> /dev/null && [ -f "Gemfile" ]; then
    bundle install
    bundle exec pod install
else
    pod install
fi
cd "$PROJECT_ROOT"

# 3. Build IPA
echo "🔨 Building iOS IPA..."
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# 4. Upload using Fastlane or altool
cd "$PROJECT_ROOT/ios"
if command -v bundle &> /dev/null && [ -f "Gemfile" ]; then
    echo "🚀 Uploading to TestFlight via Fastlane..."
    bundle exec fastlane beta "$@"
else
    echo "⚠️ Bundler not found. Attempting fastlane directly..."
    fastlane beta "$@"
fi

echo "========================================================"
echo "✅ TestFlight deployment process completed!"
echo "========================================================"
