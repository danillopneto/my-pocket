---
applyTo: '**/*screen.dart'
---
# Screen File Structure and Best Practices

When creating or modifying screen files in the my-pocket codebase, follow these guidelines:

## File Organization

1. **File Comment Header**
   - Always start with a file comment describing the screen's purpose
   - Example: `// Dashboard screen with summary and charts`

2. **Import Structure**
   - First import Flutter packages
   - Then external packages like easy_localization
   - Then local imports, organized by models, services, widgets, utils

3. **Class Naming**
   - Name screen classes with PascalCase, followed by "Screen" suffix
   - Example: `class DashboardScreen extends StatefulWidget`

4. **State Variables & Services**
   - Declare all services as final instance variables
   - Group related state variables together
   - Include proper final/non-final declarations

## UI Implementation

1. **Widget Structure**
   - Use `ScaffoldWithDrawer` for consistent app layout
   - Set the proper `selected` and `titleKey` parameters
   - Place the main content within the `body` parameter

2. **Authentication**
   - Always use `withCurrentUser` or `withCurrentUserAsync` utility
   - Provide a fallback UI for unauthenticated users

3. **Data Loading**
   - Use `StreamBuilder` or `FutureBuilder` for data that changes
   - Show loading indicators while data is loading
   - Handle empty states and errors appropriately

4. **Text & Formatting**
   - Use `tr()` extension for all user-facing text (from easy_localization)
   - Use services for formatting:
     - `DateFormatService` for dates
     - `CurrencyFormatService` for monetary values

5. **State Management**
   - Check `mounted` before using `setState` after async operations
   - Dispose controllers in the `dispose` method

## Layout & Responsiveness

1. **Responsive Design**
   - Use `LayoutBuilder` for responsive layouts
   - Adapt UI based on available width using conditional layout

2. **Component Organization**
   - Use `Card` widgets for grouping related content
   - Use proper spacing with `SizedBox`
   - Follow consistent padding patterns

## Error Handling & User Experience

1. **Loading States**
   - Use `AppLoadingIndicator` while data is loading
   - Show appropriate messages for empty states

2. **Error Messages**
   - Display user-friendly error messages using `ScaffoldMessenger`
   - Always localize error messages

Follow these guidelines to maintain consistency across all screen files in the codebase.