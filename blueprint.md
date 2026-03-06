# Transit App Blueprint

## Overview

This document outlines the architecture, features, and design of the Transit App, a Flutter application for browsing public transit information.

## Implemented Features & Design

*   **Project Setup:** Standard Flutter setup with key dependencies (`http`, `go_router`, `provider`, etc.) and a Nix environment for build tools.
*   **Architecture:** Service-oriented architecture with a `TransitService`, data models, `provider` for state management, and `go_router` for navigation.
*   **UI & Design:**
    *   **Theming:** Centralized Material 3 theme with `google_fonts` and dark mode support.
    *   **Main Screen (Agency List):** A feature-rich screen with real-time search, error handling, a favorites system, and a clean `Card`-based UI.
    *   **Agency Details Screen:** A redesigned screen with a clean layout, `Card`-based information sections, and a visually intuitive list of routes with type-specific icons.
    *   **Route Details Screen:** A polished screen that displays route details, including names, description, and official colors, along with an integrated map view, all within a consistent, `Card`-based layout.
*   **Error Handling:** Custom `ApiException` and robust handling of nullable data and type mismatches from the API, resolving multiple runtime errors.

---

## Current Plan: Finalize Favorites Screen

The `FavoritesScreen` is the last remaining piece to complete the core user experience. The current implementation is functional but inefficient and lacks the polished design of the other screens.

### Steps:

1.  **Review Existing Code:** The current `favorites_screen.dart` loads all agencies from the API and then filters them based on the user's favorite IDs. This is inefficient.

2.  **Optimize Data Fetching:**
    *   Instead of fetching all agencies, the new approach will be to first get the list of favorite agency IDs from `FavoritesProvider`.
    *   Then, create a new method in `TransitService`, such as `getAgenciesByIds(List<String> ids)`, that specifically requests only the data for those favorite agencies from the API. This will significantly improve the screen's loading time.

3.  **Refine the UI/UX:**
    *   **Empty State:** Redesign the view for when the user has no favorites. Instead of a simple line of text, create a more engaging message with a large icon (e.g., `Icons.favorite_border`), a clear headline, and descriptive subtext.
    *   **List Item Design:** Redesign the list items to be consistent with the main screen. Each favorite will be a `Card` with a `ListTile`.
    *   **Remove from Favorites:** The trailing icon will be a filled-in heart (`Icons.favorite`). Tapping this icon will immediately remove the agency from the favorites list, providing instant feedback to the user.

4.  **Implement the Changes:**
    *   Add the `getAgenciesByIds` method to `lib/services/transit_service.dart`.
    *   Modify `lib/screens/favorites_screen.dart` to use the new data fetching logic.
    *   Rebuild the `build` method to implement the new empty state and list item design.

5.  **Final Testing:**
    *   Thoroughly test the favorites feature: add agencies, view them on the favorites screen, and remove them.
    *   Ensure the screen handles all states correctly (loading, empty, has favorites).
    *   Confirm that the entire application flow is smooth and bug-free.
