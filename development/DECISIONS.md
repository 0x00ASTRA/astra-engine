# Astra Engine Decision Log

## `2025-06-30`

*   **Decision:** Adopt a modular architecture with clear separation of concerns between different engine systems (e.g., rendering, scripting, assets).
    *   **Rationale:** This will make the engine easier to maintain, extend, and test. It also allows for parallel development of different features.
    *   **Status:** Implemented in the current source code structure.

*   **Decision:** Use SDL2 as the primary backend for windowing, input, and rendering.
    *   **Rationale:** SDL2 is a mature and cross-platform library that provides low-level access to hardware, which is ideal for a custom game engine. It also has excellent community support and documentation.
    *   **Status:** Implemented.

*   **Decision:** Run Lua scripting in a separate thread.
    *   **Rationale:** This prevents the game logic from blocking the main rendering loop, resulting in a smoother and more responsive experience. It also allows for long-running operations in scripts without freezing the engine.
    *   **Status:** Implemented.
