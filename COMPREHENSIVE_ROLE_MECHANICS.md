# Comprehensive Role Mechanics Spreadsheet

This document serves as the master specification for night actions and role behaviors. Use the **Notes & Future Improvements** column to track requested changes.

| Priority | Role | Action Type | Player Instruction | Notification (Private) | Teaser (Public) | Host View | Logic / Effect | Notes & Improvements |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **1** | **Sober** | `selectPlayer` | "BLOCK A PLAYER" | "You blocked \[Name\]." | None | "Sober blocked \[Name\]" | **BLOCK**: Target's action is ignored. |  |
| **2** | **Roofi** | `selectPlayer` | "SILENCE A PLAYER" | "You silenced \[Name\]." | None | "Roofi silenced \[Name\]" | **SILENCE**: Target cannot vote/chat tomorrow. |  |
| **3** | **Bouncer** | `selectPlayer` | "IDENTIFY ALIGNMENT" | "\[Name\] is \[TEAM\]." | None | "Bouncer checked \[Name\]" | **INTEL**: Reveals Club Staff vs Party Animal. |  |
| **4** | **Bartender** | `selectTwoPlayers` | "COMPARE TWO PATRONS" | "They are \[SAME/DIFF\]." | None | "Bartender mixed \[A\] & \[B\]" | **INTEL**: Compares alliances of two targets. |  |
| **5** | **Manager** | `selectPlayer` | "CHECK FILES" | "\[Name\] is \[ROLE\]." | None | "Manager file-checked \[Name\]" | **INTEL**: Reveals exact role name. |  |
| **6** | **Messy Bitch** | `selectPlayer` | "SPREAD A RUMOUR" | "You leaked info on \[Name\]." | "Juicy rumours about \[Name\]..." | "MB spread rumour on \[Name\]" | **TEASER**: Adds a public narrative hint. |  |
| **7** | **Lightweight** | `selectPlayer` | "CHOOSE VOTE RESTRICTION" | "You can no longer vote for \[Name\]." | "Lightweight lost a voting option." | "LW lost a voting option" | **RESTRICT**: Target is permanently unvotable by Lightweight. Cumulative. |  |
| **8** | **Dealer** | `selectPlayer` | "ELIMINATE PATRON" | "Target acquired." | None | "Dealer target: \[Name\]" | **KILL**: Standard lethal elimination. |  |
| **9** | **Attack Dog** | `selectPlayer` | "SICK THE DOG" | "Dog released on \[Target\]." | "Dog found prey." | "Dog attacked \[Name\]" | **REVENGE**: Lethal one-time kill. |  |
| **10** | **MB Kill** | `selectPlayer` | "SETTLE A SCORE" | "Score settled with \[Name\]." | "Score settled." | "MB killed \[Name\]" | **KILL**: One-time lethal MB action. |  |
| **11** | **Medic** | `selectPlayer` | "HEAL A PATRON" | "You healed \[Name\]." | None | "Medic protected \[Name\]" | **HEAL**: Prevents death from kills. |  |
| **12** | **Silver Fox** | `selectPlayer` | "GIVE AN ALIBI" | "Alibi provided for \[Name\]." | "\[Name\] has an alibi." | "Fox shielded \[Name\]" | **ALIBI**: Target immune to Day Vote exile. |  |
| **13** | **Whore** | `selectPlayer` | "PICK SCAPEGOAT" | "Scapegoat set: \[Name\]." | None | "Whore set scapegoat: \[Name\]" | **DEFLECT**: Scapegoat dies if Whore is voted out. |  |

## Global Game Mechanics

| Phase | Action | Trigger | Cause & Effect | Notes & Improvements |
| :---- | :---- | :---- | :---- | :---- |
| **Day Vote** | **Exile** | Popular Vote | Majority vote eliminates a player (unless Alibi/Deflected). |  |
| **Alibi** | **Immunity** | Silver Fox | Removes player from the valid target list for Day Vote. |  |
| **Deflect** | **Frame** | Whore (Staff) | If a Staff member is voted out, their scapegoat dies instead. |  |
| **Sobered** | **Blocked** | Sober Action | Prevents the target's code from executing during resolution. |  |
| **Silenced** | **Muted** | Roofi Action | Disables the "SEND" button for the player on the following day. |  |

## Change Log & Notes for Improvements

* *Add your notes here or in the specific table rows above.*  
* ...

