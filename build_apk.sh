#!/bin/bash

# Script to build Flutter APK (dev) or App Bundle (release)
# Author: Generated for masterpro_ghidon project

# Function to show usage
show_usage() {
    echo "Usage: $0 [dev|release]"
    echo ""
    echo "Options:"
    echo "  dev     - Build APK for development/testing"
    echo "  release - Build App Bundle for production/Play Store"
    echo ""
    echo "Examples:"
    echo "  $0 dev     # Build APK"
    echo "  $0 release # Build App Bundle"
    echo "  $0         # Default to dev (APK)"
}

# Parse command line arguments
BUILD_TYPE=${1:-dev}

# Validate build type
if [[ "$BUILD_TYPE" != "dev" && "$BUILD_TYPE" != "release" ]]; then
    echo "❌ Invalid build type: $BUILD_TYPE"
    show_usage
    exit 1
fi

# Set build configuration based on type
if [[ "$BUILD_TYPE" == "dev" ]]; then
    BUILD_COMMAND="flutter build apk --release"
    OUTPUT_DIR="build/app/outputs/flutter-apk"
    FILE_EXTENSION="apk"
    BUILD_NAME="APK"
else
    BUILD_COMMAND="flutter build appbundle --release"
    OUTPUT_DIR="build/app/outputs/bundle/release"
    FILE_EXTENSION="aab"
    BUILD_NAME="App Bundle"
fi

echo "🚀 Starting $BUILD_NAME build process..."
echo "📱 Build type: $BUILD_TYPE"
echo "🔨 Command: $BUILD_COMMAND"

# Navigate to the project directory
cd "$(dirname "$0")"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK or App Bundle
echo "🔨 Building $BUILD_NAME..."
eval $BUILD_COMMAND

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ $BUILD_NAME build completed successfully!"
    
    # Check if the output directory exists
    if [ -d "$OUTPUT_DIR" ]; then
        echo "📱 $BUILD_NAME location: $(pwd)/$OUTPUT_DIR"
        
        # List files before renaming
        echo "📋 $BUILD_NAME files found:"
        ls -la "$OUTPUT_DIR"/*.$FILE_EXTENSION 2>/dev/null || echo "No $FILE_EXTENSION files found"
        
        # Rename file with custom name
        echo "📝 Renaming $BUILD_NAME file..."
        
        # Get current date and time for versioning
        CURRENT_DATE=$(date +"%Y%m%d_%H%M%S")
        
        # Custom file name - you can change this to whatever you want
        CUSTOM_FILE_NAME="masterpro_ghidon_${BUILD_TYPE}_v${CURRENT_DATE}.$FILE_EXTENSION"
        
        # Find the original file
        ORIGINAL_FILE=$(find "$OUTPUT_DIR" -name "*.$FILE_EXTENSION" -type f | head -1)
        
        if [ -n "$ORIGINAL_FILE" ]; then
            # Create new file with custom name
            NEW_FILE_PATH="$OUTPUT_DIR/$CUSTOM_FILE_NAME"
            cp "$ORIGINAL_FILE" "$NEW_FILE_PATH"
            
            if [ $? -eq 0 ]; then
                echo "✅ $BUILD_NAME renamed successfully!"
                echo "📱 Original: $(basename "$ORIGINAL_FILE")"
                echo "📱 New name: $CUSTOM_FILE_NAME"
                echo "📱 Full path: $NEW_FILE_PATH"
                
                # Show file size
                FILE_SIZE=$(du -h "$NEW_FILE_PATH" | cut -f1)
                echo "📊 File size: $FILE_SIZE"
            else
                echo "❌ Failed to rename $BUILD_NAME file"
            fi
        else
            echo "❌ No $FILE_EXTENSION file found to rename"
        fi
        
        # Open the folder containing the build output
        echo "📂 Opening $BUILD_NAME folder..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            open "$OUTPUT_DIR"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            xdg-open "$OUTPUT_DIR"
        elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            # Windows
            explorer "$OUTPUT_DIR"
        else
            echo "❓ Unknown OS. Please manually open: $OUTPUT_DIR"
        fi
        
        echo "🎉 Build process completed! $BUILD_NAME folder opened."
        
        # Show additional info for App Bundle
        if [[ "$BUILD_TYPE" == "release" ]]; then
            echo ""
            echo "📦 App Bundle Information:"
            echo "   • File: $CUSTOM_FILE_NAME"
            echo "   • Ready for Play Store upload"
            echo "   • Package: com.hosco.ghidon"
            echo "   • Location: $OUTPUT_DIR"
        fi
    else
        echo "❌ $BUILD_NAME directory not found: $OUTPUT_DIR"
        exit 1
    fi
else
    echo "❌ $BUILD_NAME build failed!"
    exit 1
fi
