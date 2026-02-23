# TourneyKit

A Swift package that simplifies Apple GameKit integration for real-time and turn-based multiplayer games.

TourneyKit wraps GameKit's verbose delegate-based APIs behind a modern Swift interface using `async/await`, `@Observable`, and `@MainActor` isolation, so you can focus on your game logic instead of boilerplate.

## Requirements

- iOS 17+ / macOS 15+ / watchOS 10+
- Swift 6.1+
- Xcode 16+

## Installation

Add TourneyKit to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ios-tooling/TourneyKit.git", from: "1.0.0"),
]
```

## Quick Start

### 1. Authenticate with Game Center

```swift
let authenticated = await GameCenterInterface.instance.authenticate()
```

### 2. Implement a Game Protocol

For **real-time** games, conform to `RealTimeContainer`:

```swift
@MainActor
class MyRealTimeGame: RealTimeContainer, ObservableObject {
    struct MatchState: Codable { /* your game state */ }
    struct MatchUpdate: Codable { /* incremental updates */ }

    func loaded(match: RealTimeActiveMatch<Self>, with players: [GKPlayer]) { }
    func playersChanged(to players: [GKPlayer]) { }
    func matchStateChanged(to state: MatchState) { }
    func matchUpdated(with update: MatchUpdate) { }
    func matchPhaseChanged(to phase: ActiveMatchPhase) { }
    func didReceive(data: Data, from player: GKPlayer) { }
}
```

For **turn-based** games, conform to `TurnBasedContainer`:

```swift
@MainActor @Observable
class MyTurnBasedGame: TurnBasedContainer {
    struct MatchState: Codable { /* your game state */ }

    var matchState = MatchState()

    static var defaultRequest: GKMatchRequest { /* configure request */ }

    func loaded(match: TurnBasedActiveMatch<Self>) { }
    func received(matchState: MatchState?) { }
    func matchEndedOnGameCenter() { }
    func playerDropped(_ player: GKPlayer) { }
    func clearOut() { }
}
```

### 3. Present a Matchmaker

Use the built-in SwiftUI matchmaker views (iOS only):

```swift
// Real-time
RealTimeMatchmakerView(request: matchRequest, match: $gkMatch)

// Turn-based
TurnBasedMatchmakerView(request: matchRequest, game: myGame)
```

Or start automatching directly:

```swift
try await RemoteMatchManager.instance.startAutomatching(request: request, game: myGame)
```

### 4. Play the Match

**Real-time** — send state and updates to all players:

```swift
try match.sendState(currentState)
try match.sendUpdate(incrementalUpdate)
```

**Turn-based** — advance turns with encoded game state:

```swift
try await match.endTurn()
try await match.endGame(withOutcome: .won)
```

## Architecture

```
GameCenterInterface          — Game Center authentication
    └── RemoteMatchManager         — central @MainActor coordinator (singleton)
            ├── RealTimeActiveMatch<Game>    — wraps GKMatch
            └── TurnBasedActiveMatch<Game>   — wraps GKTurnBasedMatch
```

**RemoteMatchManager** is the hub. It listens to all GameKit delegate events and routes them to the appropriate active match object. Your game interacts with match objects; the manager handles the plumbing.

Both match types are generic over your game protocol, giving you type-safe access to your `MatchState` and `MatchUpdate` types throughout.

## Key Types

| Type | Role |
|------|------|
| `GameCenterInterface` | Singleton handling Game Center auth |
| `RemoteMatchManager` | Singleton coordinating all match activity |
| `RealTimeContainer` | Protocol your real-time game implements |
| `TurnBasedContainer` | Protocol your turn-based game implements |
| `RealTimeActiveMatch<Game>` | Manages a live real-time match |
| `TurnBasedActiveMatch<Game>` | Manages a live turn-based match |
| `RealTimeMatchmakerView` | SwiftUI wrapper for `GKMatchmakerViewController` |
| `TurnBasedMatchmakerView` | SwiftUI wrapper for `GKTurnBasedMatchmakerViewController` |
| `PlayerAvatar` / `PlayerLabel` | SwiftUI views for displaying player info |
| `PlayerDictionary<T>` | Dictionary keyed by `GKPlayer.PlayerTag` |
| `TKLogger` / `LoggerView` | Observable logger with a SwiftUI debug view |

## Messaging

TourneyKit uses a `Codable` message protocol with a `kind` discriminator for real-time matches. Built-in message types:

- **Phase change** — match lifecycle transitions (loading, playing, ended)
- **Player info** — player name and ID exchange
- **State** — full game state snapshots (your `MatchState`)
- **Update** — incremental game updates (your `MatchUpdate`)

Unrecognized data is forwarded to your game's `didReceive(data:from:)` method, so you can mix in custom messaging if needed.

## Player Identification

`GKPlayer.PlayerTag` provides a stable, `Codable` player identifier combining `teamID`, `gameID`, and `alias`. Player names and avatars are cached per-session via `PlayerCache` and `PlayerImageCache`.

## Dependencies

- [CrossPlatformKit](https://github.com/ios-tooling/CrossPlatformKit) — platform-agnostic type aliases
- [JohnnyCache](https://github.com/ios-tooling/JohnnyCache) — three-tier image cache for player avatars

## License

MIT
