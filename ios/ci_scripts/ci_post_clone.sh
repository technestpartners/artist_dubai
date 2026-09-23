#!/bin/sh

# ==============================================================================
# Xcode Cloud CI Post-Clone Script for Flutter iOS
# ==============================================================================
# This script is executed automatically by Xcode Cloud immediately after cloning
# the repository. It installs the Flutter SDK, precaches iOS build tools, fetches
# dependencies, and installs CocoaPods.
# ==============================================================================

# Fail script if any subcommand fails
set -e

echo "🚀 [Xcode Cloud] Starting ci_post_clone setup for Flutter..."

# Navigate to the root of the cloned repository
cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "📂 Project root: $(pwd)"

# 1. Install Flutter SDK
echo "⬇️ [1/4] Cloning Flutter SDK (stable branch)..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter installation
flutter --version

# 2. Pre-cache iOS engine artifacts
echo "⚙️ [2/4] Pre-caching Flutter iOS engine artifacts..."
flutter precache --ios

# 3. Fetch Flutter dependencies
echo "📦 [3/4] Running flutter pub get..."
flutter pub get

# 4. Install CocoaPods and run pod install
echo "🍎 [4/4] Setting up CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

cd ios
echo "📥 Running pod install..."
pod install

echo "✅ [Xcode Cloud] ci_post_clone completed successfully! Ready for Xcode archive & build."
exit 0
