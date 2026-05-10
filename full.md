# UniAttend Application Architecture & UI Guide

This document outlines how the UniAttend application was built, focusing on its architecture, design principles, and state management.

---

## 🏗️ Architecture Overview: Feature-Driven MVC

The application follows a **Feature-Driven MVC (Model-View-Controller)** pattern powered by **GetX**. Each major functionality is encapsulated within its own module to ensure high cohesion and low coupling.

### Project Structure
```text
lib/
├── core/               # App-wide constants, themes, and shared utilities
├── features/           # Modular features of the app
│   ├── auth/           # Login & Authentication
│   ├── dashboard/      # Student Dashboard
│   ├── attendance/     # Location Verification & Check-in
│   ├── history/        # Presence logs
│   └── lecturer_dashboard/ # Lecturer Portal
├── navigation/         # Bottom Navigation & Routing logic
└── services/           # Global API & Backend services
```

---

## 🎨 Design System: Premium & Pixel-Perfect

To achieve a "premium" and "wow" aesthetic, we implemented a custom design system:

*   **Custom Color Palette**: Defined in `core/constants/app_colors.dart`, featuring deep navies, vibrant cyans, and soft neutrals.
*   **Typography**: Powered by `Google Fonts`. We use **Outfit** for bold, premium-looking headings and **Inter** for clean, readable body text.
*   **Theme Engine**: `core/theme/app_theme.dart` centralizes the look of buttons, cards, and input fields, ensuring UI consistency.

---

## 🎮 The MVC Breakdown

### 1. The Controller (The Brain)
Controllers handle all the business logic and state changes.
*   **Technology**: `GetxController`
*   **Reactive State**: Uses `.obs` variables (Observables) to automatically update the UI whenever data changes.
*   **Example**: `AuthController` manages the `isLoading` state during login and toggles password visibility.

### 2. The View (The Face)
Views are purely for presentation. They listen to the Controller and render accordingly.
*   **Pixel Perfect Design**: We used `SingleChildScrollView`, `Column`, and `Row` with precise padding and `BoxShadow` to match the design prototypes exactly.
*   **Decoupled Logic**: No business logic lives in the View; it simply calls methods on the Controller (e.g., `controller.login()`).

### 3. The Model (The Data)
While currently using JSON-like maps for rapid prototyping, the system is designed to use **Data Classes** for type safety when communicating with the backend.

---

## 🗺️ Navigation & Persistence

### AppNavigator & LecturerNavigator
*   **Persistent Bottom Nav**: We used `IndexedStack` in the navigators. This ensures that when a student switches from **Home** to **History**, the state of the Home tab is preserved (no unnecessary reloading).
*   **Role-Based Access**: The app distinguishes between a **Student** (using `AppNavigator`) and a **Lecturer** (using `LecturerNavigator`), providing tailored tools for each.

---

## 🚀 Backend & Networking: BaseService

The communication layer is built on a robust `BaseService` that handles:
*   **Authentication Hooks**: Automatically attaches Bearer tokens to requests from `GetStorage`.
*   **Error Handling**: Catches 401 (Unauthorized), Timeouts, and Network errors globally.
*   **JSON Serialization**: Transparently decodes UTF-8 responses for the app.

---

## 📍 Modern App Capabilities
As part of the latest updates, we've enabled:
*   **Location Services**: Integrated permissions in the `AndroidManifest.xml` to support the location verification feature.
*   **Firebase Integration**: Configured the project-level and app-level Gradle files to support Firebase SDKs.

---

> **Tip**: To add a new feature, create a new folder in `lib/features/` with `controllers/`, `views/`, and `models/` subdirectories. Register the new pages in `lib/main.dart`.
