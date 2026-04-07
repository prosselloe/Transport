# Transport de les Balears

## Visió General

Aquest document descriu l'arquitectura, les característiques i el disseny de Transport de les Balears, una aplicació Flutter per consultar informació sobre el transport públic a les Illes Balears, amb un enfocament especial en els serveis oferts pel Consorci de Transports de Mallorca.

## Característiques i Disseny Implementats

*   **Pantalla d'Agències**: Mostra una graella d'agències de transport, distingint entre el Consorci de Transports de Mallorca i altres de l'API Onestop.
*   **Pantalla de Detalls d'Agència/Parada**:
    *   Mostra detalls d'una agència seleccionada o d'una parada específica.
    *   Mostra un mapa amb totes les parades d'una agència o només la parada seleccionada.
    *   El mapa inclou la ubicació actual de l'usuari.
    *   Llista totes les rutes associades a l'agència o parada.
*   **Pantalla de Detalls de Ruta**:
    *   Mostra el recorregut d'una ruta seleccionada en un mapa, incloent-hi totes les seves parades.
    *   Mostra una llista de totes les parades de la ruta.
    *   El color de l'AppBar s'adapta dinàmicament al color de la ruta per a una millor experiència d'usuari.
*   **Elements Interactius de Parada (Llista i Mapa)**:
    *   Tant els marcadors de parada als mapes com els elements a les llistes de parades són interactius.
    *   Si una parada proporciona una URL externa (de Transit.land), en tocar-la s'obrirà la URL en un navegador.
    *   Si no hi ha URL però la parada pertany al "Consorci de Transports de Mallorca" (amb el prefix `mallorca::`), en tocar-la es navegarà a la pantalla de detalls de la parada.
    *   Per a altres casos, l'acció de tocar està desactivada per evitar la navegació a pantalles buides o irrellevants.
*   **Tema**:
    *   L'aplicació utilitza un tema personalitzat amb un color primari de `#0175C2`.
    *   S'utilitza un `ThemeProvider` per permetre als usuaris canviar entre els modes de tema clar, fosc i de sistema.
*   **Pantalla de Benvinguda**: S'ha implementat una pantalla de benvinguda nativa per a un llançament professional de l'aplicació.
