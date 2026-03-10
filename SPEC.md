# CRM SaaS Mobile Application Specification

## 1. Project Overview

**Project Name:** CRM Pro Mobile
**Bundle Identifier:** com.crmpro.mobile
**Core Functionality:** A comprehensive CRM (Customer Relationship Management) mobile application that enables sales teams to manage leads, contacts, deals, and tasks with real-time synchronization to a backend API.
**Target Users:** Sales representatives, account managers, and CRM administrators
**iOS Version Support:** iOS 12.0+
**Flutter SDK:** Latest stable (3.x)

---

## 2. API Endpoints Summary

Based on the Postman collection, the API base URL is: `https://be-crm-production-a948.up.railway.app`

### Authentication
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/logout` - Logout (revoke token)
- `POST /api/auth/change-password` - Change password

### Users
- `GET /api/users` - List all users
- `GET /api/users/{id}` - Get user by ID
- `PATCH /api/users/me` - Update profile
- `POST /api/users` - Create user (admin)
- `PUT /api/users/{id}` - Update user (admin)
- `PUT /api/users/{id}/password` - Set password (admin)

### Companies
- `GET /api/companies` - List companies (search, country, kamUserId)
- `POST /api/companies` - Create company
- `GET /api/companies/{id}` - Get company
- `PUT /api/companies/{id}` - Update company
- `DELETE /api/companies/{id}` - Delete company

### Contacts
- `GET /api/contacts` - List contacts (companyId, search)
- `POST /api/contacts` - Create contact
- `GET /api/contacts/{id}` - Get contact
- `PUT /api/contacts/{id}` - Update contact
- `DELETE /api/contacts/{id}` - Delete contact

### Tasks
- `GET /api/tasks` - List tasks (status, companyId, assignToUserId, assignByUserId, search)
- `POST /api/tasks` - Create task
- `GET /api/tasks/{id}` - Get task
- `PUT /api/tasks/{id}` - Update task
- `PATCH /api/tasks/{id}/status` - Change task status
- `GET /api/tasks/{id}/logs` - Get task logs
- `DELETE /api/tasks/{id}` - Delete task

### Sales/Deals
- `GET /api/sales` - List sales (status, companyId, category, createdByUserId, search)
- `POST /api/sales` - Create sale
- `GET /api/sales/{id}` - Get sale
- `PUT /api/sales/{id}` - Update sale
- `PATCH /api/sales/{id}/status` - Change sale status
- `GET /api/sales/{id}/logs` - Get sale logs
- `GET /api/sales/{id}/activities` - List activities
- `POST /api/sales/{id}/activities` - Create activity
- `PUT /api/sales/{id}/activities/{activityId}` - Update activity
- `DELETE /api/sales/{id}/activities/{activityId}` - Delete activity
- `DELETE /api/sales/{id}` - Delete sale

### Status Config
- `GET /api/status-config` - Get taskStatuses, salesCategories, salesStatuses

### Company Profile
- `GET /api/company-profile` - Get company profile
- `PUT /api/company-profile` - Update company profile (admin)

---

## 3. UI/UX Specification

### Color Palette
- **Primary:** #2563EB (Blue 600) - Main brand color
- **Primary Dark:** #1D4ED8 (Blue 700)
- **Primary Light:** #3B82F6 (Blue 500)
- **Secondary:** #10B981 (Emerald 500) - Success/positive
- **Accent:** #8B5CF6 (Violet 500) - Special actions
- **Warning:** #F59E0B (Amber 500)
- **Error:** #EF4444 (Red 500)
- **Background:** #F8FAFC (Slate 50)
- **Surface:** #FFFFFF
- **Card:** #FFFFFF
- **Text Primary:** #1E293B (Slate 800)
- **Text Secondary:** #64748B (Slate 500)
- **Text Tertiary:** #94A3B8 (Slate 400)
- **Border:** #E2E8F0 (Slate 200)
- **Divider:** #F1F5F9 (Slate 100)

### Typography
- **Font Family:** System default (San Francisco on iOS)
- **Heading 1:** 28px, FontWeight.bold
- **Heading 2:** 24px, FontWeight.w600
- **Heading 3:** 20px, FontWeight.w600
- **Heading 4:** 18px, FontWeight.w500
- **Body Large:** 16px, FontWeight.normal
- **Body:** 14px, FontWeight.normal
- **Body Small:** 12px, FontWeight.normal
- **Caption:** 11px, FontWeight.normal
- **Button:** 14px, FontWeight.w600

### Spacing System (8pt Grid)
- **xs:** 4px
- **sm:** 8px
- **md:** 16px
- **lg:** 24px
- **xl:** 32px
- **xxl:** 48px

### Border Radius
- **Small:** 8px
- **Medium:** 12px
- **Large:** 16px
- **XLarge:** 24px
- **Full:** 9999px (circular)

### Shadows
- **Small:** BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))
- **Medium:** BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 4))
- **Large:** BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: Offset(0, 8))

---

## 4. Screen Structure

### Authentication Flow
1. **Splash Screen** - App logo, loading indicator
2. **Login Screen** - Email, password fields, login button, forgot password link
3. **Forgot Password Screen** - Email field, send reset link

### Main App Structure (Bottom Navigation)
1. **Dashboard** - Home icon
2. **Leads** - Target icon (Sales/Deals)
3. **Contacts** - People icon
4. **Tasks** - Checklist icon
5. **More** - Menu icon (settings, profile, etc.)

### Screen Hierarchy

```
├── Auth
│   ├── Login Screen
│   └── Forgot Password Screen
│
├── Main (with Bottom Navigation)
│   ├── Dashboard
│   │   ├── KPI Cards Row
│   │   ├── Recent Activities
│   │   ├── Quick Actions
│   │   └── Notifications
│   │
│   ├── Leads/Deals (Sales)
│   │   ├── Sales List Screen
│   │   ├── Kanban Pipeline Screen
│   │   ├── Sale Detail Screen
│   │   ├── Add/Edit Sale Screen
│   │   └── Sale Activity Screen
│   │
│   ├── Contacts
│   │   ├── Contacts List Screen
│   │   ├── Contact Detail Screen
│   │   ├── Add/Edit Contact Screen
│   │   └── Company Detail Screen
│   │
│   ├── Tasks
│   │   ├── Tasks List Screen
│   │   ├── Task Detail Screen
│   │   ├── Add/Edit Task Screen
│   │   └── Task Logs Screen
│   │
│   └── More
│       ├── Profile Screen
│       ├── Settings Screen
│       ├── Users Screen (Admin)
│       ├── Companies Screen (Admin)
│       ├── Status Config (Admin)
│       └── Logout
│
└── Modals
    ├── Filter Modal
    ├── Search Modal
    └── Confirmation Dialogs
```

---

## 5. Functionality Specification

### Authentication
- **Login:** Email + password → receive JWT token → store securely
- **Auto Login:** Check stored token on app start, validate if still valid
- **Logout:** Clear tokens, navigate to login
- **Forgot Password:** Email input → send reset request

### Dashboard
- **KPI Cards:** Total leads, Total deals, Revenue this month, Tasks pending
- **Recent Activities:** Timeline of latest activities across all modules
- **Quick Actions:** Add lead, Add contact, Add task buttons
- **Notifications:** Unread notifications badge

### Leads/Deals (Sales)
- **List View:** Filterable by status, category, company
- **Kanban View:** Drag-and-drop deal stages (Lead → Prospect → Negotiation → Closed)
- **Deal Detail:** All deal info, activities timeline, status history
- **Add/Edit:** Form with validation
- **Categories:** Hot, Warm, Cold
- **Statuses:** Lead, Prospect, Negotiation, Closed, Disqualified

### Contacts
- **List View:** Searchable, filterable by company
- **Contact Detail:** Name, company, designation, email, phone, linked deals
- **Actions:** Call (phone dialer), Email (mailto)
- **Add/Edit:** Form with required fields validation

### Tasks
- **List View:** Filterable by status, assigned user, company
- **Task Detail:** Title, description, due date, assignee, status
- **Add/Edit:** Form with due date picker
- **Status:** Pending, In Progress, Completed, Cancelled
- **Logs:** Activity history for each task

### Companies
- **List View:** Searchable by name, country
- **Company Detail:** Name, location, country, KAM user, contacts, deals

---

## 6. Technical Specification

### Architecture: Clean Architecture
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── blocs/
    ├── pages/
    └── widgets/
```

### State Management: Riverpod 2.x

### Key Dependencies
- `flutter_riverpod` - State management
- `dio` - HTTP client
- `flutter_secure_storage` - Secure token storage
- `go_router` - Navigation
- `freezed` + `json_serializable` - Data models
- `intl` - Date formatting
- `url_launcher` - Call/email actions
- `shimmer` - Loading skeletons
- `flutter_slidable` - Swipe actions

### API Service Layer
- Base API client with interceptors
- Token authentication
- Error handling with custom exceptions
- Retry logic (3 attempts)
- Request/response logging

### Model Generation
Models for:
- User
- Company
- Contact
- Task
- Sale/Deal
- SaleActivity
- StatusConfig
- AuthResponse

---

## 7. Widget Components

### Custom Widgets
- **CRMButton** - Primary, secondary, text variants
- **CRMTextField** - With validation, prefix/suffix icons
- **CRMCard** - Elevated card with shadow
- **KPICard** - Icon, value, label, trend indicator
- **StatusBadge** - Colored status indicator
- **AvatarWidget** - User/contact avatar with fallback
- **EmptyStateWidget** - No data illustration
- **LoadingWidget** - Shimmer loading states
- **ErrorWidget** - Error message with retry
- **SearchField** - Search input with clear button

---

## 8. Animations & Transitions

- **Page Transitions:** Fade + slide (300ms ease-out)
- **Card Press:** Scale down to 0.98 (100ms)
- **Button Press:** Opacity to 0.8 (100ms)
- **List Items:** Staggered fade-in on load
- **Pull to Refresh:** Standard Material refresh
- **Loading:** Shimmer effect on cards

---

## 9. Error Handling

- Network errors: Show retry dialog
- Auth errors (401): Auto logout, redirect to login
- Validation errors: Inline error messages
- Server errors: Generic error with support contact

---

## 10. Performance

- **List Optimization:** ListView.builder with pagination
- **Image Caching:** Cached network images
- **Lazy Loading:** Load more on scroll
- **Debounce Search:** 300ms debounce on search input

---

*This specification serves as the blueprint for CRM Pro Mobile app development.*

