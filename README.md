# Transport Balears

## Visió General

Aquesta és una aplicació Flutter dissenyada per consultar i mostrar informació del transport públic. L'aplicació ofereix una interfície neta, moderna i fàcil d'usar perquè els usuaris explorin agències, rutes i parades de transport, amb un enfocament especial en les dades de les Illes Balears.

L'aplicació està construïda amb un fort èmfasi en una arquitectura robusta, l'obtenció de dades en temps real i una experiència d'usuari intuïtiva seguint els principis de disseny de Material 3.

## Característiques

*   **Consultar Agències de Transport:** Obté i mostra una llista d'agències de transport, inicialment centrada a les Illes Balears.
*   **Cerca d'Agències en Temps Real:** Permet als usuaris cercar agències específiques en temps real.
*   **Sistema de Favorits:** Els usuaris poden marcar agències com a favorites per accedir-hi ràpidament des de la pantalla principal. L'estat de favorit es manté localment.
*   **Detalls de l'Agència:** Una pantalla dedicada mostra informació detallada de cada agència, incloent-hi el nom, l'ID i un enllaç al seu lloc web oficial.
*   **Llistat de Rutes:** Mostra totes les rutes operades per una agència, amb icones úniques per a cada tipus de transport (Bus, Tren, Metro, etc.) i colors oficials.
*   **Detalls de la Ruta i Vista del Mapa:** Una vista detallada per a cada ruta, que mostra el seu nom llarg, descripció i un mapa interactiu (`flutter_map`).
    *   El mapa intenta mostrar primer la geometria precisa de la ruta des de l'API de `transit.land`.
*   **Visualització de Parades:** Mostra totes les parades al llarg d'una ruta, tant al mapa com en una llista.

## Arquitectura i Disseny

*   **Gestió d'Estat:** `provider` s'utilitza per a la injecció de dependències i la gestió de l'estat de l'aplicació, com el tema i la llista d'agències favorites.
*   **Navegació:** `go_router` gestiona tota la navegació, proporcionant un sistema declaratiu i robust que suporta el pas d'objectes complexos entre pantalles.
*   **Capa de Serveis:** Un `TransitService` dedicat abstrau tota la lògica d'obtenció de dades.
    *   Es comunica amb l'API de `transit.land` per a dades generals i amb el paquet `mallorca_transit_services` per a dades específiques de Mallorca.
    *   **Obtenció de Dades Optimizada:** La capa de servei està dissenyada per obtenir i combinar dades de manera eficient. Per exemple, a la pantalla de detalls de la ruta, conserva la informació de la ruta existent while obtenint detalls addicionals com la geometria i les parades, evitant la pèrdua de dades.
*   **Models de Dades:** S'utilitzen models de dades clars i immutables (`Agency`, `TransitRoute`, `Stop`, etc.) per representar les dades de les APIs.
*   **Interfície d'Usuari:**
    *   L'aplicació segueix els principis de **Material 3**.
    *   Inclou un **tema fosc i clar** que es pot canviar manualment.
    *   `flutter_map` s'utilitza per a la visualització de mapes interactius.

## Crèdits

Aquesta aplicació no hauria estat possible sense les fantàstiques fonts de dades obertes i eines de desenvolupament proporcionades per:

*   [**Transit.land (API v2)**](https://www.transit.land/documentation/rest-api/): Una plataforma de dades obertes per al transport públic.
*   [**Mallorca Transport Services API**](https://github.com/open-transport-mallorca/mallorca_transit_services): Un paquet de Dart per accedir a les dades del transport públic de Mallorca.
*   [**Firebase i Gemini**](https://firebase.google.com/): El backend, l'allotjament i les eines d'IA generativa han estat proporcionades per Google a través de Firebase i l'assistent de codi Gemini a Firebase Studio.

