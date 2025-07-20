# 🍽️ Recipe App — A Community-Driven Cooking Experience

The **Recipe App** is a Flutter-powered mobile application backed by Firebase. It provides users a seamless experience for exploring, commenting, and rating recipes. A special admin interface allows easy recipe management. It’s an interactive platform where food lovers and creators meet.

---

## ✨ Key Features

### 👩‍🍳 For Users

- 🔐 Secure Sign Up / Login / Logout
- 🌟 Rate recipes (with average rating updates)
- ✍️ Comment on recipes
- 💬 Reply to other users
- 👍 Like / 👎 Dislike any comment or reply
- 🔁 Undo like/dislike
- 📝 Edit display name (except reserved names)
- 🗑️ Delete their own comments/replies
- 👀 View recipe ingredients, instructions, ratings, and discussion
- 🔎 **Search recipes by title or ingredients (comma-separated)**

### 👨‍💼 For Admin (Developer-Specified)

- Admin access fixed to: `suptipal03@gmail.com`
- 🔐 Admin login/logout with automatic "Admin" badge and role
- 🌟 Rate & comment like any user
- 👮 Delete any comment or reply (not just own)
- 📥 Upload new recipes
- ✏️ Edit existing recipes
- ❌ Delete recipes from dashboard
- 💎 Admin badge visible next to display name

---

## 🧑‍💻 Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Cloud Firestore)
- **Authentication:** Firebase Authentication
- **Storage:** Firebase Storage (for recipe images via URL or future upload)
- **Architecture:** MVVM
- **State Management:** `Provider`, `setState`
- **Platform:** Android only (iOS planned)

---

## 🚀 Getting Started

### ✅ Prerequisites

- Flutter SDK (v3.0 or later)
- Dart SDK
- Firebase Project (configured for Android)
- IDE: Android Studio / VS Code

### 🔨 Installation Steps

1. **Clone the Repository**

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
```

2. **Install Flutter Dependencies**

```bash
flutter pub get
```

3. **Configure Firebase**

- Go to [Firebase Console](https://console.firebase.google.com)
- Add Android App and download `google-services.json`
- Place `google-services.json` inside `android/app/`
- Enable **Email/Password Authentication**
- Set up **Cloud Firestore** in test mode

4. **Run the App**

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── models/
│   └── recipe_model.dart
│
├── screens/
│   ├── admin/
│   │   └── admin_dashboard_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home_screen.dart
│   ├── recipe_details_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart
│
├── services/
│   ├── auth_service.dart
│   └── database_service.dart
│
├── main.dart
```

---

## 📱 Features Snapshot

| Feature                        | User | Admin |
|-------------------------------|------|-------|
| Sign Up / Login               | ✅   | ✅    |
| Rate Recipes                  | ✅   | ✅    |
| Comment & Reply               | ✅   | ✅    |
| Like / Dislike                | ✅   | ✅    |
| Delete own Comment/Reply      | ✅   | ✅    |
| Delete others' Comment/Reply  | ❌   | ✅    |
| Upload / Edit / Delete Recipe | ❌   | ✅    |
| Change Display Name           | ✅   | ✅    |
| See Admin Badge               | ❌   | ✅    |
| 🔎 Search by Title/Ingredient | ✅   | ✅    |

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  cloud_firestore: ^5.6.5
  firebase_storage: ^12.4.4
  provider: ^6.1.2
  flutter_rating_bar: ^4.0.1
  image_picker: ^1.1.0
  iconsax: ^0.0.8
  flutter_launcher_icons: ^0.14.4
```

---

## 🧪 Testing

To run unit/widget tests:

```bash
flutter test
```

---

## 🎨 App Logo

Custom logo is included under:

```
assets/images/recipe_app_logo.png
```

---

## 🧑‍💻 Developer

**👤 Name:** Supti Pal  
**📧 Email:** [suptipal03@gmail.com](mailto:suptipal03@gmail.com)  
**🌐 GitHub:** [@SuptiPal](https://github.com/SuptiPal)

---

> 🍽️ Happy Cooking and Collaborating!
