# 🚀 Supabase Database Setup Guide

## 📋 Prerequisites
- Supabase project: `ntswtgndspxdxmgflnqw`
- Project URL: `https://ntswtgndspxdxmgflnqw.supabase.co`
- Access Token: `sbp_31e8098db3493c43a7c5a6bb00d4ab9d8a0de272`

## 🔧 Step 1: Set Up Database Schema

1. **Go to your Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your project**: `ntswtgndspxdxmgflnqw`
3. **Navigate to**: SQL Editor
4. **Click**: "New query"
5. **Copy and paste** the contents of `database_schema.sql`
6. **Click**: "Run" to execute the SQL

## 🗄️ What Gets Created

### Tables:
- **users** - User profiles and admin roles
- **trips** - Trip information and metadata
- **trip_segments** - Flights, accommodations, activities
- **expenses** - Trip expenses with categories
- **expense_categories** - Expense categories (pre-populated)
- **trip_images** - Image storage references

### Features:
- ✅ Row Level Security (RLS) policies
- ✅ Automatic user profile creation on signup
- ✅ Updated timestamp triggers
- ✅ Proper indexing for performance
- ✅ Admin role support

## 🔐 Step 2: Configure Authentication

1. **Go to**: Authentication → Settings
2. **Enable**: Email confirmations (optional)
3. **Set**: Site URL to your app's URL
4. **Configure**: Redirect URLs for your app

## 🎯 Step 3: Test the Setup

1. **Create a test user** through your Flutter app
2. **Verify** the user profile is created automatically
3. **Check** that RLS policies are working
4. **Test** creating trips and expenses

## 🚨 Important Notes

- **RLS is enabled** - users can only access their own data
- **Admin users** can access admin dashboard
- **Images** are stored in Supabase Storage
- **All operations** are properly secured

## 🔍 Troubleshooting

### If you get permission errors:
1. Check that RLS policies are created
2. Verify user authentication is working
3. Ensure proper user roles are set

### If tables don't appear:
1. Check SQL execution for errors
2. Verify you're in the correct schema (public)
3. Refresh the table list

## 📱 Your Flutter App is Ready!

Your app now has:
- ✅ Complete database schema
- ✅ Authentication system
- ✅ User management
- ✅ Trip planning
- ✅ Expense tracking
- ✅ Admin functionality
- ✅ Secure data access

## 🎉 Next Steps

1. **Run your Flutter app**: `fvm flutter run`
2. **Test user registration** and login
3. **Create your first trip**
4. **Add expenses** and categories
5. **Test admin features** (if you have admin role)

## 🆘 Need Help?

- Check the Supabase logs for errors
- Verify your project configuration
- Test with the Supabase dashboard tools
- Check the Flutter console for app errors

**Happy Travel Planning! ✈️**
