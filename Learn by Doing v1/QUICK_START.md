# ⚡ Quick Start Guide - Learn by Doing v1

## 🚀 Get Running in 5 Minutes

### Step 1: Backend Setup (2 minutes)

```bash
# Navigate to backend
cd "a:\Documents\Apps - VS Code with AI\Learn by Doing v1\backend"

# Create virtual environment
python -m venv venv

# Activate it
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Configure environment
copy .env.example .env

# IMPORTANT: Edit .env with these minimum settings:
# DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/learn_by_doing_v1
# SECRET_KEY=any-long-random-string-here-for-development

# Create database
createdb learn_by_doing_v1

# Run migrations
alembic upgrade head

# Start backend
.\start-backend.ps1
```

Backend will start at: **http://127.0.0.1:8000**

### Step 2: Frontend Setup (1 minute)

Open a **new terminal**:

```bash
# Navigate to frontend
cd "a:\Documents\Apps - VS Code with AI\Learn by Doing v1\frontend"

# Get dependencies
flutter pub get

# Start frontend
.\start-frontend.ps1
```

Frontend will start at: **http://localhost:9000**

### Step 3: Create Your Account (1 minute)

1. Open browser to **http://localhost:9000**
2. Click **"Sign Up"** tab
3. Enter:
   - Email
   - Username
   - First Name
   - Last Name
   - Password
4. Click **"Sign Up"**
5. You're in! (First user becomes admin)

### Step 4: Explore (1 minute)

You now have:
- ✅ **Dashboard** - Welcome screen with stats
- ✅ **Profile** - Click hamburger menu icon
- ✅ **Edit Profile** - Upload image, change timezone
- ✅ **Logout** - Works perfectly

## 🎯 That's It!

You now have a fully functional authentication system with:
- User signup/login
- Password reset (needs SMTP config)
- Profile management
- Dashboard
- Navigation

## 🔧 Troubleshooting

**Backend won't start?**
- Check PostgreSQL is running
- Verify DATABASE_URL in .env
- Make sure port 8000 is free

**Frontend won't start?**
- Run `flutter doctor` to check installation
- Try `flutter clean` then `flutter pub get`
- Make sure port 9000 is free

**Can't login?**
- Check backend is running (http://127.0.0.1:8000/health)
- Try creating a new account
- Check browser console for errors

## 📖 Next Steps

- Read `README.md` for full documentation
- Check `PROJECT_CREATION_SUMMARY.md` for details
- Start building your custom features!

## 💡 Pro Tips

1. **Email Optional**: Password reset requires SMTP configuration in `.env`. Skip it for development.

2. **First User = Admin**: The first user created automatically becomes super_admin.

3. **API Docs**: Visit http://127.0.0.1:8000/docs for interactive API documentation.

4. **Hot Reload**: Both frontend and backend auto-reload when you save files!

5. **Debug Mode**: Both are in debug mode by default. Perfect for development.

---

**Happy Coding! 🎉**
