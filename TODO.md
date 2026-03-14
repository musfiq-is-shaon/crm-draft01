# Delete Account Functionality TODO

## Plan Overview
Add delete account feature using soft-delete (PATCH /api/users/me with isActive: false) + logout.

## Steps to Complete
- [x] 1. Update app_constants.dart: Add `usersMeDeactivate` constant
- [x] 2. Update user_repository.dart: Add `deactivateAccount()` method
- [x] 3. Update auth_provider.dart: Add `deleteAccount()` notifier method
- [x] 1. Update app_constants.dart: Add `usersMeDeactivate` constant
- [x] 2. Update user_repository.dart: Add `deactivateAccount()` method
- [x] 3. Update auth_provider.dart: Add `deleteAccount()` notifier method
- [x] 4. Update more_page.dart: Add "Delete Account" menu item with confirmation dialog
- [x] 5. Test functionality (flutter analyze passed with expected warnings)
- [x] 6. Mark complete

**Delete account functionality added successfully!**

Navigate to More page → scroll to bottom → tap "Delete Account" → confirm to deactivate account and logout.

