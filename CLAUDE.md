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

**GameCenterInterface** (`Sources/TourneyKit/GameCenterInterface.swift`) handles Game Center authentication. Call `authenticate() async -> Bool` once at startup (UIKit-only; no macOS native support). Concurrent callers share a single `Task` — authentication only runs once. The underlying `GKLocalPlayer.authenticateHandler` is called multiple times by GameKit (once with a login view controller if needed, once with the result); `withCheckedContinuation` is resumed exactly once on the final outcome.

**MatchManager** (`Sources/TourneyKit/Match Manager/`) is the central `@MainActor` coordinator. It listens to GameKit delegate events (via `MatchManager+Conformances.swift`, using `@preconcurrency GKLocalPlayerListener`) and routes them to the appropriate active match object.

**Match types** are generic over a `Game` protocol:
- `RealTimeGame` — implement to handle real-time data, player connections, and phase changes. Unrecognized incoming messages are forwarded to `didReceive(data:from:)`.
- `TurnBasedGame: Observable, AnyObject` — implement to handle turn state, player drops, and match end.

Both `RealTimeActiveMatch<Game>` and `TurnBasedActiveMatch<Game>` are `@MainActor @Observable`.

**Messaging** (`MatchMessage.swift`) uses a `Codable`-based protocol with a `kind` discriminator field. Built-in types: `.phaseChange`, `.playerInfo`, `.state`, `.update`. Data not recognisable as a framework message is forwarded to `game.didReceive(data:from:)`. `recentlyReceivedData` on `RealTimeActiveMatch` accumulates the last `recentDataDepth` (default 20) state/update messages.

**Player identification** uses `GKPlayer.PlayerTag` (`Extensions/GKPlayer.swift`), which holds `teamID`, `gameID`, and `alias`. `PlayerCache` (name/ID) and `PlayerImageCache` (avatar, via JohnnyCache) manage per-session player metadata.

**UI components** include SwiftUI wrappers for GameKit's matchmaker view controllers (`RealTimeMatchmakerView`, `TurnBasedMatchmakerView`, UIKit-only) and player display views (`PlayerAvatar`, `PlayerLabel`, `PlayerInfoView`). Both matchmaker coordinators are `@MainActor` with `@preconcurrency` ObjC delegate conformances.

**Logging** uses OSLog via `TKLogger` (`@MainActor @Observable` singleton, subsystem `"TourneyKit"`, category `"matches"`). `LoggerView` is a SwiftUI debug view surfacing recent events.

## Key Design Patterns

- Everything on the match update path is `@MainActor`; ObjC delegate protocols use `@preconcurrency` conformance to bridge GameKit's threading model
- Both match types are generic (`RealTimeActiveMatch<Game>`, `TurnBasedActiveMatch<Game>`) for type-safe game state
- Games implement protocols rather than subclassing
- `SomeMatch` and `SomeTurnBasedActiveMatch` are `@MainActor` protocols enabling polymorphic handling in `MatchManager`
- The entire API is `async/await`; Combine is not used

## Dependencies

- **CrossPlatformKit** (`https://github.com/ios-tooling/CrossPlatformKit.git`, ≥1.1.0) — platform-agnostic type aliases (`UXImage`, etc.)
- **JohnnyCache** (local path `../JohnnyCache`) — three-tier cache (memory/disk/CloudKit) used for player avatar images

## Platforms

iOS 17+, macOS 15+, watchOS 10+, Swift 6.1+
