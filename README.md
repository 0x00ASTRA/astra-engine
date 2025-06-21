# Astra Engine - Undergoing Major Rewrite

-----

## **Important: Codebase Undergoing Major Rewrite**

Please be aware that the Astra Engine is currently undergoing a **complete and fundamental rewrite**. This means that **everything is likely broken and non-functional at the moment.**

I'm moving away from **Raylib** and transitioning to **SDL** for graphics and input handling. Additionally, the entire **Lua scripting system is being overhauled** for improved functionality and integration.

**Please check back later** when I have more of the rewrite finished and the engine is in a more stable and usable state.

-----

### **Previous Overview (No Longer Current)**

*This section describes the previous state of the engine and is provided for historical context only. It does not reflect the current development status.*

This project was previously an experiment and demonstration of using Zig for game development, written using Raylib for rendering and input handling, and integrating Lua for game logic and scripting. TOML was also built in for configurations.

### **Previous Key Features (No Longer Current)**

  * Developed using the Zig programming language.
  * Utilized the Raylib library for 2D graphics rendering.
  * Integrated Lua scripting capabilities (via `zlua`).
  * Configuration handled via TOML files (via `zig-toml`).

### **Previous Technologies Used (No Longer Current)**

  * **Language:** Zig
  * **Graphics:** Raylib (via `raylib-zig`)
  * **Scripting:** Lua (via `zlua`)
  * **Configuration:** TOML (via `zig-toml`)

### **Prerequisites, Installation, Usage, and Project Structure**

The information below regarding prerequisites, installation, usage, and project structure is **outdated** and pertains to the previous version of the engine. These instructions will be updated once the rewrite is complete and the project is in a working state.

-----

## Prerequisites

  * **Zig Compiler:** Version `0.14.0` or later (as specified in `build.zig.zon`). You can download it from the [official Zig website](https://ziglang.org/download/).
  * **Build Tools:** Standard system build tools (like GCC or Clang) required for compiling the Raylib C dependency.

-----

## Installation

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

    This will create the executable in the `zig-out/bin/` directory and the required shared libraries in `zig-out/lib/`.

-----

## Usage / Getting Started

To run the game after building:

```bash
zig build run
```

Alternatively, you can execute the compiled binary directly from the build output directory:

```bash
./zig-out/bin/AstraEngine
```

Ensure the necessary assets and potentially configuration files are in the correct location relative to the executable or run it from the project root using `zig build run`.

-----

## Project Structure

```
astra-engine/
├── .gitignore          # Specifies intentionally untracked files
├── assets/             # Game assets (images, sounds, etc.)
├── build.zig           # Zig build file
├── build.zig.zon       # Zig package definition and dependency management
├── config/             # Configuration files (likely TOML)
├── scripts/            # Lua scripts
├── src/                # Source code directory
│   ├── main.zig        # Main application entry point
│   └── ...             # Other Zig source files
└── test/               # Unit tests
    └── test.zig        # Test source file
```

  * `src/`: Contains the main Zig source code for the game logic, Raylib integration, etc.
  * `assets/`: Holds graphics, sounds, and other resources used by the game.
  * `scripts/`: Contains Lua scripts used for game logic or events.
  * `config/`: TOML files for game and engine settings.
  * `build.zig`: Defines how the project is built, including fetching and linking dependencies like Raylib and Lua.
  * `build.zig.zon`: Defines the Zig package and its dependencies managed by the Zig package manager.

-----

## Configuration

Game configuration is likely handled through files within the `config/` directory, utilizing the TOML format. Please refer to the files in the `config/` directory for specific settings and their structure.

-----

## Contributing

Contributions are welcome\! If you find a bug or have an idea for an improvement, please open an issue or submit a pull request.

-----

## License

[󰿃 LICENSE](https://www.google.com/search?q=LICENSE)

-----

## Acknowledgements

  * [Raylib](https://www.raylib.com/) - A simple and easy-to-use library to enjoy videogames programming.
  * [raylib-zig](https://github.com/raysan5/raylib-zig) - Zig bindings for Raylib.
  * [Lua](https://www.lua.org/) - A powerful, efficient, lightweight, embeddable scripting language.
  * [zlua](https://github.com/sumneko/zlua) - Lua bindings for Zig.
  * [zig-toml](https://github.com/0x00ASTRA/zig-toml) - TOML parser for Zig.

-----
