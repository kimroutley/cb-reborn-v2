import '../enums.dart';
import '../role.dart';
import '../role_ids.dart';

/// Complete role catalog for Club Blackout.
///
/// Alliance mapping:
///   clubStaff  = The Dealers (killers / mafia)
///   partyAnimals = The Party Animals (town / innocents)
///   neutral    = Wildcards / Variables
///
/// nightPriority: lower = acts earlier. 0 = passive (no night wake).
const List<Role> roleCatalog = [
  // ═══════════════════════════════════════════════
  //  THE DEALERS (Killers)
  // ═══════════════════════════════════════════════
  Role(
    id: RoleIds.dealer,
    name: 'The Dealer',
    alliance: Team.clubStaff,
    type: 'Killer',
    complexity: 2,
    tacticalTip:
        'Coordinate your targets. Don\'t always eliminate the loudest players; sometimes the quiet ones are easier to frame during the day.',
    description: 'Choose a victim to murder each night with the other Dealers.',
    nightPriority: 10,
    ability: 'Night Kill',
    assetPath: 'assets/roles/dealer.png',
    colorHex: '#FF00FF', // Fuschia - from CB Visuals
    canRepeat: true,
    lore:
        "The house always wins. You are the invisible hand steering the night, removing obstacles with surgical precision. The lounge is your hunting ground, and silence is your weapon.",
    detailedAbility:
        "Each night, the Dealer team wakes up together. You must unanimously agree on a single victim to eliminate. If even one Dealer disagrees or is blocked (e.g. by the Roofi), the kill may fail or be disrupted.",
    synergies: [RoleIds.whore, RoleIds.silverFox, RoleIds.roofi],
    counters: [RoleIds.bouncer, RoleIds.wallflower, RoleIds.minor],
  ),

  Role(
    id: RoleIds.whore,
    name: 'The Whore',
    alliance: Team.clubStaff,
    type: 'Defensive',
    complexity: 4,
    tacticalTip:
        'Your scapegoat is your shield. Keep them alive but ensure they are the primary suspect if you start feeling the heat.',
    description:
        'Choose a scapegoat. The next time a Dealer would be voted out, the elimination is deflected to your scapegoat instead. One use.',
    nightPriority: 55,
    ability: 'Vote Deflection',
    assetPath: 'assets/roles/whore.png',
    colorHex: '#008080', // Teal - from CB Visuals
    lore:
        "Everyone has a price, and you know exactly who can afford to pay. You survive by making yourself indispensable—or by ensuring someone else takes the fall when the heat gets too high.",
    detailedAbility:
        "Choose a Scapegoat at night. This is a one-time deflection shield. If the Dealers are about to be voted out during the day, the elimination is redirected to your Scapegoat instead. The Scapegoat dies, and the day ends.",
    synergies: [RoleIds.dealer, RoleIds.silverFox],
    counters: [RoleIds.bouncer, RoleIds.medic],
  ),

  Role(
    id: RoleIds.silverFox,
    name: 'The Silver Fox',
    alliance: Team.clubStaff,
    type: 'Disruptive',
    complexity: 3,
    tacticalTip:
        'Use your alibi to build trust. Saving a "confirmed" Party Animal can make you look like a hero and blend you in with the crowd.',
    description:
        'Each night, choose one player. During the following day, they cannot be voted out.',
    nightPriority: 50,
    ability: 'Nightly Alibi',
    assetPath: 'assets/roles/silver_fox.png',
    colorHex: '#808000', // Olive - from CB Visuals
    lore:
        "Charming, sophisticated, and utterly untrustworthy. You weave narratives that protect the guilty and confuse the innocent. A well-placed alibi is worth more than a loaded gun.",
    detailedAbility:
        "Each night, select a player to grant an Alibi. That player cannot be eliminated by the day vote the following day. You can protect a fellow Dealer to save them from justice, or 'protect' an innocent to gain their trust.",
    synergies: [RoleIds.dealer, RoleIds.whore],
    counters: [RoleIds.teaSpiller, RoleIds.predator],
  ),

  // ═══════════════════════════════════════════════
  //  THE PARTY ANIMALS (Innocents)
  // ═══════════════════════════════════════════════
  Role(
    id: RoleIds.partyAnimal,
    name: 'The Party Animal',
    alliance: Team.partyAnimals,
    type: 'Passive',
    complexity: 1,
    tacticalTip:
        'Your strength is in your vote and your social awareness. Pay attention to inconsistencies in claims and don\'t be afraid to lead discussions.',
    description:
        'No special ability. Your strength is in your vote and your survival.',
    nightPriority: 0,
    ability: 'None',
    assetPath: 'assets/roles/party_animal.png',
    colorHex: '#FFDAB9', // Peach - from CB Visuals
    canRepeat: true,
    lore:
        "You came for the music, the drinks, and the escape. Now you're trapped in a game of life and death. Your only power is your voice and your vote—use them wisely.",
    detailedAbility:
        "You have no special night action. You wake up only when the day begins. Your survival depends on observing patterns, calling out inconsistencies, and building trust with other Party Animals.",
    synergies: [RoleIds.bouncer, RoleIds.medic],
    counters: [RoleIds.dealer, RoleIds.messyBitch],
  ),

  Role(
    id: RoleIds.medic,
    name: 'The Medic',
    alliance: Team.partyAnimals,
    type: 'Defensive',
    complexity: 3,
    tacticalTip:
        'Self-protect on Night 1 if the game feels aggressive. Saving a powerful role like the Bouncer or Wallflower can completely flip the game.',
    description:
        'Choose to protect a player each night, or sacrifice that power for a one-time revive.',
    nightPriority: 30,
    hasBinaryChoiceAtStart: true,
    choices: ['PROTECT_DAILY', 'REVIVE'],
    ability: 'Protect or Revive',
    assetPath: 'assets/roles/medic.png',
    colorHex: '#FF0000', // Red - from CB Visuals
    lore:
        "In a club full of poison, you are the antidote. You've seen too many good nights go bad, and you're determined to make sure everyone sees the sunrise.",
    detailedAbility:
        "Choose between 'Protect Daily' or 'Revive'. If you choose Protect, you select one player each night to save from murder. If you choose Revive, you have a one-time ability to bring a dead player back to life.",
    synergies: [RoleIds.bouncer, RoleIds.wallflower],
    counters: [RoleIds.dealer, RoleIds.roofi],
  ),

  Role(
    id: RoleIds.bouncer,
    name: 'The Bouncer',
    alliance: Team.partyAnimals,
    type: 'Investigative',
    complexity: 3,
    tacticalTip:
        'Target the most influential talkers. Finding a Dealer early is great, but confirming a powerful ally is just as important for the town.',
    description:
        'Each night, check a player\'s ID. The Host reveals if they are Dealer-side or not.',
    nightPriority: 20,
    ability: 'Check ID',
    assetPath: 'assets/roles/bouncer.png',
    colorHex: '#0000FF', // Blue - from CB Visuals
    lore:
        "You check IDs at the door, and you check souls in the lounge. You have an instinct for trouble, and you can smell a Dealer from a mile away.",
    detailedAbility:
        "Each night, inspect one player's ID card. The Host will signal whether they are 'Club Staff' (Dealer team) or 'Party Animal' (Innocent). Note: Some roles like the Silver Fox might appear innocent depending on game settings.",
    synergies: [RoleIds.medic, RoleIds.allyCat],
    counters: [RoleIds.dealer, RoleIds.whore],
  ),

  Role(
    id: RoleIds.roofi,
    name: 'The Roofi',
    alliance: Team.partyAnimals,
    type: 'Offensive',
    complexity: 4,
    tacticalTip:
        'Silence Dealers to block their kills, or silence loud "suspects" to prevent them from leading the vote against you the next day.',
    description:
        'Paralyze a player each night. They are silenced the next day. Roofing the only Dealer blocks their kill.',
    nightPriority:
        8, // Changed from 15 to 8 to ensure it blocks Dealers (Priority 10)
    ability: 'Paralyze',
    assetPath: 'assets/roles/roofi.png',
    colorHex: '#008000', // Green - from CB Visuals
    lore:
        "You fight fire with fire. If the Dealers want to play dirty, you'll put them to sleep before they can hurt anyone. Sometimes the best defense is a knockout punch.",
    detailedAbility:
        "Select a player at night to sedate. They will be silenced for the entire next day, unable to speak or vote. If you target the only active Dealer, their kill is blocked for the night.",
    synergies: [RoleIds.bouncer, RoleIds.medic],
    counters: [RoleIds.dealer, RoleIds.messyBitch],
  ),

  Role(
    id: RoleIds.sober,
    name: 'The Sober',
    alliance: Team.partyAnimals,
    type: 'Protective',
    complexity: 3,
    tacticalTip:
        'Send suspected power roles home to keep them safe from murder, or target suspicious players to block their potential night action.',
    description:
        'Send a player home at the start of night. They are safe from murder and cannot act tonight.',
    nightPriority: 5,
    ability: 'Send Home',
    assetPath: 'assets/roles/sober.png',
    colorHex: '#39FF14', // Fluro Green - from CB Visuals
    lore:
        "While everyone else is losing their minds, you're the designated driver of destiny. You pull people out of the chaos before they get themselves killed.",
    detailedAbility:
        "Choose a player to send home at the start of the night. They are safe from all night actions (including murder) but cannot perform their own night action. Use this to protect key roles or neutralize threats.",
    synergies: [RoleIds.bouncer, RoleIds.medic],
    counters: [RoleIds.dealer, RoleIds.roofi],
  ),

  Role(
    id: RoleIds.wallflower,
    name: 'The Wallflower',
    alliance: Team.partyAnimals,
    type: 'Investigative',
    complexity: 4,
    tacticalTip:
        'Observe without acting. Only reveal your identity when you have definitive proof of a Dealer\'s action to ensure the town follows your lead.',
    description:
        'Can discreetly open eyes during the murder phase to witness the kill.',
    nightPriority: 0,
    ability: 'Witness Murder',
    assetPath: 'assets/roles/wallflower.png',
    colorHex: '#FFC0CB', // Pink - from CB Visuals
    isRequired: true,
    lore:
        "You blend into the background, unnoticed and underestimated. But while others are busy talking, you are watching. You see things no one else sees—even murder.",
    detailedAbility:
        "You can open your eyes during the Dealer's murder phase. If you do, you witness the kill. However, if the Dealers spot you, they might change their target to you. It's a high-risk, high-reward surveillance move.",
    synergies: [RoleIds.bouncer, RoleIds.medic],
    counters: [RoleIds.dealer, RoleIds.roofi],
  ),

  Role(
    id: RoleIds.allyCat,
    name: 'The Ally Cat',
    alliance: Team.partyAnimals,
    type: 'Investigative',
    complexity: 4,
    tacticalTip:
        'Your lives are a resource. Don\'t be afraid to be vocal and draw fire, but remember you can only communicate using "Meow".',
    description:
        'Can open eyes when the Bouncer checks IDs. Must communicate using "Meow". You have 9 lives.',
    nightPriority: 0,
    ability: 'Vantage Point + Nine Lives',
    assetPath: 'assets/roles/ally_cat.png',
    colorHex: '#FFFACD', // Lemon - from CB Visuals
    lore:
        "Curiosity hasn't killed you yet, but it's close. You have nine lives and a special connection to the Bouncer. You act as their eyes when they can't see, but your voice is... limited.",
    detailedAbility:
        "You wake up whenever the Bouncer wakes up. You see who they check, but not the result. You have 9 lives (immune to 8 kills). You can only communicate by saying 'Meow' during the day.",
    synergies: [RoleIds.bouncer, RoleIds.seasonedDrinker],
    counters: [RoleIds.dealer, RoleIds.roofi],
  ),

  Role(
    id: RoleIds.minor,
    name: 'The Minor',
    alliance: Team.partyAnimals,
    type: 'Defensive',
    complexity: 2,
    tacticalTip:
        'You are safe from the first attack. Use this temporary invincibility to be bold in discussions and gather as much intel as possible.',
    description:
        'Dealer murder attempts fail until the Bouncer has checked your identity. Can still be voted out.',
    nightPriority: 0,
    ability: 'Death Protection',
    assetPath: 'assets/roles/minor.png',
    colorHex: '#FFFFFF', // White - from CB Visuals
    lore:
        "You shouldn't even be here. You're young, innocent, and somehow invisible to the darkness. The Dealers can't touch you... at least, not yet.",
    detailedAbility:
        "You are immune to Dealer kills until the Bouncer checks your ID. Once checked, your 'innocence' is lost, and you become vulnerable. You can still be eliminated by the day vote at any time.",
    synergies: [RoleIds.bouncer, RoleIds.medic],
    counters: [RoleIds.bouncer, RoleIds.dealer],
  ),

  Role(
    id: RoleIds.seasonedDrinker,
    name: 'The Seasoned Drinker',
    alliance: Team.partyAnimals,
    type: 'Tank',
    complexity: 2,
    tacticalTip:
        'You are the team\'s tank. Take the heat for others and use your extra lives to survive long enough to find the Dealers.',
    description:
        'Extra lives equal to the number of Dealers. Only Dealer kills burn a life.',
    nightPriority: 0,
    ability: 'Dealer Immunity Tank',
    assetPath: 'assets/roles/seasoned_drinker.png',
    colorHex: '#3EB489', // Mint - from CB Visuals
    lore:
        "You've been here since the doors opened, and you'll be here when they close. You've built up a tolerance to everything—including poison. It takes more than one shot to take you down.",
    detailedAbility:
        "You have extra lives equal to the number of starting Dealers. If the Dealers try to kill you, you lose a life but survive. You only die when all lives are gone or if voted out.",
    synergies: [RoleIds.medic, RoleIds.allyCat],
    counters: [RoleIds.dealer, RoleIds.messyBitch],
  ),

  Role(
    id: RoleIds.lightweight,
    name: 'The Lightweight',
    alliance: Team.partyAnimals,
    type: 'Passive',
    complexity: 5,
    tacticalTip:
        'Be careful who you target! Each night you choose someone, you lose the ability to vote for them forever. This accumulates nightly, so save your targets for players you trust completely.',
    description:
        'Each night, choose an operative. That operative becomes "taboo" for you, and you can no longer cast a vote against them in any future day vote.',
    nightPriority: 45,
    ability: 'Cumulative Voting Restriction',
    assetPath: 'assets/roles/lightweight.png',
    colorHex: '#FFA500', // Orange - from CB Visuals
    lore:
        "You can't handle your liquor, and you can't handle betrayal. Once you suspect someone, you hold a grudge forever. Your memory is long, but your patience is short.",
    detailedAbility:
        "Each night, you must choose a player to 'block' from your own voting pool. You can never vote for that player again for the rest of the game. This accumulates, limiting your voting options over time.",
    synergies: [RoleIds.bouncer, RoleIds.medic],
    counters: [RoleIds.messyBitch, RoleIds.dealer],
  ),

  Role(
    id: RoleIds.teaSpiller,
    name: 'The Tea Spiller',
    alliance: Team.partyAnimals,
    type: 'Reactive',
    complexity: 2,
    tacticalTip:
        'Your death is an information tool. Ensure you die at a time when your public revelation will cause the most disruption for the Dealers.',
    description:
        'If voted out, immediately expose the role of one player who voted against you.',
    nightPriority: 0,
    ability: 'Death Reveal',
    assetPath: 'assets/roles/tea_spiller.png',
    colorHex: '#FFD700', // Gold - from CB Visuals
    lore:
        "You love the drama, and you love the spotlight. If you're going down, you're taking everyone's secrets with you. Your last words will be the most important ones spoken all night.",
    detailedAbility:
        "If you are eliminated by the day vote, you immediately reveal the role of one player who voted against you. This information is public and confirmed by the Host.",
    synergies: [RoleIds.partyAnimal, RoleIds.bouncer],
    counters: [RoleIds.silverFox, RoleIds.dealer],
  ),

  Role(
    id: RoleIds.predator,
    name: 'The Predator',
    alliance: Team.partyAnimals,
    type: 'Reactive',
    complexity: 3,
    tacticalTip:
        'Make it known that attacking you has a heavy price. Use your retaliatory strike to take out the Dealers\' most influential leader.',
    description:
        'If voted out, choose one of the players who voted against you to die with you.',
    nightPriority: 0,
    ability: 'Death Retaliation',
    assetPath: 'assets/roles/predator.png',
    colorHex: '#2C3539', // Black_Grey - from CB Visuals
    lore:
        "You aren't prey. You never were. If they corner you, you'll show them exactly why they should have been afraid. Revenge is a dish best served immediately.",
    detailedAbility:
        "If you are eliminated by the day vote, you choose one of the players who voted for you to die with you. This is a retaliatory strike that happens instantly.",
    synergies: [RoleIds.partyAnimal, RoleIds.medic],
    counters: [RoleIds.dealer, RoleIds.messyBitch],
  ),

  Role(
    id: RoleIds.dramaQueen,
    name: 'The Drama Queen',
    alliance: Team.partyAnimals,
    type: 'Reactive',
    complexity: 4,
    tacticalTip:
        'Swapping roles can sow total chaos. Use it to confuse the Dealers and steal a powerful card from someone you suspect is evil.',
    description:
        'When killed, swap two cards with remaining players and look at the swapped cards.',
    nightPriority: 0,
    ability: 'Vendetta Power',
    assetPath: 'assets/roles/drama_queen.png',
    colorHex: '#000080', // Navy - from CB Visuals
    lore:
        "The center of attention, for better or worse. You thrive on chaos and confusion. Even in death, you manage to make everything about you.",
    detailedAbility:
        "Upon death (by any means), you trigger a 'Card Swap'. You choose two living players and swap their role cards. You learn the new roles, but the players themselves might not realize the swap happened immediately.",
    synergies: [RoleIds.messyBitch, RoleIds.creep],
    counters: [RoleIds.bouncer, RoleIds.medic],
  ),

  Role(
    id: RoleIds.bartender,
    name: 'The Bartender',
    alliance: Team.partyAnimals,
    type: 'Investigative',
    complexity: 4,
    tacticalTip:
        'Comparing alignment is powerful but subtle. Look for players who claim to be on the same side and verify if they are truly aligned.',
    description:
        'Each night, choose two players. Learn if they are ALIGNED (same side) or NOT ALIGNED.',
    nightPriority: 35,
    ability: 'Mixology',
    assetPath: 'assets/roles/bartender.png',
    colorHex: '#4B0082', // Indigo - from CB Visuals
    lore:
        "You serve the drinks, you hear the stories. You know who's sitting together and who's sitting apart. You can tell who's drinking from the same bottle.",
    detailedAbility:
        "Each night, select two players. The Host will signal if they are 'Aligned' (on the same team) or 'Not Aligned' (on different teams). You do not learn their specific roles, only their relationship.",
    synergies: [RoleIds.bouncer, RoleIds.medic],
    counters: [RoleIds.dealer, RoleIds.messyBitch],
  ),

  // ═══════════════════════════════════════════════
  //  WILDCARDS (Variables)
  // ═══════════════════════════════════════════════
  Role(
    id: RoleIds.messyBitch,
    name: 'The Messy Bitch',
    alliance: Team.neutral,
    type: 'Chaos',
    complexity: 5,
    tacticalTip:
        'Chaos is your win condition. Spread enough rumours to keep the town distracted while you work towards your solo victory.',
    description:
        'Each night, start a rumour about a player. Win immediately if every living player has heard a rumour.',
    nightPriority: 40,
    ability: 'The Rumour Mill',
    assetPath: 'assets/roles/messy_bitch.png',
    colorHex: '#E6E6FA', // Lavender - from CB Visuals
    lore:
        "Some people just want to watch the world burn. You? You brought the matches. The truth is boring. A good rumor is forever.",
    detailedAbility:
        "Each night, you start a Rumour about a specific player. This rumour spreads to other players. If, at any point, every living player has heard a rumour (not necessarily the same one), you win instantly and the game ends.",
    synergies: [RoleIds.dramaQueen, RoleIds.creep],
    counters: [RoleIds.dealer, RoleIds.bouncer],
  ),

  Role(
    id: RoleIds.clubManager,
    name: 'The Club Manager',
    alliance: Team.neutral,
    type: 'Investigative',
    complexity: 3,
    tacticalTip:
        'Survival is your only goal. Gather intel to stay ahead of the curve, but don\'t become such a threat that the Dealers target you.',
    description:
        'Every night, secretly look at a fellow player\'s role card. Objective is pure self-survival.',
    nightPriority: 25,
    ability: 'Sight Card',
    assetPath: 'assets/roles/club_manager.png',
    colorHex: '#D2B48C', // Taupe - from CB Visuals
    lore:
        "This is your club. These are your people. Or at least, they were. Now you're just trying to survive the night without getting caught in the crossfire. You see everything, but you say nothing.",
    detailedAbility:
        "Each night, you can look at the role card of one other player. You learn their exact role. Your goal is simply to survive until the end of the game, regardless of who wins.",
    synergies: [RoleIds.bouncer, RoleIds.wallflower],
    counters: [RoleIds.dealer, RoleIds.roofi],
  ),

  Role(
    id: RoleIds.clinger,
    name: 'The Clinger',
    alliance: Team.neutral,
    type: 'Passive-Aggressive',
    complexity: 4,
    tacticalTip:
        'Your partner is your life. Protect them at all costs, but be ready to snap and take your revenge if they are eliminated.',
    description:
        'Obsessed with a partner. Must support their vote. If they die, you die. Can be freed as an Attack Dog.',
    nightPriority: 10, // Changed from 0 to 10 to act as Attack Dog
    ability: 'Obsession + Attack Dog',
    assetPath: 'assets/roles/clinger.png',
    colorHex: '#FFFF00', // Yellow - from CB Visuals
    lore:
        "You're not here for the party. You're here for *them*. If they leave, you leave. If they die, you die. It's romantic... in a twisted, codependent sort of way.",
    detailedAbility:
        "At the start of the game, you are linked to another player (your Partner). You must vote with them. If they are eliminated, you are also eliminated. However, if they die at night, you might snap and become an Attack Dog.",
    synergies: [RoleIds.medic, RoleIds.silverFox],
    counters: [RoleIds.dealer, RoleIds.teaSpiller],
  ),

  Role(
    id: RoleIds.secondWind,
    name: 'The Second Wind',
    alliance: Team.partyAnimals,
    startAlliance: Team.partyAnimals,
    type: 'Convertible',
    complexity: 4,
    tacticalTip:
        'You are a wildcard. Negotiate with both sides to see who offers you the best chance of staying alive and returning to the lounge.',
    description:
        'If Dealers try to kill you, you survive. Next day they can convert you (revive as Dealer) or execute you.',
    nightPriority: 0,
    ability: 'Conversion Opportunity',
    assetPath: 'assets/roles/second_wind.png',
    colorHex: '#DE3163', // Cherry - from CB Visuals
    lore:
        "You've always been a survivor. When life knocks you down, you get back up. But sometimes, getting back up means changing who you are.",
    detailedAbility:
        "If the Dealers attempt to kill you at night, you survive. The next morning, you are presented with a choice: join the Dealers (become a Dealer) or remain a Party Animal. If you refuse, they can try to kill you again.",
    synergies: [RoleIds.medic, RoleIds.dealer],
    counters: [RoleIds.bouncer, RoleIds.wallflower],
  ),

  Role(
    id: RoleIds.creep,
    name: 'The Creep',
    alliance: Team.neutral,
    type: 'Mimic',
    complexity: 4,
    tacticalTip:
        'Lurk in the shadows. Wait for a powerful role to die and then step into their shoes to change the game\'s direction at the perfect moment.',
    description:
        'At Night 0, choose a player to mimic. Your alliance becomes theirs. When they die, you inherit their role.',
    nightPriority: 0,
    ability: 'Pretend Role + Inheritance',
    assetPath: 'assets/roles/creep.png',
    colorHex: '#800080', // Purple - from CB Visuals
    lore:
        "You have no identity of your own. You're a shadow, a mimic, a void waiting to be filled. You watch, you wait, and when the time is right, you become someone else.",
    detailedAbility:
        "On Night 0, choose a player to Mimic. You adopt their team alignment immediately. If that player dies, you inherit their role and ability. Until then, you are just a generic member of their team.",
    synergies: [RoleIds.dramaQueen, RoleIds.messyBitch],
    counters: [RoleIds.bouncer, RoleIds.medic],
  ),
];

/// A map of role IDs to their corresponding Role objects for O(1) lookup.
final Map<String, Role> roleCatalogMap = {
  for (final role in roleCatalog) role.id: role,
};
