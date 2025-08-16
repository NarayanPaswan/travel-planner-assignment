# 🚀 Travel Planner - Flutter Mobile App

A comprehensive travel planning application built with Flutter and Supabase backend, designed to help users plan, organize, and track their travel adventures.

## ✨ Features

### 🎯 Core Functionality
- **Trip Management**: Create, edit, and organize travel plans
- **User Authentication**: Secure signup/login with role-based access
- **Trip Segments**: Break down trips into flights, accommodation, activities, and transport
- **Expense Tracking**: Monitor travel costs with categorization
- **Image Management**: Upload and manage trip photos
- **Search & Filter**: Advanced trip discovery with sorting options

### 👑 Admin Features
- **User Management**: Admin dashboard for user oversight
- **Analytics**: Comprehensive app usage statistics
- **System Settings**: Configuration management
- **Security Policies**: Advanced security controls

### 🎨 User Experience
- **Responsive Design**: Optimized for all mobile devices
- **Intuitive Navigation**: Clean, modern UI with smooth interactions
- **Offline Support**: Core functionality works without internet
- **Real-time Updates**: Live data synchronization

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.x
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **State Management**: Provider
- **Image Handling**: Image Picker + Supabase Storage
- **Authentication**: Supabase Auth with RLS policies
- **Database**: PostgreSQL with advanced security

## 📱 Screenshots

### Authentication & User Management
- Clean signup/login screens with form validation
- Role-based access control (User/Admin)
- Secure password management

### Trip Planning
- Intuitive trip creation with title, destination, dates
- Image upload support for trip memories
- Advanced search and filtering capabilities

### Admin Dashboard
- Comprehensive administrative functions
- User management and analytics
- System configuration tools

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yasirSub/signa.git
   cd signa
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new Supabase project
   - Update `lib/config/supabase_config.dart` with your credentials
   - Run the database migrations

4. **Run the app**
   ```bash
   flutter run
   ```

## 🗄️ Database Schema

The app uses a well-structured PostgreSQL database with the following key tables:

- **users**: User profiles and authentication data
- **trips**: Main trip information and metadata
- **trip_segments**: Detailed trip components (flights, hotels, etc.)
- **expenses**: Financial tracking and categorization
- **shooting_data**: Specialized data for specific use cases

All tables include Row Level Security (RLS) policies for data privacy and security.

## 🔐 Security Features

- **Row Level Security (RLS)**: Users can only access their own data
- **JWT Authentication**: Secure token-based authentication
- **Role-based Access Control**: Admin and user permission levels
- **Data Encryption**: Secure data transmission and storage

## 📁 Project Structure

```
lib/
├── config/           # App configuration
├── models/           # Data models
├── providers/        # State management
├── screens/          # UI screens
│   ├── admin/        # Admin-specific screens
│   ├── auth/         # Authentication screens
│   ├── home/         # Main app screens
│   └── trips/        # Trip management screens
├── services/         # Business logic and API calls
└── utils/            # Helper functions and constants
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## 📦 Building

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the powerful backend services
- The open-source community for inspiration and tools

## 📞 Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Contact the development team
- Check the documentation

---

**Built with ❤️ using Flutter & Supabase**
