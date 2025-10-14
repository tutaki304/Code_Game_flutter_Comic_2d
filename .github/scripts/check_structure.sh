#!/bin/bash

# Script to check Flutter project structure compliance
# Checks if the project follows the clean architecture structure

set -e

echo "🔍 Checking Flutter project structure..."

# Function to check if directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo "❌ Missing required directory: $1"
        return 1
    else
        echo "✅ Found: $1"
        return 0
    fi
}

# Function to check if file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ Missing required file: $1"
        return 1
    else
        echo "✅ Found: $1"
        return 0
    fi
}

# Function to check forbidden patterns
check_forbidden_patterns() {
    local dir=$1
    local pattern=$2
    local message=$3
    
    if find "$dir" -name "$pattern" 2>/dev/null | head -1 | grep -q .; then
        echo "❌ $message"
        find "$dir" -name "$pattern" 2>/dev/null || true
        return 1
    fi
    return 0
}

echo ""
echo "📁 Checking core directory structure..."

# Check main entry points
check_file "lib/main.dart"
check_file "lib/app.dart"

# Check core structure
check_directory "lib/core"
check_directory "lib/core/constants"
check_directory "lib/core/utils"
check_directory "lib/core/error"
check_directory "lib/core/theme"

# Check data layer
check_directory "lib/data"
check_directory "lib/data/models"
check_directory "lib/data/datasources"
check_directory "lib/data/repositories_impl"

# Check domain layer
check_directory "lib/domain"
check_directory "lib/domain/entities"
check_directory "lib/domain/repositories"
check_directory "lib/domain/usecases"

# Check presentation layer
check_directory "lib/presentation"
check_directory "lib/presentation/screens"
check_directory "lib/presentation/widgets"
check_directory "lib/presentation/providers"
check_directory "lib/presentation/routes"

# Check services
check_directory "lib/services"

echo ""
echo "🚫 Checking for forbidden patterns..."

# Check for forbidden imports in domain layer
if [ -d "lib/domain" ]; then
    echo "Checking domain layer for clean architecture violations..."
    
    # Domain should not import Flutter or data layer
    if grep -r "import 'package:flutter" lib/domain/ 2>/dev/null; then
        echo "❌ Domain layer should not import Flutter packages"
        exit 1
    fi
    
    if grep -r "import.*data/" lib/domain/ 2>/dev/null; then
        echo "❌ Domain layer should not import data layer"
        exit 1
    fi
    
    if grep -r "import.*presentation/" lib/domain/ 2>/dev/null; then
        echo "❌ Domain layer should not import presentation layer"
        exit 1
    fi
    
    echo "✅ Domain layer is clean"
fi

# Check for proper file naming conventions
echo ""
echo "📝 Checking naming conventions..."

# Check for snake_case file names
find lib/ -name "*.dart" | while read file; do
    filename=$(basename "$file" .dart)
    if [[ ! "$filename" =~ ^[a-z][a-z0-9_]*$ ]]; then
        echo "❌ File should use snake_case: $file"
        exit 1
    fi
done

echo "✅ All files follow snake_case naming convention"

# Check for proper directory structure
echo ""
echo "🗂️ Checking directory organization..."

# Check if widgets are properly organized
if [ -d "lib/presentation/widgets" ]; then
    # Look for common widget patterns
    widget_count=$(find lib/presentation/widgets -name "*.dart" | wc -l)
    if [ "$widget_count" -gt 10 ]; then
        echo "💡 Consider organizing widgets into subdirectories (common/, forms/, cards/, etc.)"
    fi
fi

# Check if screens are properly organized
if [ -d "lib/presentation/screens" ]; then
    screen_count=$(find lib/presentation/screens -name "*.dart" | wc -l)
    if [ "$screen_count" -gt 5 ]; then
        echo "💡 Consider organizing screens into feature-based subdirectories"
    fi
fi

echo ""
echo "✅ Project structure validation completed successfully!"
echo ""
echo "📋 Structure Summary:"
echo "   ├── lib/"
echo "   │   ├── main.dart & app.dart ✅"
echo "   │   ├── core/ (constants, utils, error, theme) ✅"
echo "   │   ├── data/ (models, datasources, repositories_impl) ✅"
echo "   │   ├── domain/ (entities, repositories, usecases) ✅"
echo "   │   ├── presentation/ (screens, widgets, providers, routes) ✅"
echo "   │   └── services/ ✅"
echo ""
echo "🎉 Your project follows Flutter Clean Architecture guidelines!"