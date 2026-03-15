# 🏢 CRM  - Professional Mobile CRM App

[![Flutter](https://flutter.dev/images/flutter-logo-sharing.png)](https://flutter.dev) [![Riverpod](https://img.shields.io/badge/State-Riverpod-blue?logo=flutter)](https://riverpod.dev) [![Dart 3](https://img.shields.io/badge/Dart-3.x-brightblue)](https://dart.dev) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**CRM** is a comprehensive, production-ready Customer Relationship Management (CRM) mobile application built with Flutter. Designed for sales teams, it provides real-time synchronization with backend APIs to manage leads, contacts, deals, tasks, expenses, and more. Supports iOS, Android, Web, Desktop, Linux & Windows.

## ✨ Features

- **📱 Authentication**: Secure login, forgot password, auto-login with JWT tokens
- **📊 Dashboard**: KPI cards (leads/deals/revenue/tasks), recent activities, quick actions, notifications
- **💼 Sales/Deals**: Kanban pipeline, list with filters (status/category/company/search), details with activities/logs, CRUD operations
- **👥 Contacts**: Searchable lists, company-linked details, call/email actions, CRUD
- **🏢 Companies**: Search by name/country, KAM assignment, linked contacts/deals, CRUD
- **✅ Tasks**: Filter by status/assignee/company, logs/history, status updates, CRUD
- **💰 Expenses**: List, details, forms for tracking
- **💱 Currency**: Management & conversion
- **⚙️ Settings**: Light/Dark theme, notifications, profile
- **👨‍💼 Admin**: Users management, status configuration
- **🚀 Performance**: In-memory caching, N+1 query batching, lazy tab loading, shimmer effects
- **🎨 Custom UI**: CRM Cards/Buttons/TextFields, avatars, loading/error states, slidable actions
- **🔄 Offline-First**: Secure storage, retry logic, optimistic updates

## 📱 Screenshots

Add screenshots to `assets/images/`:

```
![Dashboard](assets/images/dashboard.png)
![Sales Pipeline](assets/images/sales_list.png)
![Contact Detail](assets/images/contact_detail.png)
![Tasks](assets/images/tasks.png)
```

## 🛠 Tech Stack

| Category | Technologies |
|----------|--------------|
| **Framework** | Flutter 3.x, Dart 3.x |
| **State** | Riverpod 2.x |
| **Network** | Dio 5.x, flutter_secure_storage |
| **Navigation** | GoRouter |
| **Data** | Freezed + json_serializable |
| **UI/UX** | Shimmer, cached_network_image, flutter_svg, flutter_slidable |
| **Notifications** | flutter_local_notifications |
| **Utils** | intl, url_launcher, timezone |

## 🚀 Quick Start

```bash
# Clone & Setup
git clone <repo> crm-pro
cd crm_app
flutter pub get

# Run (iOS/Android/Web/Desktop)
flutter run

# Build APK (release)
flutter build apk --release
```

**Backend API**: `https://be-crm-production-a948.up.railway.app`
- See [CRM_API_Postman_Collection.json](CRM_API_Postman_Collection%20(1).json) for full endpoints (Auth/Users/Companies/Contacts/Tasks/Sales).

## 🏗 Architecture (Clean Architecture)

```
lib/
├── core/          # Network, Theme, Errors, Constants
├── data/          # Repositories, Models
├── presentation/  # Providers, Pages, Widgets
├── main.dart      # Entry
└── app.dart       # Root App Widget
```

```
UI (Riverpod) → Repositories → Dio API Client → Backend
         ↑
     Caching & Error Handling
```

## 🎯 Performance Optimizations

- **Caching**: In-memory for companies/users.
- **Batch Loading**: Single API calls for N+1 relations (sales/tasks/contacts).
- **Lazy Loading**: Tabs load on-demand.
- **Pagination Ready**: ListView.builder structure.

See [PERFORMANCE_FIX_PLAN.md](PERFORMANCE_FIX_PLAN.md).

## 📁 Project Structure

```
crm_app/
├── lib/
│   ├── core/network/api_client.dart      # Dio setup + interceptors
│   ├── data/repositories/*.dart           # All CRUD repos
│   ├── presentation/providers/*.dart     # 10+ providers
│   └── presentation/pages/**/*.dart      # 20+ screens
├── assets/crm_icon.png
├── pubspec.yaml
└── README.md
```

## 🤝 Contributing

1. Fork & PR.
2. See [TODO.md](TODO.md) & [SPEC.md](SPEC.md).
3. Run `flutter analyze` & `flutter test`.

## 📄 License

MIT - See [LICENSE](LICENSE) (add if needed).

---

⭐ **Star on GitHub** | 🐛 **Report Issues** | 💬 **Discussions**

