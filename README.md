# Transit App

## Overview

This is a Flutter application designed to browse and display public transit information. The app provides a clean, modern, and user-friendly interface for users to explore transit agencies, routes, and stops, with a special focus on data from the Balearic Islands.

The application is built with a strong emphasis on a robust architecture, real-time data fetching, and an intuitive user experience following Material 3 design principles.

## Features

*   **Browse Transit Agencies:** Fetches and displays a list of transit agencies, initially focused on the Balearic Islands.
*   **Real-time Agency Search:** Allows users to search for specific agencies in real-time.
*   **Favorites System:** Users can mark agencies as favorites for quick access from the main screen. Favorite status is persisted locally.
*   **Agency Details:** A dedicated screen shows detailed information for each agency, including its name, ID, and a link to its official website.
*   **Route Listing:** Displays all routes operated by an agency, with unique icons for each transit type (Bus, Train, Metro, etc.) and official colors.
*   **Route Details & Map View:** A detailed view for each route, showing its long name, description, and an interactive map (`flutter_map`) that displays the user's location and all the stops along the route.
*   **Special Data Integration:** Includes a custom service integration for Mallorca's transit data (`mallorca_transit_services`) to handle its unique data structure, ensuring routes and stops for both of its agency IDs are fetched correctly.
*   **Theming:**
    *   **Material 3:** Modern look and feel using the latest Material Design components.
    *   **Dark/Light Mode:** Full support for both light and dark themes, which can be toggled by the user.
    *   **Custom Fonts:** Uses `google_fonts` for polished and consistent typography.

## Technical Architecture

The application is built using a modern, scalable, and service-oriented architecture.

*   **State Management:** `provider` is used for dependency injection and managing app-wide state, such as the theme and the list of favorite agencies.
*   **Navigation:** `go_router` handles all routing, providing a declarative and robust navigation system that supports passing complex objects between screens.
*   **Service Layer:** A dedicated `TransitService` abstracts all data fetching logic. It communicates with the `transit.land` API for general data and the `mallorca_transit_services` package for specific Mallorca data.
*   **Data Models:** Clear and immutable data models (`Agency`, `TransitRoute`, `Stop`, etc.) are used to represent the data from the APIs.
*   **UI:**
    *   The UI is built as a tree of composable Flutter widgets.
    *   `Card`-based layouts are used extensively to create a clean, organized, and visually appealing interface.
    *   `FutureBuilder` and `ValueListenableBuilder` are used to efficiently build the UI based on asynchronous data and state changes.
*   **Development Environment:** A Nix environment (`.idx/dev.nix`) is configured to ensure all developers have the necessary tools and a consistent development setup.

## Getting Started

To run this project:

1.  **Clone the repository.**
2.  **Ensure you have the Flutter SDK installed.**
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the application:**
    ```bash
    flutter run
    ```
