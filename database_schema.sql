-- Travel Planner App Database Schema
-- Run this in your Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trips table
CREATE TABLE IF NOT EXISTS public.trips (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  destination TEXT,
  start_date DATE,
  end_date DATE,
  trip_image_url TEXT,
  status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
  budget DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trip_segments table
CREATE TABLE IF NOT EXISTS public.trip_segments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE NOT NULL,
  segment_type TEXT NOT NULL CHECK (segment_type IN ('flight', 'accommodation', 'activity', 'transport', 'other')),
  title TEXT NOT NULL,
  description TEXT,
  start_datetime TIMESTAMP WITH TIME ZONE,
  end_datetime TIMESTAMP WITH TIME ZONE,
  location TEXT,
  booking_reference TEXT,
  cost DECIMAL(10,2),
  status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'booked', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create expense_categories table
CREATE TABLE IF NOT EXISTS public.expense_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  color TEXT DEFAULT '#3B82F6',
  icon TEXT DEFAULT 'receipt',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default expense categories
INSERT INTO public.expense_categories (name, color, icon) VALUES
  ('Food & Dining', '#10B981', 'restaurant'),
  ('Accommodation', '#3B82F6', 'hotel'),
  ('Transportation', '#F59E0B', 'directions_car'),
  ('Activities', '#8B5CF6', 'attractions'),
  ('Shopping', '#EF4444', 'shopping_bag'),
  ('Other', '#6B7280', 'more_horiz')
ON CONFLICT (name) DO NOTHING;

-- Create expenses table
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  date DATE NOT NULL,
  receipt_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trip_images table
CREATE TABLE IF NOT EXISTS public.trip_images (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE NOT NULL,
  image_url TEXT NOT NULL,
  caption TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create shooting_data table for admin analytics
CREATE TABLE IF NOT EXISTS public.shooting_data (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE NOT NULL,
  shooting_date DATE NOT NULL,
  location TEXT NOT NULL,
  target_type TEXT NOT NULL CHECK (target_type IN ('static', 'moving', 'long_range', 'close_range')),
  distance_meters INTEGER NOT NULL CHECK (distance_meters > 0),
  shots_fired INTEGER NOT NULL DEFAULT 0,
  shots_hit INTEGER NOT NULL DEFAULT 0,
  accuracy_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN shots_fired > 0 THEN ROUND((shots_hit::DECIMAL / shots_fired * 100), 2)
      ELSE 0
    END
  ) STORED,
  weather_conditions TEXT,
  wind_speed_kmh DECIMAL(4,1),
  temperature_celsius DECIMAL(4,1),
  equipment_used TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create shooting_statistics view for admin analytics
CREATE OR REPLACE VIEW public.shooting_statistics AS
SELECT 
  u.full_name,
  u.email,
  t.title as trip_title,
  t.destination,
  COUNT(sd.id) as total_sessions,
  SUM(sd.shots_fired) as total_shots_fired,
  SUM(sd.shots_hit) as total_shots_hit,
  ROUND(AVG(sd.accuracy_percentage), 2) as avg_accuracy,
  MAX(sd.accuracy_percentage) as best_accuracy,
  MIN(sd.accuracy_percentage) as worst_accuracy,
  ROUND(AVG(sd.distance_meters), 1) as avg_distance,
  MAX(sd.distance_meters) as max_distance,
  COUNT(DISTINCT sd.location) as unique_locations,
  COUNT(DISTINCT sd.target_type) as target_types_used
FROM public.shooting_data sd
JOIN public.users u ON sd.user_id = u.id
JOIN public.trips t ON sd.trip_id = t.id
GROUP BY u.id, u.full_name, u.email, t.id, t.title, t.destination;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_trips_user_id ON public.trips(user_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON public.trips(status);
CREATE INDEX IF NOT EXISTS idx_trip_segments_trip_id ON public.trip_segments(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_segments_type ON public.trip_segments(segment_type);
CREATE INDEX IF NOT EXISTS idx_expenses_trip_id ON public.expenses(trip_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_trip_images_trip_id ON public.trip_images(trip_id);
CREATE INDEX IF NOT EXISTS idx_shooting_data_user_id ON public.shooting_data(user_id);
CREATE INDEX IF NOT EXISTS idx_shooting_data_trip_id ON public.shooting_data(trip_id);
CREATE INDEX IF NOT EXISTS idx_shooting_data_date ON public.shooting_data(shooting_date);
CREATE INDEX IF NOT EXISTS idx_shooting_data_location ON public.shooting_data(location);
CREATE INDEX IF NOT EXISTS idx_shooting_data_target_type ON public.shooting_data(target_type);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shooting_data ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for trips table
CREATE POLICY "Users can view own trips" ON public.trips
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own trips" ON public.trips
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trips" ON public.trips
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trips" ON public.trips
  FOR DELETE USING (auth.uid() = user_id);

-- Admin policies for trips table
CREATE POLICY "Admins can view all trips" ON public.trips
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.is_admin = TRUE
    )
  );

CREATE POLICY "Admins can update any trip" ON public.trips
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.is_admin = TRUE
    )
  );

CREATE POLICY "Admins can delete any trip" ON public.trips
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.is_admin = TRUE
    )
  );

-- RLS Policies for trip_segments table
CREATE POLICY "Users can view segments of own trips" ON public.trip_segments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = trip_segments.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create segments for own trips" ON public.trip_segments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = trip_segments.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update segments of own trips" ON public.trip_segments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = trip_segments.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete segments of own trips" ON public.trip_segments
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = trip_segments.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

-- RLS Policies for expenses table
CREATE POLICY "Users can view expenses of own trips" ON public.expenses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = expenses.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create expenses for own trips" ON public.expenses
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = expenses.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update expenses of own trips" ON public.expenses
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = expenses.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete expenses of own trips" ON public.expenses
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = expenses.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

-- RLS Policies for trip_images table
CREATE POLICY "Users can view images of own trips" ON public.trip_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = trip_images.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can upload images for own trips" ON public.trip_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = trip_images.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete images of own trips" ON public.trip_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.trips 
      WHERE trips.id = trip_images.trip_id 
      AND trips.user_id = auth.uid()
    )
  );

-- RLS Policies for shooting_data table
CREATE POLICY "Users can view own shooting data" ON public.shooting_data
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own shooting data" ON public.shooting_data
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shooting data" ON public.shooting_data
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own shooting data" ON public.shooting_data
  FOR DELETE USING (auth.uid() = user_id);

-- Admin policies for shooting_data table
CREATE POLICY "Admins can view all shooting data" ON public.shooting_data
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.is_admin = TRUE
    )
  );

CREATE POLICY "Admins can update any shooting data" ON public.shooting_data
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.is_admin = TRUE
    )
  );

CREATE POLICY "Admins can delete any shooting data" ON public.shooting_data
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.is_admin = TRUE
    )
  );

-- RLS Policies for expense_categories table (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view expense categories" ON public.expense_categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON public.trips
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_trip_segments_updated_at BEFORE UPDATE ON public.trip_segments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_shooting_data_updated_at BEFORE UPDATE ON public.shooting_data
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.shooting_statistics TO anon, authenticated;
