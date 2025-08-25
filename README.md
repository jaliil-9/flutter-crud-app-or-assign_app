# Flutter CRUD App with Firebase OTP Authentication

A production-ready cross-platform Flutter application featuring Firebase OTP authentication and comprehensive CRUD operations using a public REST API. Built with GetX architecture for optimal state management, navigation, and dependency injection.

## Features

- **Firebase OTP Authentication** - Secure phone number-based authentication for mobile and web
- **Cross-Platform** - Responsive design optimized for mobile, tablet, and web
- **Full CRUD Operations** - Create, Read, Update, Delete with optimistic updates
- **GetX Architecture** - Reactive state management, navigation, and dependency injection
- **Firebase Hosting** - Automated deployment with GitHub Actions
- **Pagination** - Efficient data loading with infinite scroll
- **Offline Support** - Graceful handling of network connectivity issues
- **Error Handling** - Robust error management with user-friendly messages

## Architecture

The app follows clean architecture principles with clear separation of concerns:

```
lib/
├── main.dart                    # App entry point with Firebase initialization
├── app/                         # App-level configuration
│   ├── routes/                  # GetX navigation routes and pages
│   ├── theme/                   # Material Design 3 theming
│   └── widgets/                 # Global app wrapper widgets
├── models/                      # Data models with JSON serialization
│   ├── api_object.dart         # Main API object model
│   └── user.dart               # User authentication model
├── controllers/                 # GetX controllers for business logic
│   ├── auth_controller.dart    # Authentication state management
│   ├── object_controller.dart  # CRUD operations controller
│   └── theme_controller.dart   # Theme and UI state
├── services/                    # External service integrations
│   ├── api_service.dart        # REST API client with Dio
│   ├── auth_service.dart       # Firebase Authentication wrapper
│   ├── storage_service.dart    # Local storage with GetStorage
│   └── retry_service.dart      # Network retry logic
├── views/                       # UI screens and widgets
│   ├── auth/                   # Login and OTP verification screens
│   ├── objects/                # CRUD operation screens
│   └── common/                 # Reusable UI components
├── utils/                       # Helper utilities and constants
└── bindings/                    # GetX dependency injection setup
```

## 📦 Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management & Navigation
  get: ^4.6.6                    # GetX for state management, navigation, DI
  
  # Firebase Integration
  firebase_core: ^4.0.0         # Firebase core functionality
  firebase_auth: ^6.0.1         # Firebase Authentication
  firebase_app_check: ^0.4.0    # App integrity verification
  
  # HTTP & API
  dio: ^5.7.0                    # HTTP client for API calls
  
  # Data & Storage
  json_annotation: ^4.9.0       # JSON serialization annotations
  get_storage: ^2.1.1           # Local storage solution
  collection: ^1.18.0           # Collection utilities
  
  # UI & Theming
  google_fonts: ^6.2.1          # Custom typography
  cupertino_icons: ^1.0.8       # iOS-style icons
  
  # Environment
  flutter_dotenv: ^5.1.0        # Environment variables

dev_dependencies:
  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4                # Mocking for unit tests
  
  # Code Generation
  build_runner: ^2.4.13         # Code generation runner
  json_serializable: ^6.8.0     # JSON serialization generator
  
  # Code Quality
  flutter_lints: ^6.0.0         # Dart linting rules
```

## Getting Started

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/jaliil-9/assign_app.git
cd assign_app

# Install dependencies
flutter pub get

# Generate code (for JSON serialization)
flutter packages pub run build_runner build
```

### 2. Firebase Configuration

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase for your project
flutterfire configure
```


### 3. Environment Configuration

Create a `.env` file in the project root:
```env
# API Configuration
API_BASE_URL=YOUR_API_BASE_URL

```

### 4. Run the Application

```bash
# Web development
flutter run -d chrome

# Android development
flutter run -d android

# Build for production
flutter build web --release
flutter build apk --release
```

## Firebase Setup Details

### Authentication Configuration

1. **Enable Phone Authentication**:
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable Phone provider
   - Configure authorized domains (add localhost for development)

2. **Billing Requirements**:
   - Phone Authentication requires Blaze (Pay-as-you-go) plan
   - Set up budget alerts to monitor usage

3. **Test Phone Numbers**:
   ```
   Phone: +1 650 555 3434
   Code: 654321
   ```

### Web Configuration

For web deployment, ensure these domains are authorized:
- `localhost` (development)
- `https://caffedict-gauth.web.app` (production)

## 🌐 API Integration

The app integrates with the RESTful API providing full CRUD functionality:

### API Endpoints
- **GET** `/objects` - Fetch all objects (with pagination)
- **GET** `/objects/{id}` - Fetch single object details
- **POST** `/objects` - Create new object
- **PUT** `/objects/{id}` - Update existing object
- **DELETE** `/objects/{id}` - Delete object


### Error Handling
- Network connectivity issues
- API rate limiting
- Invalid data validation
- Authentication errors
- Server errors (4xx, 5xx)

## Key Features Implementation

### Authentication Flow
1. **Phone Input**: User enters phone number with country code
2. **OTP Verification**: Firebase sends SMS with verification code
3. **Auto-verification**: Automatic verification on supported platforms
4. **Session Management**: Persistent login state with secure token storage
5. **Logout**: Clear session and redirect to login

### CRUD Operations
1. **List View**: 
   - Infinite scroll pagination
   - Pull-to-refresh functionality
   - Search and filter capabilities
   - Empty and error states

2. **Detail View**:
   - Complete object information display
   - Edit and delete actions
   - Optimistic UI updates

3. **Create/Edit Forms**:
   - Form validation with real-time feedback
   - JSON data field with syntax validation
   - Auto-save draft functionality

4. **Delete Operations**:
   - Confirmation dialogs
   - Optimistic UI updates
   - Undo functionality

### State Management with GetX
- **Reactive Programming**: Observable variables with automatic UI updates
- **Navigation Management**: Named routes with parameter passing
- **Dependency Injection**: Service locator pattern with lazy loading
- **Memory Management**: Automatic controller disposal

##  Testing

The app includes comprehensive testing:

### Run All Tests
```bash
flutter test
```

### Run Specific Test Suites
```bash
# API Service tests
flutter test test/services/api_service_test.dart

# Controller tests
flutter test test/controllers/object_controller_test.dart

```

## Deployment

### Web Deployment to Firebase Hosting

#### CI/CD with GitHub Actions
The project includes automated deployment on push to `main` branch. See `.github/workflows/firebase-deploy.yml`.

### Mobile App Deployment

#### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS
```bash
flutter build ios --release
# Use Xcode to archive and distribute
```

## UI/UX Features

### Responsive Design
- **Mobile-first**: Optimized for touch interactions
- **Tablet**: Adaptive layouts with better space utilization
- **Web**: Desktop-friendly with keyboard navigation
- **Breakpoints**: Custom responsive breakpoints for all screen sizes

### Material Design 3
- **Dynamic theming**: System-based color schemes
- **Dark mode**: Automatic and manual theme switching
- **Typography**: Google Fonts with proper text scaling
- **Components**: Latest Material 3 components and animations

### Accessibility
- **Screen readers**: Semantic labels and descriptions
- **Keyboard navigation**: Full keyboard support for web
- **High contrast**: Support for accessibility themes
- **Text scaling**: Respect system font size preferences


## Performance Optimizations

- **Lazy loading**: Controllers and services loaded on demand
- **Image optimization**: Cached network images with placeholders
- **API caching**: Intelligent caching with cache invalidation
- **Bundle optimization**: Tree shaking and code splitting for web
- **Memory management**: Proper disposal of resources and subscriptions

## 🔮 Future Improvements

- **Offline-first architecture**: Local database with sync capabilities
- **Push notifications**: Firebase Cloud Messaging integration
- **Advanced search**: Full-text search with filters and sorting
- **File uploads**: Image and document upload functionality
- **Real-time updates**: WebSocket integration for live data
- **Internationalization**: Multi-language support
- **Analytics**: User behavior tracking and insights


### Development Guidelines
- Follow the existing code style and architecture
- Write tests for new features
- Update documentation for API changes
- Use conventional commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
