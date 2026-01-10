#!/bin/bash

# Script to generate app icons from logo.png
# Author: Generated for masterpro_ghidon project

echo "🎨 Starting app icon generation..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Check if logo.png exists
if [ ! -f "assets/logo.png" ]; then
    echo "❌ Logo file not found: assets/logo.png"
    echo "Please make sure you have a logo.png file in the assets folder"
    exit 1
fi

echo "📱 Found logo file: assets/logo.png"

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate app icons
echo "🎨 Generating app icons for all platforms..."
flutter pub run flutter_launcher_icons:main

# Check if generation was successful
if [ $? -eq 0 ]; then
    echo "✅ App icons generated successfully!"
    echo ""
    echo "📱 Generated icons for:"
    echo "   • Android (various sizes)"
    echo "   • iOS (various sizes)"
    echo "   • Web (favicon and PWA icons)"
    echo "   • Windows (48px)"
    echo "   • macOS (various sizes)"
    echo ""
    echo "🎉 Icon generation completed!"
else
    echo "❌ App icon generation failed!"
    exit 1
fi
