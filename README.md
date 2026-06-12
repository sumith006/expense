# 💰 Finance Pro - Expense & Task Manager

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-%2302569B.svg?style=for-the-badge&logo=Riverpod&logoColor=white)](https://riverpod.dev)
[![Hive](https://img.shields.io/badge/Hive-%23FDC210.svg?style=for-the-badge&logo=Hive&logoColor=black)](https://docs.hivedb.dev/)

Finance Pro is a powerful, modern, and high-performance financial management and task tracking application built with Flutter. It features a unique **Neo-Brutalism** design language that makes financial tracking not just functional, but visually striking.

---

## ✨ Key Features

### 📊 Advanced Financial Tracking
- **Expense & Income Logging**: Easily log your daily transactions with detailed categories.
- **Budget Management**: Set monthly budgets for different categories and track your spending progress.
- **Recurring Transactions**: Automate your monthly bills and regular income.
- **Visual Analytics**: Interactive charts (Pie and Bar) to visualize your spending habits and net balance.

### 📝 Integrated Task Management
- **Quick Tasks**: Manage your daily to-dos right from the dashboard.
- **Priority System**: Categorize tasks by priority (High, Medium, Low).
- **Link Expenses to Tasks**: Keep track of financial obligations related to your tasks.

### 🔒 Privacy & Security
- **Biometric Lock**: Secure your financial data with Fingerprint or Face ID.
- **PIN Protection**: Set up a secure PIN for an extra layer of security.
- **Local Storage**: All your data is stored securely on your device using Hive DB.

### ☁️ Backup & Restore
- **Google Drive Integration**: Backup your data to the cloud and restore it on any device.

### 🎨 Neo-Brutalism UI
- Vibrant colors, bold borders, and high-contrast gradients.
- Smooth animations and transitions using `flutter_staggered_animations`.
- Dark Mode support with a deep, modern aesthetic.

---

## 📸 Screenshots

| Dashboard | Reports | Tasks |
| :---: | :---: | :---: |
| ![Dashboard](https://raw.githubusercontent.com/sumith006/expense/main/screenshots/dashboard.png) | ![Reports](https://raw.githubusercontent.com/sumith006/expense/main/screenshots/reports.png) | ![Tasks](https://raw.githubusercontent.com/sumith006/expense/main/screenshots/tasks.png) |

| Budget | Settings | Profile |
| :---: | :---: | :---: |
| ![Budget](https://raw.githubusercontent.com/sumith006/expense/main/screenshots/budget.png) | ![Settings](https://raw.githubusercontent.com/sumith006/expense/main/screenshots/settings.png) | ![Profile](https://raw.githubusercontent.com/sumith006/expense/main/screenshots/profile.png) |

---

## 🚀 Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Database**: Hive CE (Local NoSQL)
- **Architecture**: MVVM (Model-View-ViewModel)
- **UI Components**: Google Fonts, Lucide Icons (IconHelper)
- **Animations**: Flutter Staggered Animations, Animated Text Kit

---

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/sumith006/expense.git
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run build runner (for Hive adapters)**
   ```bash
   dart run build_runner build
   ```
4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Developed with ❤️ by [Sumith](https://github.com/sumith006)
