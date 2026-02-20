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
    nightPriority: 8, // Changed from 15 to 8 to ensure it blocks Dealers (Priority 10)
    ability: 'Paralyze',
    assetPath: 'assets/roles/roofi.png',
    colorHex: '#008000', // Green - from CB Visuals
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
  ),

  Role(
    id: RoleIds.lightweight,
    name: 'The Lightweight',
    alliance: Team.partyAnimals,
    type: 'Passive',
    complexity: 5,
    tacticalTip:
        'The Taboo name is a powerful social weapon. Use the pressure of the Bar Tab to flush out players who aren\'t paying close attention.',
    description:
        'After every night, a name becomes taboo. If you speak that name, you die immediately.',
    nightPriority: 45,
    ability: 'Memory Loss (Taboo)',
    assetPath: 'assets/roles/lightweight.png',
    colorHex: '#FFA500', // Orange - from CB Visuals
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
  ),
];

/// A map of role IDs to their corresponding Role objects for O(1) lookup.
final Map<String, Role> roleCatalogMap = {
  for (final role in roleCatalog) role.id: role,
};
