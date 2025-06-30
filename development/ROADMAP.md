# Astra Engine Development Roadmap

## **Objective:** Complete the transition from Raylib to SDL2 and overhaul the scripting system for a more robust and flexible engine.

---

## `Phase 1: Core Systems Rewrite (In Progress)`

*   **Milestone 1.1: SDL2 Integration**
    *   [x] Replace Raylib with SDL2 for windowing and input handling.
    *   [x] Implement a stable and efficient rendering manager using SDL2.

*   **Milestone 1.2: Scripting System Overhaul**
    *   [x] Move Lua logic to a separate thread for non-blocking execution.
    *   [ ] Redesign the Lua API for better integration with the new engine architecture.
    *   [ ] Implement a robust event system for communication between the engine and Lua scripts.

---

## `Phase 2: 2D Feature Expansion`

*   **Milestone 2.1: Asset Management**
    *   [x] Develop a flexible asset management system for textures.
    *   [ ] Implement hot-reloading for assets to improve development workflow.
    *   [ ] Add support for loading sounds and fonts.

*   **Milestone 2.2: Enhanced 2D Rendering**
    *   [ ] Implement support for shaders and post-processing effects.
    *   [ ] Add a basic 2D lighting system.

*   **Milestone 2.3: 2D Physics and Collision**
    *   [ ] Integrate a 2D physics engine (e.g., Box2D or a custom implementation).
    *   [ ] Provide a simple and intuitive API for physics interactions in Lua.

---

## `Phase 3: Tooling and Documentation`

*   **Milestone 3.1: Developer Tools**
    *   [ ] Create a simple in-game console for debugging and executing commands.
    *   [ ] Develop a basic scene editor for placing objects and entities.

*   **Milestone 3.2: Documentation and Examples**
    *   [ ] Write comprehensive documentation for the new engine API.
    *   [ ] Create example projects to demonstrate engine features and best practices.

---

## `Phase 4: 3D Rendering (Future)`

*   **Milestone 4.1: Foundational 3D**
    *   [ ] Extend the renderer to support 3D models and transformations.
    *   [ ] Implement a 3D camera system.
    *   [ ] Add support for basic 3D lighting and materials.

---

## `Phase 5: Multiplayer (Future)`

*   **Milestone 5.1: Networking**
    *   [ ] Integrate a networking library for client-server communication.
    *   [ ] Design and implement a basic server architecture.
    *   [ ] Expose networking functionality to the Lua API.

---

## `Future Considerations`
*   [ ] Ensure cross-platform compatibility (Windows, macOS, Linux).
