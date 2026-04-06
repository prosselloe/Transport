# Transport Balears Blueprint

## Overview

This document outlines the architecture, features, and design of Transport Balears, a Flutter application for browsing public transit information in the Balearic Islands, with a special focus on the services provided by the Consorci de Transports de Mallorca.

## Implemented Features & Design

*   **Agencies Screen**: Displays a grid of transit agencies, distinguishing between the Consorci de Transports de Mallorca and others from the Onestop API.
*   **Agency/Stop Details Screen**:
    *   Shows details for a selected agency or a specific stop.
    *   Displays a map with all stops for an agency or just the selected stop.
    *   The map includes the user's current location.
    *   Lists all the routes associated with the agency or stop.
*   **Route Details Screen**:
    *   Displays the path of a selected route on a map, including all its stops.
    *   Shows a list of all stops for the route.
    *   The AppBar color dynamically adapts to the route's color for a better user experience.
*   **Interactive Stop Elements (List and Map)**:
    *   Both the stop markers on the maps and the items in the stop lists are interactive.
    *   If a stop provides an external URL (from Transit.land), tapping it will open the URL in a browser.
    *   If there's no URL but the stop belongs to the "Consorci de Transports de Mallorca" (prefixed with `mallorca::`), tapping it will navigate to the stop's detail screen.
    *   For other cases, the tap action is disabled to prevent navigation to empty or irrelevant screens.
*   **Theming**:
    *   The app uses a custom theme with a primary color of `#0175C2`.
    *   A `ThemeProvider` is used to allow users to switch between light, dark, and system theme modes.
*   **Splash Screen**: A native splash screen is implemented for a professional app launch.
