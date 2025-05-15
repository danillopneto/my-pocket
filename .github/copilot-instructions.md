# Custom Copilot Instructions for my-pocket Codebase

1. **Localization & Text**
   - Always use language files in `lib/l10n/` (e.g., `en.json`, `es.json`, `pt.json`) for all user-facing labels, messages, and text. Never hardcode display text in widgets, screens, or services.
   - When adding new text, update all relevant language files and use the localization mechanism to retrieve strings.

2. **Currency & Decimal Handling**
   - Always use `currency_format_service.dart` (or similar) for formatting, parsing, and displaying currency or decimal values. Do not manually format currency or decimals in UI or business logic.
   - When adding new features that involve money or decimal values, ensure all calculations and displays use the currency format service.

3. **Date & Time Handling**
   - Always use the `date_format_service.dart` (or similar) for formatting, parsing, and displaying dates or times. Never manually format dates in UI or business logic.
   - When adding new features that involve dates, ensure all date manipulations and displays use the date format service.

4. **Service Usage**
   - Place all business logic and data manipulation in the appropriate service under `lib/services/`. UI code should call these services rather than duplicating logic.
   - When creating new services, follow the naming convention: `<feature>_service.dart`.

5. **Models**
   - Define all new data models in `lib/models/`. Use consistent naming and structure. Update models to support localization and formatting as needed.

6. **Widgets & Screens**
   - Place reusable UI components in `lib/widgets/` and screens in `lib/screens/`.
   - When creating new widgets/screens, ensure all text is localized and all currency/date values are formatted using the appropriate services.

7. **General Patterns**
   - Prefer composition over inheritance for widgets and services.
   - Use dependency injection for services where possible.
   - Follow existing code style and structure for consistency.

> **Summary:**
> - Always use language files for text.
> - Always use currency/date format services for values.
> - Place logic in services, UI in widgets/screens.
> - Keep code consistent.
