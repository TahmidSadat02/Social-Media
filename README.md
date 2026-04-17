# PixoGram - Flutter Social Media App

A complete Flutter social media application with clean architecture, built with Provider state management and Supabase backend.

## Project Structure

```
lib/
├── main.dart                         # App entry point
├── app.dart                          # App configuration & routing
├── supabase_config.dart             # Supabase initialization
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Color palette
│   │   └── app_text_styles.dart     # Text styles
│   ├── utils/
│   │   ├── time_ago.dart            # Timestamp formatting
│   │   └── validators.dart          # Form validators
│   └── widgets/
│       ├── app_button.dart          # Reusable button
│       ├── app_text_field.dart      # Reusable text field
│       ├── avatar_widget.dart       # User avatar
│       └── loading_widget.dart      # Loading indicator
├── features/
│   ├── auth/ (login, signup)
│   ├── feed/ (posts, compose)
│   ├── profile/ (user profiles, following)
│   ├── messages/ (direct messaging)
│   └── search/ (user search)
└── models/ (data models with toJson/fromJson)
```

## Features Implemented

✅ **Authentication** - Sign up, login, auto-redirect, logout
✅ **Feed** - Post creation, like/unlike, pull-to-refresh
✅ **Profile** - View profiles, follow/unfollow, edit bio
✅ **Messages** - Direct messaging, conversation list
✅ **Search** - Find users by username
✅ **Navigation** - Bottom tab navigation (Home, Search, Messages, Profile)

## Getting Started

### Quick Start

```bash
cd pixogram
flutter pub get
flutter run
```

### Database Setup

Copy and run the SQL from `MESSAGES_TABLE.sql` in your Supabase dashboard.

## Supabase Tables

- **profiles** - User information (username, bio, avatar)
- **posts** - User posts with content and images
- **likes** - Post likes (ready for comment likes too)
- **follows** - Follow relationships
- **messages** - Direct messages between users (create with SQL file)

## State Management

Provider pattern with ChangeNotifier controllers:
- AuthController - Auth & user state
- FeedController - Posts & feed
- ProfileController - Profiles & follows
- MessagesController - Direct messaging
- SearchController - User search

## Design

Dark theme (#0a0a0f background, #e8ff57 accent)
- Clean, minimal UI focused on functionality
- TODO: Design improvements planned for future

## What's Next

- [ ] Real-time message subscriptions
- [ ] Image uploads
- [ ] Comments
- [ ] Notifications
- [ ] Explore/Discover
- [ ] Stories
- [ ] DM read receipts

## Building

```bash
flutter build apk --release    # Android
flutter build ios --release    # iOS
flutter build web --release    # Web
```

For full documentation, see inline code comments marked with TODO.

