# 📋 Travel Planner App - Project Requirements & Technical Specifications

## 🎯 Project Goal
Build a comprehensive personal Travel Planner application using Flutter and Supabase. Users can register, log in, and manage their trips, including trip segments (flights, accommodations, activities) and expenses. The app will feature user profiles and differentiate access based on "Admin" and "User" roles.

## 🔧 Backend Setup (Supabase)

### 1. Create a New Supabase Project
- Go to Supabase and create a new project
- Remember your Project URL and anon Public Key (found under Project Settings > API)
- These will be configured in your Flutter app

### 2. Database Schema (SQL Editor)
Execute the following SQL commands in your Supabase project's SQL Editor:

#### Profiles Table
```sql
-- Create the 'profiles' table
CREATE TABLE public.profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username text UNIQUE,
  avatar_url text,
  role text DEFAULT 'user' NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS for 'profiles'
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Policy: Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');

-- Function to handle new user creation and create a profile entry
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, role)
  VALUES (new.id, new.email, 'user'); -- Default role to 'user'
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to run handle_new_user on auth.users inserts
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

#### Trips Table
```sql
-- Create the 'trips' table
CREATE TABLE public.trips (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  destination text NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  description text,
  trip_image_url text, -- To store URL of uploaded image
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS for 'trips'
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own trips
CREATE POLICY "Users can view their own trips" ON public.trips
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own trips
CREATE POLICY "Users can insert their own trips" ON public.trips
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own trips
CREATE POLICY "Users can update their own trips" ON public.trips
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own trips
CREATE POLICY "Users can delete their own trips" ON public.trips
  FOR DELETE USING (auth.uid() = user_id);

-- Policy: Admins can view ALL trips
CREATE POLICY "Admins can view all trips" ON public.trips
  FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');
```

#### Trip Segments Table
```sql
-- Create 'trip_segments' table
CREATE TABLE public.trip_segments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id), -- Redundant but useful for RLS directly
  type text NOT NULL, -- e.g., 'Flight', 'Hotel', 'Activity'
  details text,
  start_time timestamp with time zone,
  end_time timestamp with time zone,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS for 'trip_segments'
ALTER TABLE public.trip_segments ENABLE ROW LEVEL SECURITY;

-- Policies for trip_segments (similar to trips, linked by user_id)
CREATE POLICY "Users can view their own trip segments" ON public.trip_segments
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own trip segments" ON public.trip_segments
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own trip segments" ON public.trip_segments
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own trip segments" ON public.trip_segments
  FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all trip segments" ON public.trip_segments
  FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');
```

#### Expenses Table
```sql
-- Create 'expenses' table
CREATE TABLE public.expenses (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id), -- Redundant but useful for RLS directly
  description text NOT NULL,
  amount numeric(10, 2) NOT NULL,
  currency text DEFAULT 'USD' NOT NULL,
  category text, -- e.g., 'Food', 'Transport', 'Accommodation'
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS for 'expenses'
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Policies for expenses (similar to trips, linked by user_id)
CREATE POLICY "Users can view their own expenses" ON public.expenses
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own expenses" ON public.expenses
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own expenses" ON public.expenses
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own expenses" ON public.expenses
  FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all expenses" ON public.expenses
  FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');
```

#### Storage Configuration
```sql
-- Create a storage bucket for trip images
INSERT INTO storage.buckets (id, name, public)
VALUES ('trip_images', 'trip_images', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Allow authenticated users to upload to 'trip_images'
CREATE POLICY "Allow authenticated upload" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'trip_images');

-- Policy: Allow authenticated users to view 'trip_images'
CREATE POLICY "Allow authenticated view" ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'trip_images');

-- Policy: Allow authenticated users to delete their own images
CREATE POLICY "Allow authenticated delete own" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'trip_images' AND owner = auth.uid());
```

### 3. Creating an Admin User
To test the admin functionality, you'll need to assign the 'admin' role to one of your users:

1. Register a new user through your app's signup flow (e.g., admin@example.com)
2. Go to the Supabase Dashboard > Authentication > Users tab
3. Find the admin@example.com user
4. Click the three dots ... next to their entry and select "Edit metadata"
5. Add a key-value pair to raw_app_meta_data as follows:
   - Key: `role`
   - Value: `admin`
6. Ensure the JSON format is valid (e.g., `{"provider": "email", "role": "admin"}`)

## 📱 Frontend Requirements (Flutter)

### 1. Project Setup
- Initialize a new Flutter project (`flutter create travel_planner_app`)
- Integrate the `supabase_flutter` package
- Add `image_picker` package for image handling

### 2. Required Screens

#### Authentication Flow
- **Splash Screen**: Handle initial Supabase session check
- **Login Screen**: User authentication
- **Registration Screen**: User signup
- **User Profile Screen**: Display/edit username and avatar

#### Main Application
- **Home Screen (Trips List)**:
  - Display list of trips
  - Conditional "Admin Dashboard" button for admin users
  - Filtering and sorting capabilities
  - Real-time listeners for automatic updates

- **Trip Detail Screen**:
  - Display trip details and uploaded image
  - List associated trip segments and expenses
  - Add/edit/delete functionality for segments and expenses

- **Create/Edit Trip Screen**: Form for trip details and image selection
- **Create/Edit Segment Screen**: Form for segment details
- **Create/Edit Expense Screen**: Form for expense details
- **Admin Dashboard**: List all trips in the system (admin only)

### 3. Technical Requirements
- **Error Handling**: Robust error handling for all Supabase API calls
- **State Management**: Choose appropriate solution (Provider, Riverpod, Bloc, or setState)
- **Real-time Updates**: Implement real-time listening for data changes
- **Image Handling**: Upload, store, and retrieve trip images

## 📦 Deliverables

### 1. GitHub Repository
- Public GitHub repository with complete Flutter project code
- All necessary files committed (pubspec.yaml, lib/, android/, ios/, etc.)

### 2. Build Artifact
Provide either:
- **Web Build**: Run `flutter build web` and provide build/web folder contents (zipped)
- **Android APK**: Run `flutter build apk` and provide .apk file (zipped)

### 3. Comprehensive README.md
Must include:
- Project title and description
- Complete feature list
- Detailed local setup instructions
- Supabase backend setup guide
- Configuration instructions
- Admin role setup steps
- Running instructions
- State management explanation
- Screenshots (recommended)

## ✅ Evaluation Criteria

### Core Functionality (40%)
- User authentication (registration, login, logout)
- Trip CRUD operations
- Trip segments management
- Expense tracking
- User profile management

### Supabase Integration (25%)
- Proper database schema implementation
- RLS policies enforcement
- Storage bucket configuration
- Real-time functionality

### Security & Access Control (20%)
- Role-based access control
- Row-level security implementation
- User data isolation

### Code Quality (15%)
- Clean, readable code structure
- Proper error handling
- Documentation and comments
- Flutter best practices

## 🚀 Success Factors

1. **Complete Feature Implementation**: All primary features working as specified
2. **Proper Supabase Integration**: Correct data storage, retrieval, and management
3. **Robust RLS Enforcement**: Proper security implementation
4. **Role-based Access**: Correct user role identification and UI adaptation
5. **Data Relationships**: Proper linking between trips, segments, and expenses
6. **File Storage**: Working image upload and retrieval
7. **Code Quality**: Maintainable, readable, and well-structured code
8. **Easy Setup**: Clear documentation for easy project setup by others

---

**Good luck, and demonstrate your best Flutter and Supabase skills! 🚀**
