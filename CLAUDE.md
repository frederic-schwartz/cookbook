# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter recipe book application ("Un livre de recettes") written in French. The app appears to be in early development with a basic structure for categorizing recipes into French culinary categories.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app in development mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter test` - Run unit tests
- `flutter analyze` - Run static analysis and linting
- `flutter clean` - Clean build cache

### Icon Generation
- `flutter pub run flutter_launcher_icons:main` - Generate app icons for Android and iOS from `assets/icon/app_icon.png`

### Testing
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file
- Note: Current widget test is outdated (expects counter app behavior but app uses HomeScreen)

## Project Structure

### Main Application Files
- `lib/main.dart` - Entry point, sets up MaterialApp with "Cookbook" title and deep purple theme
- `lib/home_screen.dart` - Main screen (currently placeholder implementation)
- `lib/category_fr.json` - French recipe categories and subcategories data structure

### Key Architecture Details
- Uses Material Design with ColorScheme.fromSeed
- Categories are structured in French: Entrées, Plats principaux, Accompagnements, Desserts, etc.
- Each category has multiple subcategories (e.g., "Viande", "Poisson & fruits de mer" under "Plats principaux")
- Assets stored in `assets/images/` directory
- App icon configuration in pubspec.yaml points to `assets/icon/app_icon.png`

### Dependencies
- Core Flutter SDK (^3.8.1)
- `cupertino_icons` for iOS-style icons
- `flutter_launcher_icons` for automated icon generation
- `flutter_lints` for code quality

## Development Notes

The app is currently in French language and designed for recipe organization. The category structure suggests a comprehensive cooking app with sections for appetizers, mains, sides, desserts, drinks, and basic recipes.

When working with this codebase:
- The JSON structure in `category_fr.json` defines the recipe categorization system
- The HomeScreen is currently a placeholder and needs implementation
- Icon changes require running the flutter_launcher_icons command after updating the source image
- The widget test needs updating to match the actual app structure (currently tests counter behavior but app uses HomeScreen)