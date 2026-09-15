# Galamsey EcoWatch Ghana
A full-stack environmental monitoring and community reporting platform that empowers citizens to report illegal mining (galamsey) and environmental violations across Ghana.

Live App: https://ecowatch-ghana.netlify.app/
API: galamsey-ecowatch-ghana.onrender.com

 # About
Illegal mining (galamsey) has caused severe environmental damage across Ghana — polluting rivers, destroying forests, and contaminating communities.
EcoWatch Ghana provides a real-time platform for citizens to report incidents with photo evidence and GPS location, while giving authorities a comprehensive dashboard to review, 
investigate, and resolve reports.

# Features
# 👤 Citizen App
Secure registration and login (JWT authentication)
Create detailed reports with photos, location, category, and severity
Report anonymously for personal safety
Track report status (Pending → Verified → Under Investigation → Resolved)
Interactive Google Maps view of nearby reports
Real-time notifications on status updates
Educational content on environmental protection

# 🛡️ Admin & Officer Dashboard
Comprehensive analytics with charts and regional breakdowns
Manage and verify all reports submitted by citizens
Assign officers and update investigation statuses
Create environmental alerts, tasks, and investigations
Manage users, news, and educational articles
All statistics dynamically pulled from PostgreSQL

# Tech Stack
Layer	Technology
Frontend	Flutter (Web + Mobile)
Backend	Node.js + Express.js
Database	PostgreSQL
Auth	JWT + bcrypt
Storage	Cloudinary (evidence uploads)
Maps	Google Maps API
Hosting	Netlify (web) + Render (API + DB)

# 📁 Project Structure
text
galamsey-ecowatch-ghana/
├── backend/                 # Node.js REST API
│   ├── src/
│   │   ├── config/          # Database, Cloudinary
│   │   ├── controllers/     # Route logic
│   │   ├── middleware/      # Auth, validation
│   │   ├── models/          # Data models
│   │   ├── routes/          # API endpoints
│   │   └── scripts/         # Migrations & seeds
│   └── package.json
│
└── galamsey_ecowatch/       # Flutter app
    ├── lib/
    │   ├── models/
    │   ├── providers/       # State management
    │   ├── screens/         # UI (user + admin)
    │   ├── services/        # API, maps, notifications
    │   └── main.dart
    └── pubspec.yaml
    
# Quick Start
Backend Setup
bash
cd backend
npm install
cp .env.example .env      # Configure your credentials
node src/scripts/create-tables.js
node src/scripts/seed-admin.js
node src/server.js

Flutter Setup
bash
cd galamsey_ecowatch
flutter pub get
flutter run -d chrome --web-port=3000
Environment Variables (.env)
env
PORT=5000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=galamsey_ecowatch_db
DB_USER=postgres
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_secret_key
JWT_EXPIRE=7d

# Cloudinary (for evidence uploads)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Admin seed
ADMIN_EMAIL=admin@ecowatch.gh
ADMIN_PASSWORD=Admin@123456
On Render, use the DATABASE_URL environment variable instead of individual DB fields.

# Demo Credentials
Role	Email	Password
Admin	admin@ecowatch.gh	Admin@123456
Citizen	mikeasare3030@gmail.com	Sconzy3030

# Deploy
Component	Platform	Notes
Backend	Render	Free tier (sleeps after 15 min inactivity)
Database	Render PostgreSQL	Free tier
Web App	Netlify	Auto-deploys on git push
Mobile APK	Android Studio	flutter build apk --release

# Roadmap
☑ Full authentication system (JWT + bcrypt)
☑ Citizen report creation with evidence uploads
☑ Admin dashboard with analytics
☑ Google Maps integration (user + admin)
☑ Real-time notifications
☑ Cloudinary evidence storage
☑ Cloud deployment (Render + Netlify)
□ Firebase push notifications
□ Multi-language support (Twi, Ga, Ewe)
□ Android APK release
□ iOS build

# Contributing
Contributions are welcome. Please:

Fork the repository

Create a feature branch (git checkout -b feature/amazing-feature)

Commit your changes (git commit -m "Add amazing feature")

Push to the branch (git push origin feature/amazing-feature)

Open a Pull Request


# 👨‍💻 Author
Michael Asare
GitHub: @asaremichael3030

🙏 Acknowledgments
Built to support Ghana's fight against illegal mining and to empower communities to protect their environment.

# 📸 Screenshots
# 👤 Citizen App
Login	Home Dashboard
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 19 36 PM" src="https://github.com/user-attachments/assets/6f146af5-fd72-4e33-9461-b3e110ff90eb" />

user home Dashboard
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 19 34 PM" src="https://github.com/user-attachments/assets/cf1a8375-1e61-4f03-ada2-2195aed07f97" />

Create Report	Report Details
<img width="499" height="1080" alt="c rep" src="https://github.com/user-attachments/assets/9f271068-1b3c-4d36-97b2-a2d85feb10fc" />

My Reports Dashboard
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 19 36 PM (1)" src="https://github.com/user-attachments/assets/6bbfefe3-1747-4c02-9b39-3a74b0abd623" />

Map View	Notifications
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 19 35 PM" src="https://github.com/user-attachments/assets/7bfb9b8e-aa44-4ecd-b300-b3cd7fcbaa60" />


# 🛡️ Admin Dashboard
Dashboard Overview	Reports Management
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 28 55 PM" src="https://github.com/user-attachments/assets/6767da93-cb28-48a4-8867-d2007ccdb43f" />


<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 28 56 PM" src="https://github.com/user-attachments/assets/1adf0c40-defb-42d8-a54f-977d5d4e83c6" />


Analytics	Users Management
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 31 20 PM" src="https://github.com/user-attachments/assets/8abef6de-0265-42da-85c8-293e51543b1c" />


<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 28 56 PM (1)" src="https://github.com/user-attachments/assets/0ab012a5-4cff-4a60-9759-05a9741830c8" />


Admin Map	Alerts & Tasks
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 31 20 PM (1)" src="https://github.com/user-attachments/assets/64026184-82b4-4ffe-a16c-1fbb8b77c090" />


<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 28 57 PM" src="https://github.com/user-attachments/assets/162c4b6f-7dda-454a-bbd3-b8e9756c2ed9" />


<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 28 57 PM (1)" src="https://github.com/user-attachments/assets/32e8f3f0-c9e6-4b6d-9e10-905f974b9cca" />

 
<img width="499" height="1080" alt="WhatsApp Image 2026-09-15 at 6 28 57 PM (1)" src="https://github.com/user-attachments/assets/b142f944-867d-4200-a4a2-21fbf9a4fe8b" />

