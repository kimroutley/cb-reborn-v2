<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

The `cb_logic` package contains the core business logic, game rules, and state management for the Club Blackout game.

## Features

### Core Game Logic
- **Role Assignment**: Automatically assigns roles to players, ensuring game balance with Dealers (Staff) and required roles. Supports special initialization for roles like "Seasoned Drinker".
- **Night Phase Resolution**: Processes night actions including pre-emptive blocks (Sober, Roofi), investigations (Bouncer), murders (Dealer), and protections (Medic). Handles complex interactions like "Second Wind" and "Seasoned Drinker" survival mechanics.
- **Day Phase Resolution**: Manages voting results, including ties and abstentions.
- **Win Conditions**: Determines victory conditions for "Club Staff" (Dealers) or "Party Animals" (Townsfolk).

### Scripting & Narration
- **Dynamic Script Generation**: Generates step-by-step scripts for the game host, covering Setup, Night, and Day phases using `ScriptBuilder`.
- **Role-Specific Instructions**: Includes specific steps for roles like Medic, Creep, Clinger, Wallflower, Attack Dog, and Messy Bitch.
- **AI-Powered Narration**: Integrates with Google Gemini via `GeminiNarrationService` to generate thematic, immersive narration based on game events and selected voice styles (e.g., "nightclub_noir", "host_hype").

### State Management
- **Game Provider**: Manages the current game state using Riverpod (`game_provider.dart`).
- **Games Night Provider**: Manages a session of multiple games (`games_night_provider.dart`).
- **Chat Provider**: Handles in-game chat functionality (`chat_provider.dart`).

### Utilities
- **Player Matching**: Algorithms for matching players (`PlayerMatcher`).
- **Recap Generation**: Creates summaries of game events (`RecapGenerator`).
- **Strategy Hints**: Generates strategic tips for players (`StrategyGenerator`).
- **Analytics**: Tracks game events using Firebase Analytics (`AnalyticsService`).

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
