# Happy Place Frontend - Architecture Documentation

> **Last Updated:** 2024-12-19  
> **Purpose:** Living documentation of app architecture, patterns, and implementation guidelines

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [State Management (BLoC Pattern)](#state-management-bloc-pattern)
4. [Navigation](#navigation)
5. [Feature Implementation Guide](#feature-implementation-guide)
6. [Current Features](#current-features)
7. [Services & Utilities](#services--utilities)
8. [Design System](#design-system)
9. [Implementation Checklist](#implementation-checklist)

---

## 🏗️ Architecture Overview

### Pattern: **Feature-Based Architecture + BLoC**

The app follows a **feature-based modular architecture** with **BLoC (Business Logic Component)** pattern for state management.

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (Screens, Widgets, UI Components)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         State Management (BLoC)          │
│  (Events, States, Business Logic)       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│            Data Layer                    │
│  (Models, Repositories, Services)       │
└─────────────────────────────────────────┘
```

### Key Principles

1. **Feature-Based Organization** - Each feature is self-contained
2. **Separation of Concerns** - Clear boundaries between layers
3. **Reusability** - Shared components and services
4. **Scalability** - Easy to add new features
5. **Testability** - Business logic separated from UI

---

## 📁 Project Structure

```
lib/
├── features/                    # Feature modules
│   ├── auth/                   # Authentication feature
│   │   ├── bloc/               # State management
│   │   │   ├── linkedin_auth_bloc.dart
│   │   │   ├── linkedin_auth_event.dart
│   │   │   └── linkedin_auth_state.dart
│   │   ├── model/              # Data models
│   │   │   └── linkedin_user_model.dart
│   │   ├── repository/         # Data layer (future)
│   │   └── view/               # UI screens
│   │       └── login_screen.dart
│   ├── home/                   # Home feature
│   │   ├── view/
│   │   │   └── home_screen.dart
│   │   └── widgets/            # Feature-specific widgets
│   │       ├── animated_map_widget.dart
│   │       └── real_map_widget.dart
│   └── matching/               # Map/Matching feature
│       └── view/
│           └── map_comparison_screen.dart
├── routes/                      # Navigation configuration
│   └── app_router.dart
├── services/                    # Shared services
│   ├── location_service.dart
│   └── location_autocomplete_service.dart
├── utils/                       # Utilities
│   └── linkedin_auth_helper.dart
└── main.dart                    # App entry point
```

### Directory Conventions

- **`features/[feature_name]/`** - Feature module
  - **`bloc/`** - BLoC files (events, states, bloc)
  - **`model/`** - Data models
  - **`repository/`** - Data repositories (API calls)
  - **`view/`** - Screen widgets
  - **`widgets/`** - Feature-specific reusable widgets

- **`services/`** - Cross-feature services (location, API clients)
- **`utils/`** - Helper functions, constants
- **`routes/`** - Navigation configuration

---

## 🔄 State Management (BLoC Pattern)

### BLoC Flow

```
User Action → Event → BLoC → State → UI Update
```

### Example: LinkedIn Authentication

**Event:**
```dart
class LinkedInLoginRequested extends LinkedInAuthEvent {}
```

**BLoC:**
```dart
class LinkedInAuthBloc extends Bloc<LinkedInAuthEvent, LinkedInAuthState> {
  // Handles events, emits states
}
```

**State:**
```dart
class LinkedInAuthSuccess extends LinkedInAuthState {
  final AppLinkedInUser user;
}
```

**Usage in UI:**
```dart
BlocBuilder<LinkedInAuthBloc, LinkedInAuthState>(
  builder: (context, state) {
    if (state is LinkedInAuthSuccess) {
      // Show authenticated UI
    }
  },
)
```

### BLoC Provider Setup

```dart
// In main.dart
BlocProvider(
  create: (context) => LinkedInAuthBloc(),
  child: MaterialApp.router(...),
)
```

### Creating a New BLoC

1. Create event classes in `bloc/[feature]_event.dart`
2. Create state classes in `bloc/[feature]_state.dart`
3. Create BLoC class in `bloc/[feature]_bloc.dart`
4. Register in `main.dart` or feature-specific provider

---

## 🧭 Navigation

### Router Configuration

**File:** `lib/routes/app_router.dart`

```dart
final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: ...),
    GoRoute(path: '/home', builder: ...),
    GoRoute(path: '/matching', builder: ...),
  ],
);
```

### Navigation Methods

```dart
// Navigate to route
context.go('/home');

// Navigate with push (keeps back stack)
context.push('/matching');

// Navigate back
context.pop();
```

### Route Guards (Future)

For protected routes, add redirect logic:
```dart
GoRoute(
  path: '/home',
  redirect: (context, state) {
    // Check auth state
    if (!isAuthenticated) return '/login';
    return null;
  },
)
```

---

## 🎯 Feature Implementation Guide

### Step-by-Step: Adding a New Feature

#### 1. **Create Feature Structure**
```
lib/features/new_feature/
├── bloc/
│   ├── new_feature_event.dart
│   ├── new_feature_state.dart
│   └── new_feature_bloc.dart
├── model/
│   └── new_feature_model.dart
├── repository/
│   └── new_feature_repository.dart (if needed)
├── view/
│   └── new_feature_screen.dart
└── widgets/
    └── new_feature_widget.dart (if needed)
```

#### 2. **Define Models**
```dart
// model/new_feature_model.dart
class NewFeatureModel {
  final String id;
  final String name;
  // ...
}
```

#### 3. **Create BLoC**
```dart
// bloc/new_feature_event.dart
abstract class NewFeatureEvent {}
class LoadData extends NewFeatureEvent {}

// bloc/new_feature_state.dart
abstract class NewFeatureState {}
class NewFeatureInitial extends NewFeatureState {}
class NewFeatureLoading extends NewFeatureState {}
class NewFeatureLoaded extends NewFeatureState {
  final List<NewFeatureModel> data;
}

// bloc/new_feature_bloc.dart
class NewFeatureBloc extends Bloc<NewFeatureEvent, NewFeatureState> {
  // Implementation
}
```

#### 4. **Create Screen**
```dart
// view/new_feature_screen.dart
class NewFeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NewFeatureBloc()..add(LoadData()),
      child: BlocBuilder<NewFeatureBloc, NewFeatureState>(
        builder: (context, state) {
          // UI implementation
        },
      ),
    );
  }
}
```

#### 5. **Add Route**
```dart
// routes/app_router.dart
GoRoute(
  path: '/new-feature',
  builder: (context, state) => const NewFeatureScreen(),
),
```

---

## ✅ Current Features

### 1. **Authentication (LinkedIn OAuth)**

**Location:** `lib/features/auth/`

**Flow:**
1. User lands on `/login`
2. Taps LinkedIn login button
3. OAuth flow opens LinkedIn app/browser
4. User authorizes
5. Returns with user data
6. `LinkedInAuthBloc` emits `LinkedInAuthSuccess`
7. Auto-navigate to `/home`

**Files:**
- `bloc/linkedin_auth_bloc.dart` - Handles auth state
- `model/linkedin_user_model.dart` - User data model
- `view/login_screen.dart` - Login UI

**Native Configuration:**
- **iOS:** `Info.plist` - URL schemes and queries
- **Android:** Handled by `linkedin_login` package

---

### 2. **Home Screen**

**Location:** `lib/features/home/`

**Features:**
- Welcome message with user name
- "Find Flatmates" card → navigates to map

**Files:**
- `view/home_screen.dart` - Main home screen

---

### 3. **Map/Matching Feature**

**Location:** `lib/features/matching/` & `lib/features/home/widgets/`

**Features:**
- Toggle between Real Map and Stylized Map
- Current Location (GPS) or Custom Location
- Location search with autocomplete
- Zoom-based flat filtering
- 5km radius circle (dynamic based on zoom)

**Files:**
- `view/map_comparison_screen.dart` - Map comparison UI
- `widgets/real_map_widget.dart` - OpenStreetMap implementation
- `widgets/animated_map_widget.dart` - Stylized decorative map

**Map Themes:**
- **Current:** CartoDB Dark Matter (dark theme)
- **Available:** OpenStreetMap, CartoDB Light, Stamen themes

**Services:**
- `services/location_service.dart` - GPS & geocoding
- `services/location_autocomplete_service.dart` - Search suggestions

---

## 🔧 Services & Utilities

### Location Service

**File:** `lib/services/location_service.dart`

**Features:**
- Get current GPS location
- Geocode address → coordinates
- Reverse geocode coordinates → address
- Calculate distance between points
- Handle permissions

**Usage:**
```dart
final location = await LocationService().getCurrentLocation();
final coords = await LocationService().getLocationFromAddress('Hyderabad');
```

### Location Autocomplete Service

**File:** `lib/services/location_autocomplete_service.dart`

**Features:**
- Search locations with autocomplete
- Uses OpenStreetMap Nominatim (free)
- Debounced search (500ms)
- Rate limiting (1 req/sec)

**Future:** Will be replaced with Google Places API for better accuracy

---

## 🎨 Design System

### Colors

**Primary:**
- Purple Gradient: `Color(0xFF667eea)` → `Color(0xFF764ba2)`
- Dark Background: `Color(0xFF1A1A1A)`
- Dark Card: `Color(0xFF2A2A2A)`

**Match Colors:**
- High Match (80%+): `Color(0xFF4CAF50)` (Green)
- Medium Match (50-79%): `Color(0xFFFF9800)` (Orange)
- Low Match (<50%): `Color(0xFFE57373)` (Light Red)

### Typography

- **Headings:** Material 3 default
- **Body:** System default
- **Map Subtitle:** Georgia, italic

### Spacing

- Standard padding: `16.0`
- Card padding: `20.0`
- Section spacing: `32.0`

---

## 📝 Implementation Checklist

When implementing a new feature from Figma:

### Pre-Implementation
- [ ] Analyze Figma design (layout, colors, components)
- [ ] Identify reusable components
- [ ] Plan state management (BLoC events/states)
- [ ] Plan navigation flow
- [ ] Check if services/utilities needed

### Implementation
- [ ] Create feature directory structure
- [ ] Define models
- [ ] Create BLoC (events, states, bloc)
- [ ] Create screen/widget
- [ ] Add route to `app_router.dart`
- [ ] Register BLoC provider (if needed)
- [ ] Implement UI matching Figma design
- [ ] Add navigation logic
- [ ] Handle loading/error states

### Post-Implementation
- [ ] Test navigation flow
- [ ] Test state management
- [ ] Verify UI matches design
- [ ] Update this documentation
- [ ] Check for lint errors

---

## 🔄 Updating This Document

**When to update:**
- Adding a new feature
- Changing architecture patterns
- Adding new services/utilities
- Changing navigation structure
- Adding design system elements

**How to update:**
1. Add new section or update existing
2. Update "Current Features" section
3. Update "Implementation Checklist" if needed
4. Update "Last Updated" date

---

## 📚 Dependencies

### Core
- `flutter_bloc: ^8.1.3` - State management
- `go_router: ^13.2.0` - Navigation

### Authentication
- `linkedin_login: ^3.1.3` - LinkedIn OAuth

### Maps & Location
- `flutter_map: ^6.1.0` - Map rendering
- `latlong2: ^0.9.0` - Coordinates
- `geolocator: ^11.0.0` - GPS location
- `geocoding: ^3.0.0` - Address ↔ Coordinates

### HTTP
- `http: ^1.2.0` - API calls

---

## 🚀 Future Enhancements

### Planned
- [ ] Google Places API integration (autocomplete)
- [ ] Backend API integration
- [ ] User profile management
- [ ] Flat listing creation/management
- [ ] Real-time matching algorithm
- [ ] Chat/messaging feature

### Architecture Improvements
- [ ] Repository pattern implementation
- [ ] API service layer
- [ ] Local storage (shared_preferences/hive)
- [ ] Error handling strategy
- [ ] Loading states standardization
- [ ] Route guards for protected routes

---

## 📞 Notes

- This is a **living document** - update as you build
- Follow the established patterns for consistency
- Keep features modular and self-contained
- Document any deviations from standard patterns

---

**Last Updated:** 2024-01-13  
**Maintained By:** Development Team

> **Note:** See [README.md](README.md) for current development phase and roadmap.

