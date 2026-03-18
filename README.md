# GM Hostel App 🏨

A comprehensive mobile application built with Flutter designed to streamline and manage hostel operations efficiently. This app provides a digital interface for students and staff to handle room allocations, grievances, payments, and more.

---

## ✨ Features

- **🔐 User Authentication**: Secure login and registration for students and supervisors.
- **🛏️ Room Management**: Digitalized room allocation and status tracking.
- **📝 Grievance Redressal**: Module for students to raise complaints and track resolution.
- **📅 Appointment Scheduling**: Book appointments with hostel authorities.
- **💰 Fee Management**: Interface for tracking and managing hostel fee payments.
- **📢 Notice Board**: Real-time updates and announcements.
- **🔍 QR Integration**: Built-in QR scanner for various hostel processes (using `mobile_scanner`).
- **📂 Document Upload**: Support for file and image uploads for registrations and complaints.
- **📱 Responsive UI**: Modern dashboard with staggered grid layouts and Lottie animations.

---

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: REST API Integration (using `http`)
- **State & Storage**: `shared_preferences`, `flutter_dotenv`
- **UI Components**: `google_fonts`, `lottie`, `flutter_staggered_grid_view`
- **Native Features**: `image_picker`, `file_picker`, `url_launcher`, `device_info_plus`, `webview_flutter`
- **Utilities**: `intl`, `qr_flutter`

---

## 📂 Folder Structure

```text
lib/
├── core/         # App themes, constants, and global configurations
├── models/       # Data models for JSON serialization
├── screens/      # UI screens
│   ├── auth/       # Login and Registration screens
│   ├── dashboards/ # Role-specific home screens
│   └── features/   # Specific feature modules (Student/Supervisor)
├── services/     # API services and business logic
├── widgets/      # Reusable UI components
└── main.dart     # Entry point
assets/           # Images, animations (Lottie), and icons
```

---

## ⚙️ Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/gm-hostel-app.git
   cd gm-hostel-app
   ```

2. **Environment Setup:**
   - Create a `.env` file in the root directory.
   - Define your API base URL and other secrets in the `.env` file.

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📱 Usage

1. **Login**: Use your student or staff credentials to log in.
2. **Dashboard**: Navigate through features like Room Request, Fee Status, or Notices.
3. **Actions**: Use the floating action buttons or grid items to submit grievances or scan QR codes.
4. **Profile**: Manage your personal information and view app details.

---

[//]: # (## 📸 Screenshots)

[//]: # ()
[//]: # (| Splash Screen | Login | Dashboard |)

[//]: # (| :---: | :---: | :---: |)

[//]: # (| ![Splash]&#40;https://via.placeholder.com/200x400?text=Splash+Screen&#41; | ![Login]&#40;https://via.placeholder.com/200x400?text=Login+Screen&#41; | ![Dashboard]&#40;https://via.placeholder.com/200x400?text=Dashboard&#41; |)

[//]: # ()
[//]: # (---)

[//]: # (---)

[//]: # ()
[//]: # (## 📄 License)

[//]: # ()
[//]: # (Distributed under the MIT License. See `LICENSE` for more information.)


Developed for **GM Hostel Management**.
