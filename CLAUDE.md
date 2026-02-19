# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**TourneyKit** is a Swift package that provides a high-level abstraction over Apple's GameKit framework, simplifying integration of real-time and turn-based multiplayer matches in iOS/macOS/watchOS apps.

## Build Commands

```bash
# Build the framework
swift build

# Build in release mode
swift build -c release

# Run tests (no formal test targets; use the example app)
open TourneyKitTestHarness.xcodeproj
```

No linting or formatting tools are configured.

## Architecture

TourneyKit wraps GameKit using a facade pattern with two match tracks:

**Core flow:**
```
GameCenterInterface (authentication)
    └── MatchManager (@MainActor singleton)
            ├── RealTimeActiveMatch<Game>   (wraps GKMatch)
            └── TurnBasedActiveMatch<Game>  (wraps GKTurnBasedMatch)
```

**MatchManager** (`Sources/TourneyKit/Match Manager/`) is the central coordinator. It listens to GameKit delegate events (via `MatchManager+Conformances.swift`) and routes them to the appropriate active match object.

**Match types** are generic over a `Game` protocol:
- `RealTimeGame` — implement to handle real-time data, player connections, and phase changes
- `TurnBasedGame: ObservableObject` — implement to handle turn state, player drops, and match end

**Messaging** (`MatchMessage.swift`) uses a `Codable`-based protocol. Built-in message types include phase changes, player info, initial state, and state updates. Games can define custom message types conforming to `MatchMessage`.

**Player identification** uses `PlayerTag` (defined in `Extensions/GKPlayer.swift`), which uniquely identifies players across sessions. `PlayerCache` and `PlayerImageCache` manage display names and avatars.

**UI components** include SwiftUI wrappers for GameKit's matchmaker view controllers (`RealTimeMatchmakerView`, `TurnBasedMatchmakerView`) and player display views (`PlayerAvatar`, `PlayerLabel`, `PlayerInfoView`).

**Logging** uses OSLog via `TKLogger` (subsystem: `"TourneyKit"`, category: `"matches"`). `LoggerView` is a SwiftUI debug view for surfacing recent events.

## Key Design Patterns

- `@MainActor` is used on `MatchManager` and match update paths for thread safety
- Both match types are generic (`RealTimeActiveMatch<Game>`, `TurnBasedActiveMatch<Game>`) for type-safe game state
- Games implement protocols rather than subclassing
- `SomeMatch` protocol enables polymorphic handling of either match type in `MatchManager`

## Dependencies

- **CrossPlatformKit** (`https://github.com/ios-tooling/CrossPlatformKit.git`, v1.1.0) — platform-agnostic utilities enabling the iOS/macOS/watchOS target support

## Platforms

iOS 15+, macOS 12+, watchOS 7+, Swift 5.8+
