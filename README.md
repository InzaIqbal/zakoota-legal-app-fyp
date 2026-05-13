# ⚖️ Zakoota — A Digital Freelance Marketplace for Lawyers and Clients

> **Final Year Project | Bachelor of Science in Computer Science**  
> Department of Computer Science, University of Engineering and Technology, Lahore — Narowal Campus  
> Session: 2022–2026 | Submitted: May 2026

---

## 👥 Team

| Name | Roll No |
|------|---------|
| Inza Iqbal | 2022-CS-502 |
| Rumaisa Aman | 2022-CS-518 |
| Faisal Khalid | 2022-CS-528 |
| Waleed Bin Tahir | 2022-CS-546 |

**Supervisor:** Mam Madiha Maqbool Chaudary  
**Co-Supervisor:** Miss Ariba Riaz  
**Chairman:** Dr. Muhammad Idrees

---

## 📖 Overview

**Zakoota** is a cross-platform mobile application that acts as a digital freelance marketplace dedicated to legal services in Pakistan. It bridges the gap between clients who need legal help and verified, qualified lawyers — following the model of international freelance platforms like Fiverr and Upwork, but tailored specifically for Pakistani legal services.

Pakistan currently lacks a centralized digital platform where clients can discover, evaluate, and hire qualified lawyers. Most people rely on personal referrals and direct visits to law firms, making legal access time-consuming, expensive, and nearly impossible for residents of small towns and rural areas. Zakoota solves this by providing a transparent, trusted, and AI-powered digital marketplace.

---

## 🤖 Zing AI — The AI Legal Chatbot

One of Zakoota's core innovations is **Zing AI**, an AI-powered legal chatbot accessible directly from the main screen. It is built on the **Groq API** using the **Llama 3.1** large language model, enhanced with a custom knowledge base of Pakistani legal information.

Zing AI serves two core purposes:

1. **Legal Guidance** — Helps users explain their legal issues in plain language and recommends relevant lawyers based on their situation (e.g., family law, criminal bail, property registration, tenant rights).
2. **Legal Q&A** — Answers common questions about Pakistani law in a conversational, accessible format — making basic legal knowledge available to every citizen regardless of their legal background.

> *Example: A user can ask "I am being evicted from my rented house, what are my rights under Pakistani law?" and receive an instant, accurate answer alongside a list of verified lawyers.*

---

## ✨ Key Features

### 👤 For Clients
- Register, verify identity, and set up a personal profile
- Search and filter verified lawyers by specialization (family law, criminal law, corporate law, civil litigation)
- View transparent service listings with pricing and client ratings
- Book lawyer consultations with real-time scheduling
- Secure in-app messaging with lawyers via Firebase Cloud Firestore
- Pay securely through **JazzCash** and **Easypaisa** with full transaction records
- Receive real-time push notifications via Firebase Cloud Messaging (FCM)
- Access the Zing AI chatbot for instant legal information
- Track active cases and view completed case history

### 👨‍⚖️ For Lawyers
- Sign up and submit professional credentials for verification (Pakistan Bar Council registration)
- Set up a workspace, manage service listings, and set pricing
- Accept/reject client consultation and booking requests
- Manage active cases — file sharing, invoicing, milestones
- Real-time chat with clients
- Counter-propose consultation times and meeting platforms
- View and manage ad listings on the marketplace

### 🛡️ For Admins
- Administrative dashboard for managing lawyer verifications
- User account management and dispute resolution
- Platform usage statistics and monitoring

---

## 🎯 Project Objectives

1. Build a cross-platform mobile app (Android & iOS) using Flutter.
2. Implement **Zing AI** via Groq API + Llama 3.1 with custom Pakistani legal prompt engineering.
3. Enable lawyer registration with credential verification (Pakistan Bar Council).
4. Provide a searchable, filterable directory of verified lawyers with ratings and pricing.
5. Enable secure real-time in-app messaging via Firebase Cloud Firestore.
6. Integrate **JazzCash** and **Easypaisa** payment gateways with full transaction records.
7. Build a booking and scheduling system with FCM push notifications.
8. Create an admin dashboard for verifications, accounts, and platform monitoring.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart SDK ≥ 3.2.0) |
| State Management | Flutter Riverpod + Riverpod Generator |
| Navigation | GoRouter |
| AI Chatbot | Groq API — Llama 3.1 LLM |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Payments | JazzCash, Easypaisa |
| Local Storage | Hive + SharedPreferences |
| UI | Material Design, Google Fonts, Phosphor Icons |
| Code Generation | build_runner, hive_generator |
| Auth | Firebase Auth + Google Sign-In |

---

## 📂 Project Structure

```
zakoota/
├── lib/
│   ├── core/
│   │   ├── constants/       # App-wide constants & Zing AI config
│   │   ├── router/          # GoRouter app routing
│   │   ├── services/        # Auth & core services
│   │   ├── theme/           # App theme & colors
│   │   └── widgets/         # Shared widgets
│   └── features/
│       ├── ads/             # Lawyer ad listings & booking
│       ├── articles/        # Legal articles screen
│       ├── auth/            # Login, signup, profile setup
│       ├── booking/         # Booking flow & summary
│       └── cases/           # Case management, consultations, workspace
├── assets/
│   └── images/              # App logo and assets
├── android/                 # Android-specific configuration
├── ios/                     # iOS-specific configuration
├── firebase.json            # Firebase project config
├── firestore.rules          # Firestore security rules
├── firestore.indexes.json   # Firestore indexes
└── pubspec.yaml             # Dependencies
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>= 3.2.0`
- Dart SDK `>= 3.2.0`
- Android Studio / Xcode (for device emulation)
- A Firebase project with Firestore, Auth, Storage, and FCM enabled
- A Groq API key for Zing AI

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/zakoota-fyp.git
   cd zakoota-fyp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a project at [Firebase Console](https://console.firebase.google.com/)
   - Download `google-services.json` (Android) → place in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) → place in `ios/Runner/`

4. **Configure Zing AI**
   - Add your Groq API key to `lib/core/constants/zing_ai_config.dart`

5. **Run code generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### Deploy Firestore Rules & Indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## ⚠️ Assumptions & Constraints

- The app targets Android 10+ devices with stable internet connectivity.
- Zing AI provides **general legal information only** — it does not constitute formal legal advice.
- The chatbot's knowledge is limited to the Pakistani legal knowledge base defined in the system prompt; it does not reflect real-time legislative changes.
- Version 1.0 supports JazzCash and Easypaisa only — no international payment gateways (e.g., Stripe).
- Lawyers must provide authentic Pakistan Bar Council credentials during registration.

---

## 🎓 Academic Context

This project was developed as a **Final Year Project (FYP)** submitted in partial fulfillment of the requirements for the degree of **Bachelor of Science in Computer Science** at the **University of Engineering and Technology, Lahore — Narowal Campus** (Session 2022–2026).

The project demonstrates the practical application of mobile development, AI/LLM integration, cloud services, real-time databases, and software engineering principles to solve a real-world problem in Pakistan's legal services sector.

---

## 📄 License

This project is submitted as an academic final year project. All rights reserved by the authors.
