#!/bin/bash

# Family Portfolio - Build Script
# Builds Android APK and Web versions

set -e

echo "🏗️  Family Portfolio Build Script"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo "✅ Flutter version: $(flutter --version | head -1)"
echo ""

# Generate code
echo "📦 Generating code..."
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Function to build Android
build_android() {
    echo ""
    echo "${YELLOW}📱 Building Android APK...${NC}"
    flutter build apk --release
    
    if [ $? -eq 0 ]; then
        echo "${GREEN}✅ Android APK built successfully!${NC}"
        echo "📍 Location: build/app/outputs/flutter-apk/app-release.apk"
        echo ""
        
        # Also build app bundle for Play Store
        echo "${YELLOW}📦 Building Android App Bundle...${NC}"
        flutter build appbundle --release
        
        if [ $? -eq 0 ]; then
            echo "${GREEN}✅ Android App Bundle built successfully!${NC}"
            echo "📍 Location: build/app/outputs/bundle/release/app-release.aab"
        fi
    else
        echo "${RED}❌ Android build failed${NC}"
        return 1
    fi
}

# Function to build Web
build_web() {
    echo ""
    echo "${YELLOW}🌐 Building Web...${NC}"
    flutter build web --release
    
    if [ $? -eq 0 ]; then
        echo "${GREEN}✅ Web built successfully!${NC}"
        echo "📍 Location: build/web/"
        echo ""
        echo "To serve locally, run:"
        echo "  python -m http.server 8080 --directory build/web"
        echo ""
        echo "Or deploy to hosting (Netlify, Firebase, etc.)"
    else
        echo "${RED}❌ Web build failed${NC}"
        return 1
    fi
}

# Parse arguments
if [ $# -eq 0 ]; then
    # Build both
    build_android
    build_web
else
    case "$1" in
        android|apk)
            build_android
            ;;
        web)
            build_web
            ;;
        all)
            build_android
            build_web
            ;;
        *)
            echo "Usage: $0 [android|web|all]"
            echo ""
            echo "Options:"
            echo "  android - Build Android APK only"
            echo "  web     - Build Web only"
            echo "  all     - Build both (default)"
            exit 1
            ;;
    esac
fi

echo ""
echo "${GREEN}🎉 Build complete!${NC}"
