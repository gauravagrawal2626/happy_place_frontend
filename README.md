# MyHappyPlace - Frontend

A Flutter application for finding compatible flatmates based on lifestyle preferences and personality matching.

---

## Environment variables

Copy `.env.example` to `.env` in the project root and set values as needed. **Do not commit `.env`** (it is gitignored).

| Variable                 | Required | Description |
|--------------------------|----------|-------------|
| `PLACES_API_KEY`         | No       | Google Places API key for **iOS**. If unset, location autocomplete falls back to Nominatim (OSM). |
| `PLACES_API_KEY_ANDROID` | No       | Google Places API key for **Android**. If unset, Android also uses Nominatim. Recommended when you have an Android-restricted key. |
| `LINKEDIN_CLIENT_ID`     | Yes\*    | LinkedIn OAuth Client ID from `https://www.linkedin.com/developers/apps`. Used by the `linkedin_login` package. |
| `LINKEDIN_CLIENT_SECRET` | Yes\*    | LinkedIn OAuth Client Secret. **Never commit this.** Only stored locally in `.env`. |
| `LINKEDIN_REDIRECT_URI`  | Yes\*    | Redirect URI configured in the LinkedIn app. Must match the value in LinkedIn’s OAuth 2.0 settings. |
| `POSTHOG_API_CLIENT_KEY` | No       | PostHog project API key. If unset, analytics is a no-op. |
| `POSTHOG_HOST`           | No       | PostHog ingest host (e.g. `https://us.i.posthog.com`). Defaults to US cloud if unset. |

- **Lister Places autocomplete:** No `types=address` (broader POI/geocode like Maps), `components=country:in` + `region=in` for India, up to 10 suggestions. Selected chip shows Google **`formatted_address`** (same source as pin text in many Maps flows), not only parsed `locality`/`city`.

\*Required only if you want LinkedIn login to work in that environment. The app will fail LinkedIn auth if these are missing.

### Analytics (PostHog)

- **Bootstrap:** `main()` loads `.env`, then `bootstrapAnalytics()` in [`lib/core/analytics/analytics_bootstrap.dart`](lib/core/analytics/analytics_bootstrap.dart) calls `Posthog().setup` when `POSTHOG_API_CLIENT_KEY` is set; otherwise [`NoOpAnalyticsProvider`](lib/core/analytics/noop_analytics_provider.dart).
- **API:** Use [`AnalyticsFacade`](lib/core/analytics/analytics_facade.dart) (`screen`, `button`, `track`, `identifyUser`, `logOutButtonTap`) via `context.read<AnalyticsFacade>()`.
- **Screen views:** [`AnalyticsNavigatorObserver`](lib/core/analytics/analytics_navigator_observer.dart) is registered on `GoRouter` in [`lib/main.dart`](lib/main.dart). Event/property/screen names live under [`lib/core/analytics/`](lib/core/analytics/).
- **Button clicks:** Primary taps call `AnalyticsFacade.button(...)` with names from [`analytics_button_names.dart`](lib/core/analytics/analytics_button_names.dart) and `screenName` from [`analytics_screen_names.dart`](lib/core/analytics/analytics_screen_names.dart). Pilot flows: login, onboarding Next/Submit, preferences Save; extended: phone/OTP, location, map/list CTAs, finding-matches, invites, profile modal, account modal, flat save.
- **Verify in PostHog:** With `POSTHOG_API_CLIENT_KEY` set, open **Activity → Live events** (or Events), filter by `button_clicked` and properties `button_name` / `screen_name`. Trigger a known action (e.g. LinkedIn tap on login) and confirm the event appears within a few seconds.
- **Native:** Android/iOS disable PostHog auto-init (`AUTO_INIT=false`) so Dart owns initialization.

---

## Backend configuration

API calls use the `ApiConfig.baseUrl` in `lib/core/config/api_config.dart`.

- **Dev backend (remote)**: `static const String baseUrl = 'http://13.126.87.95:8000';`
- **Local backend (example, commented in code)**: `// static const String baseUrl = 'http://127.0.0.1:8000';`

To switch environments, change `baseUrl` and rebuild the app.

---

## 📋 Project Phases

### ✅ Phase 0: Initial Setup (Completed)
- [x] Project structure setup
- [x] LinkedIn OAuth integration (basic)
- [x] Map implementation (OpenStreetMap)
- [x] Location services
- [x] Architecture documentation

---

### ✅ Phase 1: Basic Login Screen with BLoC (Completed)

**Completed:** 2024-01-13

**Goal:** Create a clean login screen with LinkedIn authentication and basic BLoC pattern (no local storage yet)

#### Tasks:
- [x] Update `login_screen.dart` with new design matching Figma Frame e1
- [x] Create Auth BLoC structure
  - [x] `auth_event.dart` (LinkedInLoginRequested, LinkedInLoginSuccess, LinkedInLoginFailure)
  - [x] `auth_state.dart` (AuthInitial, AuthLoading, AuthSuccess, AuthFailure)
  - [x] `auth_bloc.dart` (lightweight, no persistence)
- [x] Create Auth models
  - [x] `auth_response.dart` (API response structure)
  - [x] `app_user.dart` (User data model)
- [x] Update app routing
  - [x] Add route guards (basic)
  - [x] Navigate to onboarding after login
- [x] **No local storage** - Kept simple for Phase 1

#### Deliverables:
- ✅ **AppScaffold** - Reusable background wrapper (turquoise)
- ✅ **AppColors** - Centralized color constants
- ✅ Clean login screen UI using AppScaffold
- ✅ Working LinkedIn OAuth flow
- ✅ Basic BLoC state management (lightweight, no persistence)
- ✅ Navigation to onboarding screen after login
- ✅ Placeholder onboarding screen for Phase 2

#### Files Created/Modified:
- `lib/shared/theme/app_colors.dart` - NEW (centralized color constants)
- `lib/shared/widgets/app_scaffold.dart` - NEW (**reusable background wrapper - first component**)
- `lib/features/auth/model/auth_response.dart` - NEW (API response model)
- `lib/features/auth/model/app_user.dart` - NEW (user data model)
- `lib/features/auth/view/login_screen.dart` - UPDATED (uses AppScaffold & AppColors)
- `lib/features/onboarding/view/onboarding_screen.dart` - NEW (placeholder using AppScaffold)
- `lib/routes/app_router.dart` - UPDATED (added /onboarding route)

#### Testing:
- ✅ Login screen displays with turquoise background
- ✅ LinkedIn OAuth button works
- ✅ Navigation to onboarding screen after login
- ✅ No linter errors

---

### ✅ Phase 2: Onboarding Flow (Completed + Enhanced)

**Completed:** 2025-01-15 | **Enhanced:** 2025-01-17

**Goal:** Create the complete onboarding flow (Frames 2-7) with reusable components and **real API integration**

#### 🆕 Enhanced Features (2025-01-17):
- **Text Variations**: Dynamic text that changes based on previous answers or user role
- **Sub-Options**: Expandable/inline child options for complex questions
- **Role Tracking**: USER_TYPE question determines LISTER or SEEKER role
- **{name} Placeholder**: Personalized greetings with user's name

#### Tasks:
- [x] Create reusable components
  - [x] `AppButton` (primary action button with outline variant)
  - [x] `ChipButton` (chip/tag selection)
  - [x] `ImageOptionCard` (image/icon options with S3/CDN PNG + local asset support)
  - [x] `ProgressIndicatorWidget` (linear progress bar)
  - [x] `QuestionHeader` (tertiary/primary/secondary text hierarchy)
  - [x] `TextInputField` (text input with validation)
- [x] Create onboarding data models
  - [x] `question_model.dart` (Question, QuestionOption, UiConfig, OnboardingAnswer)
- [x] Create OnboardingRepository for real API
  - [x] GET `/api/questions/onboarding` - Fetch questions
  - [x] POST `/api/users/onboard` - Submit answers
- [x] Create Onboarding BLoC
  - [x] `onboarding_event.dart` (LoadQuestions, AnswerQuestion, NextQuestion, PreviousQuestion, SubmitOnboarding)
  - [x] `onboarding_state.dart` (OnboardingInitial, OnboardingLoading, OnboardingLoaded, OnboardingSubmitting, OnboardingCompleted, OnboardingError)
  - [x] `onboarding_bloc.dart` (question navigation, answer validation, mock data loading)
- [x] Create question type widgets
  - [x] `text_input_question.dart` (TEXT_INPUT type)
  - [x] `text_mcq_question.dart` (TEXT_MCQ type - gender circles, list cards, chips)
  - [x] `image_mcq_question.dart` (IMAGE_MCQ type - S3 images with fallback icons)
  - [x] `slider_question.dart` (SLIDER type - Frame 3 Age)
- [x] Create main onboarding screen
  - [x] `onboarding_screen.dart` (single reusable screen for all questions)
  - [x] Dynamic question rendering based on type
  - [x] Progress tracking with visual indicator
  - [x] Back/Next/Submit navigation
  - [x] Answer validation (required fields)
  - [x] Error handling with SnackBar feedback

#### Enhanced API Structure:
```json
{
  "questions": [
    {
      "_id": "abc123",
      "field_name": "GENDER",
      "tertiary_text": "Hey, {name}",
      "primary_text": "What's your gender?",
      "secondary_text": "Pick what suits you the best.",
      "type": "TEXT_MCQ",
      "options": [
        {"id": "opt_male", "text": "Male"},
        {"id": "opt_female", "text": "Female"},
        {"id": "opt_non_binary", "text": "Non-binary"}
      ],
      "is_required": true,
      "order": 1
    },
    {
      "_id": "abc124",
      "field_name": "AGE",
      "type": "SLIDER",
      "ui_config": {"min": 18, "max": 60, "step": 1, "default": 25},
      "text_variations": {
        "based_on": "GENDER",
        "variations": {
          "opt_male": {"tertiary_text": "Okay, handsome."},
          "opt_female": {"tertiary_text": "Okay, cutie."}
        }
      }
    },
    {
      "_id": "abc125",
      "field_name": "USER_TYPE",
      "type": "TEXT_MCQ",
      "options": [
        {
          "id": "opt_have_flat",
          "text": "I already have a flat",
          "is_parent": true,
          "sub_options": [
            {"id": "opt_replacement", "text": "Looking for a replacement"},
            {"id": "opt_flatmate", "text": "Looking for a flatmate"}
          ]
        }
      ],
      "ui_config": {"expandable": true, "expanded_title": "Oh, cool. Tell me more."},
      "matching_config": {
        "updates_role": true,
        "role_mapping": {"opt_replacement": "LISTER", "opt_flatmate": "LISTER"}
      }
    }
  ],
  "user_role": "SEEKER"
}
```

#### Key Enhanced Features:

| Feature | Field | Usage |
|---------|-------|-------|
| **Text Variations** | `text_variations.based_on` | Change text based on previous answer or role |
| **Sub-Options** | `options[].is_parent`, `sub_options[]` | Expandable child options |
| **Role Mapping** | `matching_config.role_mapping` | Map answer to LISTER/SEEKER role |
| **Inline Sub-Options** | `ui_config.show_sub_options_inline` | Show sub-options below grid |
| **Expandable Accordion** | `ui_config.expandable` | Accordion-style for USER_TYPE |
| **Name Placeholder** | `{name}` in text | Replaced with user's first name |

#### Implementation Details:
- **Single Screen, Multiple Question Types**: 
  - The `onboarding_screen.dart` is a single reusable screen that dynamically renders different question types
  - No separate screens for each question - questions are navigated programmatically
  - Question type determines the widget used (TextInputQuestion, TextMcqQuestion, ImageMcqQuestion)

- **Adaptive Rendering for TEXT_MCQ**:
  - **Chips** for multi-select (Frame 4 - Priorities, up to 3 selections)
  - **2x2 Grid** for single select with ≤4 options (Frames 2, 6, 7 - Gender, Dietary, Smoking)
  - **Icons** automatically assigned based on option text (gender, food, smoking icons)

- **Special Cases**:
  - "In a society" chip has special pink styling (`AppColors.chipPink`)
  - Multi-select questions enforce max selection limit (e.g., max 3 priorities)
  - Age question uses numeric keyboard

- **Mock API Response**:
  - Located in `lib/features/onboarding/data/mock_questions.dart`
  - Matches backend API structure exactly
  - 6 questions covering all Figma frames (2-7)

#### Deliverables:
- ✅ **Complete onboarding flow** (Frames 2-7)
- ✅ **Reusable component library** (7 new components)
- ✅ **Working question navigation** (back/next/submit)
- ✅ **Mock data integration** (6 sample questions)
- ✅ **Answer collection** (in-memory via BLoC)
- ✅ **Answer validation** (required field checking)
- ✅ **Progress tracking** (visual progress bar)
- ✅ **Error handling** (SnackBar feedback)

#### Files Created (21 new files):
**Reusable Components (7)**:
- `lib/shared/widgets/app_button.dart`
- `lib/shared/widgets/chip_button.dart`
- `lib/shared/widgets/square_option_card.dart`
- `lib/shared/widgets/icon_option_card.dart`
- `lib/shared/widgets/progress_indicator_widget.dart`
- `lib/shared/widgets/question_header.dart`
- `lib/shared/widgets/text_input_field.dart`

**Onboarding Feature (14)**:
- `lib/features/onboarding/data/mock_questions.dart`
- `lib/features/onboarding/model/question_model.dart`
- `lib/features/onboarding/bloc/onboarding_event.dart`
- `lib/features/onboarding/bloc/onboarding_state.dart`
- `lib/features/onboarding/bloc/onboarding_bloc.dart`
- `lib/features/onboarding/widgets/text_input_question.dart`
- `lib/features/onboarding/widgets/text_mcq_question.dart`
- `lib/features/onboarding/widgets/image_mcq_question.dart`
- `lib/features/onboarding/view/onboarding_screen.dart` (REPLACED placeholder)

#### Testing:
- [x] ✅ No linter errors
- [ ] Run the app and navigate through all 6 onboarding questions
- [ ] Verify progress indicator updates correctly (1/6 → 2/6 → ... → 6/6)
- [ ] Test multi-select (priorities - max 3 selections enforced)
- [ ] Test single-select (gender, dietary, smoking with 2x2 grid)
- [ ] Test text input (age with numeric keyboard)
- [ ] Test icon grid (weekend activities, 4-column grid)
- [ ] Test back button functionality (disabled on first question)
- [ ] Test answer validation (Next button disabled if required field empty)
- [ ] Verify submit completes and navigates to home screen

---

### ✅ Phase 3: Complete Auth Implementation with Persistence (Completed)

**Completed:** 2025-01-15

**Goal:** Integrate real API, add JWT token management, and implement local storage

#### Tasks:
- [x] Create storage layer
  - [x] `storage_keys.dart` (centralized storage keys)
  - [x] `secure_storage.dart` (flutter_secure_storage wrapper)
  - [x] Save/retrieve JWT token
  - [x] Save/retrieve user data
  - [x] Onboarding completion tracking
- [x] Update Auth Repository
  - [x] `saveAuthData()` - persist auth response after login
  - [x] `restoreSession()` - restore from secure storage on app launch
  - [x] `logout()` - clear all auth data
  - [x] `setOnboardingCompleted()` - mark onboarding done
- [x] Create AppBloc for app-level state
  - [x] `app_event.dart` (AppInitialized, AppUserAuthenticated, AppOnboardingCompleted, AppUserLoggedOut)
  - [x] `app_state.dart` (AppLoading, AppUnauthenticated, AppAuthenticated)
  - [x] `app_bloc.dart` (session restore, auth state management)
- [x] Update LinkedInAuthBloc
  - [x] Save auth data to secure storage after successful login
- [x] Update routing with auth guards
  - [x] Splash screen during initialization
  - [x] Route guards based on auth state
  - [x] Route guards based on onboarding completion
  - [x] Automatic redirection based on state
- [x] Update main.dart
  - [x] Initialize AppBloc on app start
  - [x] Shared AuthRepository instance
  - [x] Dynamic router based on AppState
- [x] Update screens to dispatch AppBloc events
  - [x] LoginScreen → AppUserAuthenticated
  - [x] OnboardingScreen → AppOnboardingCompleted

#### Auth Flow:
```
App Launch
  ↓
AppBloc dispatches AppInitialized
  ↓
Check JWT in SecureStorage
  ↓
YES → Restore session → AppAuthenticated state
  ↓                      ↓
  ↓                      onboardingCompleted: true → /home
  ↓                      onboardingCompleted: false → /onboarding
  ↓
NO → AppUnauthenticated → /login
  ↓
LinkedIn OAuth → Backend API
  ↓
Save to SecureStorage → AppUserAuthenticated
  ↓
Check onboarding_completed
  ↓
false → /onboarding → Submit → AppOnboardingCompleted → /home
  ↓
true → /home
```

#### Files Created (6 new files):
**Storage Layer (2)**:
- `lib/core/storage/storage_keys.dart` - Centralized storage key constants
- `lib/core/storage/secure_storage.dart` - Secure storage wrapper

**App-Level BLoC (3)**:
- `lib/core/bloc/app_event.dart` - App-level events
- `lib/core/bloc/app_state.dart` - App-level states
- `lib/core/bloc/app_bloc.dart` - App-level state management

#### Files Modified (5 files):
- `lib/features/auth/repository/auth_repository.dart` - Added persistence methods
- `lib/features/auth/bloc/linkedin_auth_bloc.dart` - Save auth data after login
- `lib/features/auth/view/login_screen.dart` - Dispatch AppUserAuthenticated
- `lib/features/onboarding/view/onboarding_screen.dart` - Dispatch AppOnboardingCompleted
- `lib/routes/app_router.dart` - Dynamic routing with auth guards
- `lib/main.dart` - AppBloc initialization, shared repository

#### Dependencies Added:
- `flutter_secure_storage: ^10.0.0` - Secure storage for tokens

#### Deliverables:
- ✅ Complete authentication flow with persistence
- ✅ JWT token management (save/restore/clear)
- ✅ Secure storage integration
- ✅ Real API integration (already done in Phase 2)
- ✅ Route guards based on auth & onboarding status
- ✅ Splash screen during initialization
- ✅ Logout functionality

#### Testing:
- [ ] Test login flow end-to-end
- [ ] Test token persistence across app restarts
- [ ] Test logout flow
- [ ] Test route guards (unauthenticated → /login)
- [ ] Test route guards (authenticated without onboarding → /onboarding)
- [ ] Test route guards (authenticated with onboarding → /home)

---

### 📍 Phase 4: Location & Matching Screen (Planned)

**Goal:** After onboarding, get user's preferred location and show potential flatmate matches on a map

#### Figma Frames:
- **Frame 8**: Location Input - "Let's see if there are people like you within your proximity"
- **Frame 10**: Loading - "Finding your happy place" with spinner
- **Frame 11**: Map with flatmate markers showing match % (35%, 65%, 95%)

#### Tasks:
- [ ] Create Location Input Screen (`location_screen.dart`)
  - [ ] Text field with location icon for address input
  - [ ] "Skip" button (uses current GPS location as fallback)
  - [ ] OpenStreetMap autocomplete (→ Google Places later)
- [ ] Create Loading Screen (`matching_loading_screen.dart`)
  - [ ] Animated spinner
  - [ ] "Finding your happy place" text
- [ ] Update Map/Matches Screen (reuse existing `map_comparison_screen.dart`)
  - [ ] Custom markers with match percentage badges
  - [ ] Filter chips (Vegetarian, Non-Smoker, More)
  - [ ] Header: "X potential flatmates found within 5 kms"
  - [ ] "Add Flat Details" button
  - [ ] "Modify Flatmate Preferences" button
- [ ] Create Matching BLoC
  - [ ] Fetch matches from API (mock data initially)
  - [ ] Filter logic

#### Map & Location Architecture:
| Component | Library/Service | Notes |
|-----------|-----------------|-------|
| Map Display | `flutter_map` + OpenStreetMap | Free, no API key |
| Autocomplete | OpenStreetMap Nominatim (now) → Google Places (later) | Better accuracy with Google |
| Geocoding | `geocoding` package | Uses native platform (free) |
| GPS Location | `geolocator` | Device GPS |

#### Initial Implementation:
- **Mock data** for matches (no backend integration initially)
- Backend API integration will be done after Phase 5

---

### ✅ Phase 5: Flat Requirements & Add Flat (Completed)

**Completed:** 2025-01-25

**Goal:** Allow users to specify flat requirements OR add their own flat listing

#### User Flows:

**Flow A: Seeker (Looking for a flat)**
1. User specifies flat requirements (budget, location preferences, amenities)
2. Requirements saved to profile
3. Matches shown based on requirements

**Flow B: Lister (Has a flat to share)**
1. User adds flat details (location, rent, photos, amenities)
2. Flat listing created
3. Potential flatmates shown based on compatibility

#### Completed Tasks:
- [x] Single unified Flat Requirements Screen (handles both SEEKER and LISTER flows)
- [x] Create Flat Requirements Screen (Seeker flow)
  - [x] Budget range slider (Max Rent, Max Deposit)
  - [x] Flat size preferences
  - [x] Bedroom type, washroom type
  - [x] Listing type preferences
  - [x] Amenities checklist (Required Facilities)
- [x] Create Add Flat Screen (Lister flow)
  - [x] Flat location (from DRAFT flat data)
  - [x] Rent amount slider
  - [x] Security deposit slider
  - [x] Amenities checklist (Facilities Available)
  - [x] Photo upload widget (backend flag controlled - `show_image_upload`)
  - [x] Description field (backend flag controlled - `show_description`)
- [x] Create FlatBloc for state management
  - [x] Load questions from API
  - [x] Form field updates
  - [x] Question answer management
  - [x] Photo upload handling (mock S3 for now)
  - [x] Submit data based on role
- [x] API integration
  - [x] `GET /api/questions/flat-listing?is_lister={bool}` - Get questions with existing data
  - [x] `POST /api/flats` - Create/update flat listing (LISTER)
  - [x] `POST /api/users/flat-requirements` - Save seeker requirements (SEEKER)
- [x] Backend flags for UI control
  - [x] `show_image_upload` - Controls photo upload widget visibility
  - [x] `show_description` - Controls description field visibility
- [x] Role-based question fetching (always based on user's actual role)
- [x] End-to-end testing

#### Remaining (Deferred):
- [ ] S3 photo upload integration (currently mocked, to be done later)

#### Key Features:
- **Unified Screen**: Single screen adapts based on user role (SEEKER vs LISTER)
- **Backend-Driven UI**: Photo upload and description widgets controlled by backend flags
- **Pre-population**: Existing data loaded from API and pre-filled in form
- **Progress Tracking**: Visual progress indicator for answered questions
- **Form Validation**: Required field validation before submission
- **Location Display**: Shows flat location for LISTERs with DRAFT data

#### Files Created/Modified:
- `lib/features/flat_requirements/view/flat_requirements_screen.dart` - Main screen
- `lib/features/flat_requirements/bloc/flat_bloc.dart` - State management
- `lib/features/flat_requirements/bloc/flat_event.dart` - Events
- `lib/features/flat_requirements/bloc/flat_state.dart` - States
- `lib/features/flat_requirements/model/flat_question_model.dart` - Models
- `lib/features/flat_requirements/model/flat_request_model.dart` - Request/Response models
- `lib/features/flat_requirements/repository/flat_repository.dart` - API integration

---

### 🔗 Phase 6: Matches API Integration (After Phase 5)

**Goal:** Replace mock match data with real backend API

#### Matches API (backend contract) – one endpoint for both SEEKER and LISTER

- **Endpoint:** `GET /api/flats/matches` (same for both roles; backend uses auth to decide response type). **Base URL:** `ApiConfig.baseUrl` + path (see [`lib/core/config/api_config.dart`](lib/core/config/api_config.dart) — e.g. `http://<host>:8000/api/flats/matches`).
- **Filtered matches:** `POST /api/flats/matches` with JSON body (`filters`, optional `location_overrides`) + same query params as GET. See `MatchingRepository.postMatches()`.
- **Caller:** Seeker Map / Lister List / filters — [`MatchingRepository`](lib/features/matching/repository/matching_repository.dart), constant [`kDefaultMatchesLimit`](lib/features/matching/model/match_model.dart) (**50** until pagination UI).
- **Query params sent (typical):** `radius_km` (e.g. `5.0`), **`limit`** (default **50**), `skip` when paginating. Optional: `flat_id`, `latitude`, `longitude`, `listing_type`, `min_rent`, `max_rent`. Backend infers role from auth; LISTER can auto-select latest flat when `flat_id` is omitted.
- **Response:** `{ results: [...], total, skip, limit, type: "flats" | "seekers", locations_searched? }`.
- **Public profile:** In both response types, **`user_id`** is the field used for fetching public profile (`GET /api/users/{user_id}/public-profile`).

**SEEKER (`type: "flats"`):**

- Each item in `results` is a flat. **Required:** **`user_id`** (string) = user id of the lister/owner of the flat. If missing, profile modal is skipped.
- Other fields (frontend parses): `_id`, `title`, `location`, `match_score`, `distance_km`, `rent`, `formatted_address` or `address`, `owner_name`, `image_url`, etc.

**LISTER (`type: "seekers"`):**

- Each item in `results` is a seeker. **Required:** **`user_id`** (string) = seeker’s user id, **`flat_id`** (string) = lister’s flat id.
- Other fields (frontend parses): `full_name`, `match_score`, `age`, `tagline`, `image_url`.

#### Tasks:
- [x] Matching Repository – `GET /api/flats/matches`
- [ ] Backend: SEEKER response – include **`user_id`** (lister) per flat; LISTER response – include **`user_id`** (seeker), **`flat_id`** per seeker
- [x] Profile modal (tap marker / card) – uses `user_id` for public profile and invite flow (both roles)
- [ ] Add messaging/contact flow

#### Requests API (Frontend API Guide)

- **POST /api/requests** – Frontend payload matches the doc:
  - **SEEKER:** `{ "flat_id": "...", "message": "..." }` (see `CreateRequestPayloadSeeker`, `_createRequestBody()` in profile modal).
  - **LISTER:** `{ "flat_id": "...", "seeker_id": "...", "message": "..." }`.
- **GET /api/requests** – Optional query `status`. Response: `sent`, `received` (each item has `_id`, `flat_id`, `status`, `person_details` { `user_id`, `full_name` }, `button_info` { `text`, `action`, `enabled` }), `sent_total`, `received_total`, `total`. Used by Invites screen (`RequestsRepository.getRequests()`).
- **PUT** accept/reject/cancel/complete – Path from `request_status.buttons[].action`; body optional per doc.
- **Account modal:** "View your profile" opens profile modal (public profile API for current user, `showBackButton: true`). "Invite sent/accept details" navigates to `/account/invites` (InvitesScreen); row tap opens profile modal with that user’s profile (back button).
- **500 "Failed to send request"** – Returned by the backend; frontend sends the correct payload. Check backend logs (e.g. flat_id not found, duplicate request, validation, DB error).

---

## 🏗️ Architecture Overview

### State Management: BLoC Pattern

```
User Action → Event → BLoC → State → UI Update
```

### Project Structure

```
lib/
├── config/                    # Configuration (API URLs, etc.)
├── shared/                    # Shared components
│   ├── storage/              # Local storage (Phase 3)
│   ├── widgets/              # Reusable widgets (Phase 2)
│   └── theme/                # Colors, themes (Phase 2)
├── services/                  # API services (Phase 3)
├── features/                  # Feature modules
│   ├── auth/                 # Authentication (Phase 1 & 3)
│   ├── onboarding/           # Onboarding (Phase 2)
│   └── home/                 # Home screen
└── routes/                    # Navigation
```

---

## 📱 Screens & Navigation

### Current Flow
1. **Login Screen** → LinkedIn OAuth → Navigate to Onboarding
2. **Onboarding Screen** → Questions (Frames 2-7) → Navigate to Home
3. **Home Screen** → Main app functionality

### Future Flow (Phase 3)
1. **Splash Screen** → Check auth → Login or Home
2. **Login Screen** → Store JWT → Check onboarding
3. **Onboarding Screen** → Submit to API → Update local storage → Home
4. **Home Screen** → Protected routes

---

## 🎨 Design System (Phase 2)

### Colors
- **Background:** `#4FD1C5` (Turquoise/Cyan)
- **Primary Button:** `#1A202C` (Dark)
- **Chip Selected:** `#1A202C` (Dark)
- **Chip Unselected:** `#FFFFFF` (White)
- **Text Dark:** `#1A202C`
- **Text Light:** `#FFFFFF`

### Components
- `AppScaffold` - Base screen with turquoise background
- `AppButton` - Primary action button
- `ChipButton` - Selectable chip/tag
- `SquareOptionCard` - 2x2 grid card
- `IconOptionCard` - Icon-based option
- `ProgressIndicator` - Progress tracking
- `QuestionHeader` - Question title
- `TextInputField` - Text input

---

## 🔧 Dependencies

### Current
- `flutter_bloc: ^8.1.3` - State management
- `go_router: ^13.2.0` - Navigation
- `linkedin_login: ^3.1.3` - LinkedIn OAuth
- `flutter_map: ^6.1.0` - Map rendering
- `geolocator: ^11.0.0` - GPS location
- `geocoding: ^3.0.0` - Address ↔ Coordinates
- `http: ^1.2.0` - API calls

### Phase 3 Additions
- `shared_preferences: ^2.2.0` - Local storage

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart 3.0+
- Xcode (for iOS)
- Android Studio (for Android)
- Node.js (for MCP/Figma integration)

### Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd happy_place_frontend
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **iOS Setup**
```bash
cd ios
pod install
cd ..
```

4. **Run the app**
```bash
flutter run
```

### LinkedIn OAuth Setup
1. Create LinkedIn app at https://www.linkedin.com/developers/apps
2. Add redirect URI: `com.happyplace://` (iOS/Android)
3. Update credentials in `lib/utils/linkedin_auth_helper.dart`

---

## 📝 API Documentation

### Authentication

**POST /api/auth/login**
```json
Request:
{
  "provider": "linkedin",
  "auth_token": "<LINKEDIN_OAUTH_TOKEN>"
}

Response:
{
  "token": "eyJhbGc...",
  "user_id": "693d68239...",
  "email": "user@example.com",
  "role": "SEEKER",
  "full_name": "John Doe",
  "onboarding_completed": false
}
```

### Onboarding

**GET /api/questions/onboarding**
```
Headers: Authorization: Bearer <JWT>
Returns: List of onboarding questions
```

**POST /api/users/onboard**
```json
Headers: Authorization: Bearer <JWT>
Body:
{
  "answers": [
    {
      "question_id": "...",
      "option_ids": ["opt_male"]
    }
  ]
}
```

---

## 🧪 Testing

### Phase 1 Testing
- Manual LinkedIn login
- Basic navigation flow

### Phase 2 Testing
- Question navigation
- Answer selection
- Mock data rendering
- Component reusability

### Phase 3 Testing
- End-to-end auth flow
- API integration
- Token persistence
- Error scenarios

---

## 📚 Resources

- [Architecture Documentation](ARCHITECTURE.md)
- [Figma Design](https://www.figma.com/design/cZSGjov2UGOfhHcgK6f7fC/MyHappyPlace)
- [Backend API Docs](http://localhost:8000/docs)

---

## 👥 Team

- Development Team

---

## 📄 License

[License Type]

---

---

### Match Question Filters (Added)

Dynamic question-based filter chips on match screens, replacing the old hardcoded Vegetarian/Non-Smoker/More chips.

#### Flow:
- **Screen init**: `LoadMatches` (GET) and `LoadMatchFilters` (GET) fire in **parallel**
- **Filters loaded**: chips populate from `question_filters`, defaults from `current_value`
- **User taps chip**: mini bottom sheet with that question's options (supports sub-options)
- **User selects option**: sheet closes, chip highlights, `PostFilteredMatches` fires (POST /api/flats/matches)
- **User returns from Flatmate Preference / Add Flat Details**: both APIs re-fire, filter state resets

#### API Endpoints:
- `GET /api/flats/match-filters` — returns `question_filters[]` with options, sub-options, `current_value`
- `POST /api/flats/matches` — body `{ filters: [{id, value}] }` + query params (`radius_km`, etc.)

#### Files Created:
- `lib/features/matching/model/filter_model.dart` — `MatchFiltersResponse`, `QuestionFilter`, `FilterItem`
- `lib/features/matching/widgets/match_filter_chips.dart` — shared horizontal chip bar
- `lib/features/matching/widgets/question_filter_sheet.dart` — mini bottom sheet per question

#### Files Modified:
- `lib/core/config/api_config.dart` — added `matchFilters` endpoint
- `lib/core/network/api_client.dart` — `post()` now accepts `queryParams`
- `lib/features/matching/repository/matching_repository.dart` — added `getMatchFilters()`, `postMatches()`
- `lib/features/matching/bloc/matching_event.dart` — added `LoadMatchFilters`, `PostFilteredMatches`
- `lib/features/matching/bloc/matching_state.dart` — added `MatchFiltersLoaded`
- `lib/features/matching/bloc/matching_bloc.dart` — handlers for new events, cached `filterConfig`
- `lib/features/matching/view/lister_list_screen.dart` — dynamic chips, reload on return
- `lib/features/matching/view/seeker_map_screen.dart` — dynamic chips, reload on return

---

### Seeker Location Filter (Added)

Ephemeral location filter for seekers on the match screen. Allows toggling saved preferred locations and adding new areas via search — sent as `location_overrides` in POST /matches. Nothing persists to DB.

#### Flow:
- **Screen init**: `LoadMatchFilters` returns `location_filter.saved_locations[]` for seekers
- **Location chip appears**: first saved location name as label (seeker-only)
- **User taps chip**: bottom sheet shows saved locations as toggleable chips (all active by default)
- **User taps "Add area"**: search field appears, calls `GET /api/locations/areas/search?q=...&city=...`; popular areas loaded from `GET /api/locations/areas?city=...` as fallback
- **User applies**: `PostFilteredMatches` fires with `location_overrides[]` (saved use `location_id`, new use `lat`/`lng`)
- **User resets**: no overrides sent → backend uses saved locations (default behavior)
- **User leaves screen**: all ephemeral locations discarded, filter resets

#### API Endpoints:
- `GET /api/flats/match-filters` — now includes `location_filter` for seekers
- `POST /api/flats/matches` — body `{ filters: [...], location_overrides: [{location_id, radius_km} | {lat, lng, radius_km, name}] }`
- `GET /api/locations/areas?city=...` — browse popular areas
- `GET /api/locations/areas/search?q=...&city=...` — search areas by name

#### Files Created:
- `lib/features/matching/widgets/location_filter_sheet.dart` — bottom sheet with saved location toggles + area search

#### Files Modified:
- `lib/features/matching/model/filter_model.dart` — added `SavedLocation`, `LocationFilter`, `LocationOverride`; updated `MatchFiltersResponse`
- `lib/features/matching/bloc/matching_event.dart` — added `locationOverrides` to `PostFilteredMatches`
- `lib/features/matching/repository/matching_repository.dart` — added `locationOverrides` to `postMatches()`, `browseAreas()`, `searchAreas()`
- `lib/features/matching/bloc/matching_bloc.dart` — passes `locationOverrides` through
- `lib/core/config/api_config.dart` — added `locationAreasSearch` endpoint
- `lib/features/matching/widgets/match_filter_chips.dart` — optional location chip (seeker-only)
- `lib/features/matching/view/seeker_map_screen.dart` — location state, chip tap, sheet callback, POST with overrides

---

### Google Sign-In (Added)

Google OAuth login alongside existing LinkedIn login. Uses `google_sign_in` package (native SDK) — not Firebase. Backend receives a Google ID token and verifies it server-side.

#### Flow:
- User taps "Continue with Google" on the login screen
- `google_sign_in` SDK presents the native Google sign-in sheet
- On success, the SDK returns an **ID token** (via `serverClientId` = Web client ID)
- Frontend sends `{ "provider": "google", "auth_token": "<ID_TOKEN>" }` to `POST /api/auth/login`
- Backend verifies the ID token (signature, aud, iss, exp), maps to user, returns JWT + user info
- BLoC saves auth data and navigates based on `onboarding_completed`

#### Env Variables:
- `GOOGLE_WEB_CLIENT_ID` — Web OAuth client ID (used as `serverClientId` in Flutter to obtain ID token)
- `GOOGLE_IOS_CLIENT_ID` — iOS OAuth client ID (registered in Google Cloud Console for the iOS bundle)

#### Google Cloud Console Setup:
- **iOS client**: Bundle ID = `com.example.happyPlaceFrontend`
- **Android client (debug)**: Package name = `com.example.happyPlaceFrontend`, SHA-1 from `~/.android/debug.keystore`
- **Android client (release)**: Same package name, SHA-1 from `~/happyplace-release.jks`
- **Web client**: Used for `serverClientId` — no origins/redirects needed for mobile-only

#### Files Modified:
- `pubspec.yaml` — added `google_sign_in: ^6.2.1`
- `lib/core/config/env_config.dart` — added `googleWebClientId`, `googleIosClientId`
- `ios/Runner/Info.plist` — added reversed iOS client ID URL scheme
- `lib/features/auth/repository/auth_repository.dart` — added `loginWithGoogle()` method
- `lib/features/auth/bloc/linkedin_auth_event.dart` — added `GoogleLoginRequested` event
- `lib/features/auth/bloc/linkedin_auth_state.dart` — added `GoogleAuthSuccess` state
- `lib/features/auth/bloc/linkedin_auth_bloc.dart` — added `_onGoogleLoginRequested` handler
- `lib/features/auth/view/login_screen.dart` — added Google button + handler + GoogleAuthSuccess listener

#### Android Signing (for Google OAuth):
- `android/app/build.gradle.kts` — configured release signing from `key.properties`
- `android/key.properties` — contains keystore path/password (gitignored)
- `.gitignore` — added `android/key.properties` and `*.jks`

#### Backend Requirement:
- `POST /api/auth/login` must handle `provider: "google"` — verify ID token using Google's public keys, check `aud` matches Web client ID, `iss` is `accounts.google.com`, token not expired. Map Google email/sub to user, return JWT.

---

### Push Notifications — FCM (Added)

Firebase Cloud Messaging integration for receiving push notifications on Android and iOS.

#### Firebase Setup (Manual):
- Firebase project: `happyplace-logging`
- Android: `google-services.json` in `android/app/` (gitignored)
- iOS: `GoogleService-Info.plist` in `ios/` (gitignored, added to Xcode project)
- APNs Auth Key (.p8) uploaded to Firebase Console (covers both dev and prod)
- iOS capabilities: Push Notifications + Background Modes (Remote notifications)

#### Notification Handling by App State:
- **Foreground** (app open): `onMessage` listener shows in-app SnackBar with "View" action
- **Background** (app minimized): OS shows notification; tap handled by `onMessageOpenedApp` → navigates
- **Terminated** (app closed): OS shows notification; `getInitialMessage()` on next launch → navigates

#### Token Lifecycle:
- FCM token fetched after user authenticates → `POST /api/notifications/register-token` with `{ "fcm_token": "...", "platform": "android|ios" }` (backend infers user from JWT)
- Token refresh listened to and re-registered automatically
- On logout: FCM token deleted from device + local storage cleaned up

#### Navigation (from notification tap):
- Backend sends `data.screen` field: `"seeker_home"` → `/map/seeker`, `"lister_home"` → `/list/lister`
- Default fallback: `/map/seeker`

#### Backend Payload Format:
```json
{
  "notification": { "title": "...", "body": "..." },
  "data": {
    "type": "new_match | invite_received | ...",
    "screen": "seeker_home | lister_home",
    "entity_id": "optional_resource_id"
  },
  "android": { "priority": "high" },
  "apns": { "headers": { "apns-priority": "10" } }
}
```

#### API Endpoint:
- `POST /api/notifications/register-token` — register/update device FCM token (requires JWT auth)

#### Files Created:
- `lib/core/notifications/notification_service.dart` — singleton FCM service

#### Files Modified:
- `pubspec.yaml` — added `firebase_core`, `firebase_messaging`
- `android/settings.gradle.kts` — added `com.google.gms.google-services` plugin
- `android/app/build.gradle.kts` — applied Google Services plugin
- `android/app/src/main/AndroidManifest.xml` — added `POST_NOTIFICATIONS` permission
- `lib/core/storage/storage_keys.dart` — added `fcmToken` key
- `lib/core/config/api_config.dart` — added `registerNotificationToken` endpoint
- `lib/main.dart` — Firebase init, background handler, notification service wiring with AppBloc
- `.gitignore` — added `google-services.json`, `GoogleService-Info.plist`

#### Backend Requirement:
- `POST /api/notifications/register-token` — store `fcm_token` + `platform` per authenticated user. Use FCM Admin SDK to send notifications.

---

**Last Updated:** 2026-04-05
**Current Phase:** Phase 6 (Matches API Integration) + Match Question Filters + Seeker Location Filter + Google Sign-In + Push Notifications (FCM)
