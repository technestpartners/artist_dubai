#!/bin/sh

# ==============================================================================
# Xcode Cloud CI Post-Clone Script for Flutter iOS (Artist Dubai)
# ==============================================================================
# Runs automatically on Apple's Xcode Cloud servers right after clone.
# Installs Flutter SDK, fetches dependencies, and runs pod install.
# ==============================================================================

set -e

echo "🚀 [Xcode Cloud] Starting ci_post_clone setup for Flutter..."
echo "📂 CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"
echo "📂 HOME: $HOME"

# Navigate to the project root
cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "📂 Working directory: $(pwd)"

# ----------------------------------------------------------------
# 1. Install Flutter SDK (stable channel)
# ----------------------------------------------------------------
echo "⬇️  [1/4] Installing Flutter SDK (stable)..."
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
else
  echo "⚡ Flutter already cached — skipping clone."
fi

export PATH="$PATH:$FLUTTER_HOME/bin"

# Verify Flutter
flutter --version

# ----------------------------------------------------------------
# 2. Pre-cache iOS engine artifacts
# ----------------------------------------------------------------
echo "⚙️  [2/4] Pre-caching Flutter iOS artifacts..."
flutter precache --ios

# ----------------------------------------------------------------
# 3. Install Flutter dependencies
# ----------------------------------------------------------------
echo "📦 [3/4] Running flutter pub get..."
flutter pub get

# ----------------------------------------------------------------
# 4. Install CocoaPods dependencies
# ----------------------------------------------------------------
echo "🍎 [4/4] Running pod install..."
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HOMEBREW_NO_AUTO_UPDATE=1

# Use system Ruby to avoid brew permission issues on Xcode Cloud
gem install cocoapods --user-install 2>/dev/null || true
export PATH="$PATH:$(ruby -e 'puts Gem.user_bin_dir')"

cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install --repo-update

echo "✅ [Xcode Cloud] ci_post_clone completed! Ready for Xcode archive."
exit 0
