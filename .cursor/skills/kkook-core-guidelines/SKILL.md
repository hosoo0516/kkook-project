---
name: kkook-core-guidelines
description: Global architectural guidelines, UI/UX philosophy, and Firebase rules for the 'KKOOK(꾹)' Stop-Smoking Web/Mobile app.
globs: lib/**/*.dart, web/**/*
disable-model-invocation: true
---

# KKOOK (꾹) - Core Project Guidelines

You are the Lead Full-Stack Developer for "KKOOK (꾹)", a stop-smoking assistant web/mobile app built with Flutter and Firebase[cite: 399, 408, 409]. Your main goal is to deliver a minimal, burden-free, and high-performance product following the Software Requirements Specification (SRS)[cite: 399, 412].

## 1. Project Philosophy & UX Rules (CRITICAL)
* [cite_start]**Burden-Free UX:** KKOOK avoids punishing the user for failures[cite: 444, 481, 483]. [cite_start]Design components focused on highlighting small successes and gradual progress[cite: 444, 483].
* **Minimal Apple-Style UI:** Strictly adhere to a minimal, clean, card-based interface resembling iOS native design[cite: 416, 443, 480]. Use a Blue primary color palette with crisp, readable typography[cite: 480].
* [cite_start]**"One Screen, One Question" Onboarding:** When working on `onboarding_screen.dart`, always structure the onboarding flow to ask exactly one question per screen (e.g., Duration, Count, Price, Pack quantity, Start date) with a visual step indicator (e.g., 3/5)[cite: 423, 424, 473, 476, 486].

## 2. Technical Stack & State Management
* **Frontend:** Flutter (Web/Mobile cross-platform compilation friendly)[cite: 415, 450, 465]. Avoid importing `dart:io` or `dart:html` directly; use conditional imports where necessary to prevent breaking the web build[cite: 415, 450].
* [cite_start]**Backend:** Firebase (Authentication, Firestore Cloud NoSQL)[cite: 406, 409, 411]. 
* **State Management:** Keep strict separation between UI Layers and Business/Data layers using clean state notifiers (e.g., Riverpod or Bloc).

## 3. Core Feature Implementations

### A. Immediate Mode (Cold Turkey) - `cold_turkey_dashboard.dart`
* [cite_start]**Timestamp-Based Calculation:** NEVER store the incremental stop-smoking time directly[cite: 482]. [cite_start]Always fetch the `quitStartDate` (timestamp) from Firestore and calculate elapsed time reactively using `[Current Time - quitStartDate]` down to the second.
* [cite_start]**Real-time Savings Formula:** Dynamically calculate saved money in real-time using: `Elapsed Time * (Daily Cigarette Count / 24 Hours) * Price per Single Cigarette`[cite: 426, 427, 495].
* **WHO Timeline:** Bind health recovery updates dynamically based on the calculated elapsed time[cite: 427, 476].

### B. Gradual Reduction Mode - `gradual_dashboard.dart`
* [cite_start]**Long Press Action:** To record smoking events, the main action button MUST trigger via a **Long Press (`GestureDetector(onLongPress: ...)` or similar)** instead of a single tap[cite: 479, 489, 499]. [cite_start]This avoids accidental presses and aligns with the "KKOOK (꾹)" pressed-down naming concept[cite: 407, 479].
* **Auto-Reduction & Reset:** Daily quota resets strictly at `00:00:00` without carrying over left-overs[cite: 432]. Implement logic to handle the monthly reduction rate (default -10%, but user-adjustable)[cite: 431, 432].
* [cite_start]**Zero Limit State:** When today's quota reaches `0`, change the status message to '금일 한도 소진' (Daily quota exhausted) along with motivational words instead of congratulatory remarks[cite: 434].

## 4. Coding Standard
* [cite_start]Follow strict architecture: UI Layer (`lib/screens/`), Data/Service Layer (`lib/services/auth_service.dart`, `lib/services/firestore_service.dart`)[cite: 490, 491].
* Ensure all UI interactions respond under 1 second[cite: 438].
* [cite_start]Prefer `const` constructors wherever possible to maximize rendering performance[cite: 416].
