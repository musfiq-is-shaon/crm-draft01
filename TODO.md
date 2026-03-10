# Add Company Button Implementation

## Task
Add "Add Company" button beside the company select dropdown in:
1. Add New Deal page (SaleFormPage)
2. Add New Task page (TaskFormPage)

Note: Add New Contact page already has this feature implemented.

## Steps
- [x] 1. Update SaleFormPage in sale_detail_page.dart - Add "Add Company" button next to company dropdown
- [x] 2. Update TaskFormPage in task_detail_page.dart - Add "Add Company" button next to company dropdown

## Implementation Details
- Use the same pattern as ContactFormPage
- Add IconButton with add_circle_outline icon
- Navigate to CompaniesListPage with openCreateDialog: true
- Return the newly created company ID and auto-select it

