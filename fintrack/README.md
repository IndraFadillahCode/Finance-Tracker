# FinTrack

FinTrack is a personal finance management app built with Flutter. It helps users manage wallets, track transactions, categorize expenses/income, and generate financial reports.

## Features

- **Authentication**: Secure login and registration.
- **Dashboard**: Overview of balances, wallets, and recent transactions.
- **Wallet Management**: Add, view, and manage multiple wallets.
- **Transactions**: Record income, expenses, and transfers between wallets.
- **Categories**: Organize transactions by customizable categories.
- **Reports**: Generate monthly and categorized financial reports.
- **Navigation**: Bottom navigation for easy access to main features.
- **Reusable Widgets**: Modular UI components for balance, wallets, and overviews.

## Project Structure

```
lib/
├── core/           # Core config (API, color, token storage, variables)
├── features/
│   ├── auth/       # Authentication (login, register)
│   ├── dashboard/  # Dashboard overview
│   ├── wallet/     # Wallet management
│   ├── transaction/# Transaction management
│   ├── category/   # Category management
│   ├── report/     # Financial reports
│   ├── nav/        # Main navigation
│   └── widgets/    # Reusable UI components
├── utils/          # Helpers and utilities
└── main.dart       # App entry point
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart (comes with Flutter)
- An emulator or physical device

### Installation

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd fintrack
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Run the app:**
   ```sh
   flutter run
   ```

### Configuration

- API base URL is set in `lib/core/config/variables.dart`:
  ```dart
  class Variables {
    static String url = 'https://jurnal.fahrifirdaus.cloud/api/v1';
  }
  ```
- Update this if you use a different backend.

## Environment & Secrets

- No `.env` file is used by default.
- Do **not** commit sensitive keys or tokens.

## Contributing

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## License

This project is for educational purposes.
