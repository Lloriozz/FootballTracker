# FootballTracker ⚽️

Welcome to **FootballTracker**! This is a modern, full-stack iOS application designed for football enthusiasts to track their favorite teams, players, leagues, and live match scores.

Built with a premium "Glassmorphism" UI aesthetic on the frontend and a scalable, custom Node.js caching proxy backend, this project ensures lightning-fast load times and a seamless user experience.

---

## 🌟 Main Features

- **Real-Time Scores & Fixtures**: Stay up to date with live matches, upcoming fixtures, and past results.
- **Team & League Tracking**: Follow your favorite teams and leagues to get personalized updates directly on your home feed.
- **Player Stats**: Deep dive into individual player statistics across different seasons.
- **Custom Backend Caching**: The Node.js backend acts as an intelligent proxy to the API-Football service, caching responses to dramatically improve speed and prevent API rate-limit exhaustion.
- **Premium Glassmorphism UI**: Beautifully designed iOS interface using SwiftUI, dynamic blurs, and immersive background imagery.

### 📸 Screenshots

Here is a glimpse of FootballTracker in action!

| Sign In / Sign Up | Home Screen | User Profile |
|:---:|:---:|:---:|
| <img src="FootballTracker/Resources/Assets/DemoScreens/signin_singup.png" width="250"> | <img src="FootballTracker/Resources/Assets/DemoScreens/homescreen.png" width="250"> | <img src="FootballTracker/Resources/Assets/DemoScreens/profile_screen.png" width="250"> |

| League Details 1 | League Details 2 | Team Details 1 |
|:---:|:---:|:---:|
| <img src="FootballTracker/Resources/Assets/DemoScreens/league_screen1.png" width="250"> | <img src="FootballTracker/Resources/Assets/DemoScreens/league_screen2.png" width="250"> | <img src="FootballTracker/Resources/Assets/DemoScreens/team_screen1.png" width="250"> |

| Team Details 2 | Player Search | Player Stats |
|:---:|:---:|:---:|
| <img src="FootballTracker/Resources/Assets/DemoScreens/team_screen2.png" width="250"> | <img src="FootballTracker/Resources/Assets/DemoScreens/player_screen1.png" width="250"> | <img src="FootballTracker/Resources/Assets/DemoScreens/player_screen2.png" width="250"> |

---

## 🛠 Tech Stack

**Frontend (iOS)**
- **Swift & SwiftUI**: 100% written in modern Swift using the new `@Observable` macro (iOS 17+).
- **Architecture**: MVVM (Model-View-ViewModel) with structured Dependency Injection.

**Backend (Node.js)**
- **Express & TypeScript**: Strongly-typed RESTful API.
- **Prisma & MySQL**: Database ORM used for managing users, sessions, favorites, and cached payloads.
- **Argon2 & JWT**: Secure password hashing and robust token-based authentication.

---

## 🚀 Getting Started

Follow these step-by-step instructions to get the backend and iOS app running locally on your machine.

### 1. Prerequisites
- **Node.js** (v18+) and `npm`
- **MySQL Database** (Ensure it is running locally or remotely)
- **Xcode** 15+ (for running the iOS app)

### 2. Set Up the Backend
1. Open your terminal and navigate to the backend folder:
   ```bash
   cd backend
   ```
2. Install the Node dependencies:
   ```bash
   npm install
   ```
3. Copy the example environment variables file to create your own `.env`:
   ```bash
   cp .env.example .env
   ```
4. Open the `.env` file and configure it:
   - Provide your `DATABASE_URL` (e.g. `mysql://user:password@localhost:3306/football_tracker`)
   - Generate a random `JWT_SECRET`.

### 3. Adding Your API-Football Key
The app gets its data from the [API-Football](https://www.api-football.com/) service via RapidAPI. To get your own data:
1. Create an account on [RapidAPI API-Football](https://rapidapi.com/api-sports/api/api-football/).
2. Subscribe to the free tier to get an API Key.
3. Open the `.env` file in the `backend/` folder.
4. Set the `API_FOOTBALL_KEY` variable to your newly generated key:
   ```env
   API_FOOTBALL_KEY="your_api_key_here"
   ```

### 4. Initialize Database and Run Server
1. Sync the Prisma schema to your MySQL database:
   ```bash
   npx prisma db push
   ```
2. Start the development server:
   ```bash
   npm run dev
   ```
   *The backend should now be listening on `http://localhost:3000`.*

### 5. Run the iOS App
1. Open Xcode.
2. Select File > Open... and choose the `FootballTracker.xcodeproj` file (or generate it if you are using `xcodegen`).
3. Select an iOS 17+ Simulator (e.g., iPhone 15 Pro).
4. Hit **Run** (`Cmd + R`).
5. Sign up for a new account in the app and enjoy tracking your favorite teams!

---

## 📄 License

This project is licensed under the MIT License.
