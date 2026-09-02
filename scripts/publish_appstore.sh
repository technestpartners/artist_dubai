#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================================"
echo "🚀 Publishing Dubai Artists to Apple App Store (Production)"
echo "========================================================"

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: flutter command not found in PATH."
    exit 1
fi

echo "📦 Running flutter pub get..."
flutter pub get

echo "🍎 Running pod install in ios/..."
cd ios
if command -v bundle &> /dev/null && [ -f "Gemfile" ]; then
    bundle install
    bundle exec pod install
else
    pod install
fi
cd "$PROJECT_ROOT"

echo "🔨 Building iOS IPA..."
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

cd "$PROJECT_ROOT/ios"
if command -v bundle &> /dev/null && [ -f "Gemfile" ]; then
    echo "🚀 Submitting to App Store via Fastlane..."
    bundle exec fastlane release "$@"
else
    fastlane release "$@"
fi

echo "========================================================"
echo "✅ App Store submission process completed!"
echo "========================================================"
