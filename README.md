# ✨ Astra Engine ✨

A modular game engine built with Zig, using SDL2 for cross-platform windowing and rendering, and Lua for scripting game logic.

> [!WARNING]
> **This project is in a very early stage of development.** While the main branch is expected to build and run, the engine is not yet feature-complete and is not ready for serious game development.

---

## 🚀 Key Features

*   **Zig-Powered:** Written in the Zig programming language for performance and safety.
*   **SDL2 Integration:** Utilizes SDL2 for window and renderer management.
*   **Lua Scripting:** Embeds a Lua scripting environment for flexible game logic.
*   **Modular Design:** Features a manager-based architecture for clear separation of concerns (windowing, rendering, assets, scripting).
*   **TOML Configuration:** Uses TOML for easy and readable configuration files.

---

## 🛠️ Technologies Used

*   **Language:** Zig
*   **Graphics/Windowing:** SDL2 (via `SDL.zig`)
*   **Scripting:** Lua (via `zlua`)
*   **Configuration:** TOML (via `zig-toml`)

---

## 📋 Prerequisites

*   **Zig Compiler:** Version `0.14.0` or later (as specified in `build.zig.zon`). You can download it from the [official Zig website](https://ziglang.org/download/).
*   **SDL2:** You need to have the SDL2 library installed on your system.

---

## 📦 Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/0x00ASTRA/astra-engine.git
    cd astra-engine
    ```

2.  **Build the project:**
    The Zig build system will automatically fetch dependencies and compile the project.
    ```bash
    zig build
    ```
    This will create the executable in the `zig-out/bin/` directory.

---

## ⚙️ Build Commands

The `build.zig` file defines the following commands:

*   `zig build`: Compiles the engine and places the executable in `zig-out/bin/`.
*   `zig build run`: Compiles and runs the engine.
*   `zig build test`: Runs the unit tests.
*   `zig build gemini`: Runs the Gemini AI project management workflow.

---

## ▶️ Usage / Getting Started

To run the engine after building:
```bash
zig build run
```

Alternatively, you can execute the compiled binary directly from the build output directory:
```bash
./zig-out/bin/AstraEngine
```

---

## 📂 Project Structure

```
astra-engine/
├── assets/             # Game assets (images, sounds, etc.)
├── build.zig           # Zig build file
├── build.zig.zon       # Zig package definition and dependency management
├── config/             # Configuration files (likely TOML)
├── scripts/            # Lua scripts
│   ├── engine/
│   │   └── init.lua    # Engine-level script, loaded first
│   └── game/
│       └── main.lua    # Main game logic script
├── src/                # Source code directory
│   ├── main.zig        # Main application entry point
│   ├── engine.zig      # Core engine logic
│   ├── window_manager.zig
│   ├── renderer_manager.zig
│   ├── asset_manager.zig
│   └── scripting.zig
└── ...
```

*   `src/`: Contains the main Zig source code for the engine.
*   `assets/`: Holds graphics, sounds, and other resources.
*   `scripts/`: Contains Lua scripts for game logic.
*   `config/`: TOML files for engine and game settings.
*   `build.zig`: Defines how the project is built.
*   `build.zig.zon`: Defines the Zig package and its dependencies.

---

## 🔧 Configuration

Engine and window settings are configured in `config/window.toml`.

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or have an idea for an improvement, please open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

*   [SDL2](https://www.libsdl.org/) - A cross-platform development library.
*   [SDL.zig](https://github.com/ikskuh/SDL.zig) - Zig bindings for SDL2.
*   [Lua](https://www.lua.org/) - A powerful, efficient, lightweight, embeddable scripting language.
*   [zlua](https://github.com/natecraddock/ziglua) - Lua bindings for Zig.
*   [zig-toml](https://github.com/0x00ASTRA/zig-toml) - TOML parser for Zig.
