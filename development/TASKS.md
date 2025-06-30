# Astra Engine Task Board

## `Backlog`

### Core Engine
*   [ ] **Logging & Error Handling:** Design and implement a comprehensive, multi-level logging system (e.g., info, warn, error, fatal).
*   [ ] **Configuration:** Add support for loading and parsing TOML configuration files for engine and game settings.
*   [ ] **Testing:** Create a comprehensive test suite for all engine modules.
*   [ ] **Event System:** Implement a dedicated event queue thread for handling all engine and game events asynchronously.

### Rendering (2D)
*   [ ] **Shapes & Primitives:** Add support for rendering basic geometric shapes (rectangles, lines, etc.).
*   [ ] **Sprite Batching:** Implement a sprite batching system to improve rendering performance.
*   [ ] **Camera System:** Implement a camera system for 2D scrolling, zooming, and rotation.
*   [ ] **Lighting:** Design and implement a 2D lighting system (e.g., normal-mapped 2D lighting).
*   [ ] **Shaders:** Integrate a shader system for custom rendering effects and post-processing.
*   [ ] **Text Rendering:** Implement a system for managing fonts and rendering text.

### Scripting
*   [ ] **Modularization:** Refactor the scripting system into its own module with a clear entry point, bindings, and tests.
*   [ ] **API Expansion:** Expose more engine functionality to the Lua API (input, audio, physics, etc.).
*   [ ] **Hot-Reloading:** Add support for hot-reloading Lua scripts to accelerate development.

### Input
*   [ ] **Input Handling:** Create a flexible input handling system that maps physical inputs to game actions.
*   [ ] **Device Support:** Add support for various input devices (keyboard, mouse, game controllers).

### Physics & Collision (2D)
*   [ ] **Collision System:** Implement a 2D collision detection and resolution system (e.g., AABB, SAT).
*   [ ] **Physics Engine:** Integrate or build a simple 2D physics engine for movement and forces.

### Asset Management
*   [ ] **Performance:** Refactor the asset manager for high performance and optimized memory usage.
*   [ ] **Audio:** Add support for loading and playing audio files (e.g., WAV, OGG).

### 3D (Future)
*   [ ] **Renderer Extension:** Extend the renderer to support 3D models, materials, and transformations.
*   [ ] **3D Camera:** Implement a 3D camera system with various projection and control modes.
*   [ ] **3D Lighting:** Add support for basic 3D lighting models (e.g., Phong, Blinn-Phong).

---

## `In Progress`

*   **[WIP]** Refine the SDL2 rendering manager to support more advanced features.
*   **[WIP]** Redesign the Lua API for better ergonomics and type safety.
*   **[WIP]** Implement a basic event system for engine-to-script communication.

---

## `Done`

*   [x] Initial SDL2 integration for windowing and input.
*   [x] Basic rendering manager implementation.
*   [x] Lua scripting moved to a separate thread.
*   [x] Basic asset manager for textures.
