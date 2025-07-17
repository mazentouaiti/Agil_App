# Agil Distribution Tunisia Mobile App

A professional mobile application for Agil Distribution Tunisia's gas station network, built with Flutter.

## 🌟 Features

### Authentication
- **Email/Password Login**: Secure user authentication
- **Biometric Authentication**: Fingerprint and face recognition support
- **Password Reset**: Email-based password recovery
- **User Registration**: New account creation with validation

### Dashboard
- **Real-time Statistics**: Sales, orders, inventory, and revenue tracking
- **Quick Actions**: Fast access to common tasks
- **Recent Activities**: Timeline of recent events
- **Performance Metrics**: Visual indicators with trend analysis

### Profile Management
- **User Profile**: Personal and professional information
- **Settings**: Notifications, security, language, and theme preferences
- **Account Management**: Secure logout and session management

### UI/UX
- **Modern Design**: Clean, professional interface with Agil branding
- **Responsive Layout**: Optimized for all screen sizes
- **Smooth Animations**: Enhanced user experience with fluid transitions
- **Dark/Light Theme**: User preference-based theming (upcoming)
- **Multilingual Support**: French primary with Arabic support (upcoming)

## 🛠 Technology Stack

- **Framework**: Flutter 3.32.5
- **State Management**: Provider
- **Navigation**: GoRouter
- **Local Storage**: SharedPreferences + Flutter Secure Storage
- **HTTP Client**: Dio & HTTP
- **Database**: SQLite (SQLFlite)
- **Authentication**: Local Auth (Biometrics)
- **UI Components**: Material Design 3

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Windows (Desktop)
- ✅ Web
- ⏳ macOS (Planned)
- ⏳ Linux (Planned)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mazentouaiti/Agil_App.git
   cd agil_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   
   # For Windows
   flutter run -d windows
   
   # For Web
   flutter run -d chrome
   ```

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Core functionality
│   ├── routes/                  # Navigation configuration
│   ├── services/               # Business services
│   ├── theme/                  # App theming
│   └── widgets/                # Shared widgets
├── features/                   # Feature modules
│   ├── auth/                   # Authentication
│   │   ├── providers/          # State management
│   │   ├── screens/            # UI screens
│   │   └── widgets/            # Feature widgets
│   ├── dashboard/              # Dashboard module
│   └── profile/                # Profile module
```

## 🎨 Design System

### Colors
- **Primary**: Gold (#FFD700) - Agil brand color
- **Secondary**: Black (#000000) - Contrast and text
- **Accent**: Orange (#FF6B35) - Highlights and CTAs
- **Background**: Off-white (#FFFFFD) - Clean background

### Typography
- **Font Family**: Poppins
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)

## 🔧 Configuration

Update the base URL in `lib/core/services/auth_service.dart` for backend integration.

## 📱 Building for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

## 👥 Team

- **Mazen Touaiti** - Lead Developer
- **Agil Distribution Tunisia** - Product Owner

---

**Made with ❤️ by the Agil team in Tunisia 🇹🇳**
