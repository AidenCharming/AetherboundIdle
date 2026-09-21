// Authoritative zod schemas for every file in src/data/. Shape is defined in docs/plan.md section 3;
// cross-file reference checks (does this ID exist?) live in index.ts, because zod only sees one file.
import { z } from 'zod'

// ---------- vocabularies (enums live here, never as free strings; plan.md section 2) ----------

export const STRENGTHS = ['minor', 'moderate', 'major'] as const
export const STAT_LEANS = ['health', 'power', 'guard'] as const
export const TEMPOS = ['quick', 'standard', 'heavy'] as const
export const ABILITY_EFFECTS = [
  'single-target-damage', 'multi-target-damage', 'heal-instant', 'heal-over-time',
  'buff-power', 'buff-guard', 'shield-self', 'shield-party', 'thorns',
] as const
export const DAMAGE_EFFECTS: readonly (typeof ABILITY_EFFECTS)[number][] = ['single-target-damage', 'multi-target-damage']
export const RESOURCE_KINDS = ['raw', 'refined', 'crafted', 'rare'] as const
export const EFFECT_TARGETS = ['self', 'party', 'active-creatures', 'other-active-in-skill'] as const
export const MODIFIER_UNITS = ['percent', 'flat', 'count'] as const

/** The complete allowed trait-mechanic list (design section 4, "nothing else"). */
export const EFFECT_KEYS = [
  'extra_output_chance', 'offline_extra_output_chance', 'save_material_chance', 'cooldown_reduction',
  'bonus_xp', 'rare_drop_chance', 'treasure_drop_chance', 'bench_aether_emission', 'bind_rate',
  'free_bind_attempts', 'hatch_time_reduction', 'mutation_odds', 'attunement_cost_reduction',
  'bonus_health', 'bonus_power', 'bonus_guard', 'ability_cooldown_reduction', 'bonus_combat_xp',
  'partner_element_drop_chance',
] as const

export type Strength = (typeof STRENGTHS)[number]
export type StatLean = (typeof STAT_LEANS)[number]
export type Tempo = (typeof TEMPOS)[number]
export type AbilityEffect = (typeof ABILITY_EFFECTS)[number]
export type EffectKey = (typeof EFFECT_KEYS)[number]

// ---------- primitives ----------

/** Kebab-case ASCII slug: `sproutlet`, `aether-weaving`. */
const Id = z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'must be a kebab-case ASCII slug')
/** Display strings are copied verbatim from content-data.md, so only reject empty or padded values. */
const Name = z.string().min(1).refine((s) => s === s.trim(), 'must not have leading or trailing whitespace')
const Hex = z.string().regex(/^#[0-9a-fA-F]{6}$/, 'must be a #rrggbb color')
const Positive = z.number().positive()
const Fraction = z.number().min(0).max(1)
const PosInt = z.number().int().positive()
/** A real emoji character, so a placeholder like "(seedling)" is rejected at load. */
const Emoji = z.string().regex(/^\p{Extended_Pictographic}/u, 'must be a real emoji character, not a placeholder')

// ---------- types.json ----------

export const TypeSchema = z
  .strictObject({
    id: Id,
    name: Name,
    element: Name,
    color: Hex,
    lockedSkills: z.array(Id).min(1),
    wheel: z.strictObject({ beats: Id, resists: Id }).nullable(),
    outsideWheel: z.boolean(),
    /**
     * Optional: the runtime hue rotation, in degrees, of a shiny of this type (a creature's first-listed type decides).
     * Same rule as tuning.ui.shinyHueDeg, strictly between 0 and 360, or a shiny would look like a normal creature. A
     * type without one falls back to tuning.ui.shinyHueDeg. Void has one because a violet turned by the global 150 lands
     * on a muddy olive.
     */
    shinyHueDeg: z.number().gt(0).lt(360).optional(),
  })
  .refine((t) => t.outsideWheel === (t.wheel === null), 'outsideWheel must be true exactly when wheel is null')

// ---------- skills.json ----------

export const SkillSchema = z
  .strictObject({
    id: Id,
    /** Optional: the nav and the skill page fall back to a plain glyph for a skill without one. */
    emoji: Emoji.optional(),
    name: Name,
    requiredType: Id.nullable(),
    open: z.boolean(),
    slotUnlockLevels: z.array(PosInt).min(1),
    maxLevel: PosInt,
  })
  .refine((s) => s.open === (s.requiredType === null), 'open must be true exactly when requiredType is null')
  .refine(
    (s) => s.slotUnlockLevels[0] === 1 && s.slotUnlockLevels.every((n, i, a) => i === 0 || n > a[i - 1]!),
    'slotUnlockLevels must start at 1 and strictly increase',
  )

// ---------- rarities.json / gear-rarities.json ----------

export const RaritySchema = z.strictObject({
  tier: PosInt,
  id: Id,
  name: Name,
  statMultiplier: Positive,
  benchEmissionPerMin: z.number().min(0),
  frame: z.strictObject({ tint: Hex, glow: Fraction }),
})

export const GearRaritySchema = z.strictObject({ tier: PosInt, id: Id, name: Name })

// ---------- resources.json ----------

export const ResourceSchema = z
  .strictObject({
    id: Id,
    name: Name,
    /** Optional: the UI falls back to a type-colored dot for a resource without one. */
    emoji: Emoji.optional(),
    tier: PosInt,
    skill: Id,
    kind: z.enum(RESOURCE_KINDS),
    elementType: Id,
    // Null on items that are dropped rather than gathered (kind "rare").
    requiredSkillLevel: PosInt.nullable(),
    baseActionMs: PosInt.nullable(),
    xpPerAction: z.number().min(0).nullable(),
    goldValue: z.number().min(0),
    rareDrop: z.strictObject({ id: Id, chance: Fraction }).nullable(),
  })
  .refine(
    (r) => r.kind !== 'raw' || (r.requiredSkillLevel !== null && r.baseActionMs !== null && r.xpPerAction !== null),
    'a raw resource needs requiredSkillLevel, baseActionMs and xpPerAction',
  )

// ---------- abilities.json ----------

export const AbilitySchema = z
  .strictObject({
    id: Id,
    name: Name,
    effect: z.enum(ABILITY_EFFECTS),
    // Required for damage effects. Non-damage abilities may also carry one (content-data.md gives the
    // hybrids' heals and shields a type); the sim only reads it for damage.
    damageType: Id.nullable(),
    tempo: z.enum(TEMPOS),
    magnitude: Positive,
  })
  .refine((a) => !DAMAGE_EFFECTS.includes(a.effect) || a.damageType !== null, 'a damage ability needs a damageType')

// ---------- traits.json ----------

const StrengthValues = z
  .strictObject({ minor: z.number().optional(), moderate: z.number().optional(), major: z.number().optional() })
  .refine((v) => Object.values(v).some((n) => n !== undefined), 'valueByStrength needs at least one strength')

export const EffectSchema = z
  .strictObject({
    key: z.enum(EFFECT_KEYS),
    scope: z.strictObject({
      target: z.enum(EFFECT_TARGETS),
      skills: z.array(Id).min(1).optional(),
      types: z.array(Id).min(1).optional(),
    }),
    /** Present only on the two aura signatures; drives "strongest of each kind applies, never stacks". */
    aura: z.strictObject({ group: Id, stacking: z.literal('strongest-only') }).optional(),
    /** Overclocked: a stacking cooldown reduction that resets on task completion. */
    dynamic: z
      .strictObject({ kind: z.literal('stacking-until-complete'), perStack: Positive, maxStacks: PosInt })
      .optional(),
    /** Which element resource a `partner_element_drop_chance` effect drops. */
    elementType: Id.optional(),
    /** Absent means "use tuning.traitStrength.default"; the loader fills it in. */
    valueByStrength: StrengthValues.optional(),
  })
  .refine((e) => (e.key === 'partner_element_drop_chance') === (e.elementType !== undefined),
    'elementType is required on partner_element_drop_chance and only allowed there')
  .refine((e) => e.dynamic === undefined || e.valueByStrength === undefined,
    'a dynamic effect carries its own perStack, so it takes no valueByStrength')

const TraitBase = { id: Id, name: Name, text: Name, effects: z.array(EffectSchema).min(1) }

export const SignatureTraitSchema = z.strictObject({
  ...TraitBase,
  kind: z.literal('signature'),
  species: Id,
  defaultStrength: z.enum(STRENGTHS),
})

export const PoolTraitSchema = z.strictObject({
  ...TraitBase,
  kind: z.literal('pool'),
  /** `universal-econ | universal-combat | void-only | <type id>`; the type ids are checked at load. */
  category: Id,
  rollWeight: Positive,
  typeAffinity: Id.nullable(),
  minStrength: z.enum(STRENGTHS).nullable(),
})

export const TraitSchema = z.discriminatedUnion('kind', [SignatureTraitSchema, PoolTraitSchema])

// ---------- species.json / hybrids.json ----------

const FormSchema = z.strictObject({
  form: z.number().int().min(1).max(3),
  name: Name,
  emoji: Emoji,
  /** Placeholder-art prompt. content-data.md only describes base species, so hybrid forms omit it. */
  art: Name.optional(),
})

const CreatureBase = {
  id: Id,
  name: Name,
  forms: z.array(FormSchema).length(3),
  primarySkill: Id,
  secondaryAptitude: Id,
  statLean: z.enum(STAT_LEANS),
  signatureTrait: Id,
  ability: Id,
}

const formsInOrder = (c: { forms: { form: number }[] }) => c.forms.every((f, i) => f.form === i + 1)

export const SpeciesSchema = z
  .strictObject({
    ...CreatureBase,
    types: z.array(Id).length(1),
    origin: z.literal('wild'),
    /** Art direction that applies to the whole species, e.g. "Stays cute." */
    artNote: Name.optional(),
  })
  .refine(formsInOrder, 'forms must be numbered 1, 2, 3 in order')

export const HybridSchema = z
  .strictObject({
    ...CreatureBase,
    types: z.array(Id).length(2),
    /** The two type IDs, sorted: the default-hybrid lookup key. */
    pair: z.tuple([Id, Id]),
    isDefaultForPair: z.boolean(),
    coveredSkills: z.array(Id).min(2),
    origin: z.literal('breed'),
  })
  .refine(formsInOrder, 'forms must be numbered 1, 2, 3 in order')

// ---------- recipes.json ----------

export const RecipesSchema = z.strictObject({
  special: z.array(z.strictObject({ parents: z.tuple([Id, Id]), result: Id, hint: Name })),
  sameTypeSiblingChance: Fraction,
})

// ---------- modifiers.json (the cap registry) ----------

export const ModifierSchema = z.strictObject({
  key: z.enum(EFFECT_KEYS),
  unit: z.enum(MODIFIER_UNITS),
  stacking: z.literal('additive'),
  cap: Positive,
  note: Name.optional(),
})

// ---------- tuning.json ----------

const ByForm = z.strictObject({ '1': z.number(), '2': z.number(), '3': z.number() })
const SpriteFraction = z.number().gt(0).lte(1)
const SpriteScale = z.strictObject({ '1': SpriteFraction, '2': SpriteFraction, '3': SpriteFraction })
const Curve = z.strictObject({ base: Positive, growth: z.number().min(1) })
// combat.tempo is empty until phase 3 authors the combat numbers (plan.md 3.10 ships them as `{}`).
const TempoSchema = z.strictObject({ effectMultiplier: Positive.optional(), cooldownMs: PosInt.optional() })

export const TuningSchema = z.strictObject({
  creature: z.strictObject({
    maxLevel: PosInt,
    /** design.md section 3: a creature has up to 3 pool traits. Only the dev panel's picker reads it before phase 2. */
    maxPoolTraits: PosInt,
    baseStats: z.strictObject({ health: Positive, power: Positive, guard: Positive }),
    statLeanMultiplier: z.strictObject({ leaned: Positive, other: Positive }),
    statPerLevel: z.number().min(0),
    formUnlockLevels: z.strictObject({ '2': PosInt, '3': PosInt }),
    formMultiplier: ByForm,
  }),
  cooldown: z.strictObject({
    floorFraction: z.number().gt(0).lt(1),
    levelTermPerLevel: z.number().min(0),
    rarityTermPerTier: z.number().min(0),
    formTerm: ByForm,
  }),
  xp: z.strictObject({ skillCurve: Curve, creatureCurve: Curve }),
  skills: z.strictObject({ secondaryAptitudeBonus: z.number().min(0), hybridOffPrimaryEfficiency: z.number().gt(0).max(1) }),
  // awayThresholdMs is the gap that counts as "away" while the tab is open (a sleeping laptop, a throttled tab).
  // A gap at or under it is a plain step; a longer one is routed through the offline path, so `capHours` applies to
  // an open tab exactly as it does to a closed one (designer, 2026-09-19). It must stay below the cap, or a gap
  // could never be both routed and uncapped.
  offline: z.strictObject({ capHours: Positive, maxSegmentsPerSlot: PosInt, awayThresholdMs: PosInt }),
  aether: z.strictObject({ benchEmissionTickMs: PosInt }),
  traitStrength: z.strictObject({
    default: z.strictObject({ minor: Positive, moderate: Positive, major: Positive }),
  }),
  breeding: z.strictObject({
    mutationPlusOne: Fraction,
    mutationPlusTwo: Fraction,
    costByCeiling: z.array(Positive).min(1),
    costGrowthPerTier: Positive,
  }),
  shiny: z.strictObject({
    encounterRate: Fraction,
    encounterPityStart: PosInt,
    hatchRate: Fraction,
    hatchPityStart: PosInt,
  }),
  attunement: z.strictObject({ lockCostMultiplier: z.array(Positive).length(3) }),
  combat: z.strictObject({
    wheelStrong: Positive,
    wheelWeak: Positive,
    voidDealt: Positive,
    voidTaken: Positive,
    voidHybridFraction: Fraction,
    tempo: z.strictObject({ quick: TempoSchema, standard: TempoSchema, heavy: TempoSchema }),
  }),
  save: z.strictObject({ version: PosInt, autosaveMs: PosInt }),
  // How often the UI's tick driver steps the sim. Presentation cadence only: the sim takes any dt, so it never
  // changes what a player earns (same rule as aether.benchEmissionTickMs).
  // shinyHueDeg is the runtime CSS hue rotation on a shiny's art (CLAUDE.md rule 4: never a separate asset). It must
  // sit strictly between 0 and 360, or a shiny would look exactly like a normal creature.
  // spriteFormScale is how big a creature's sprite is drawn in its art tile, per form, as a fraction of the tile (1 fills it).
  // The sprites are all cropped to their own bounding box, so without it a Form 1 chibi would fill the tile as much as a
  // Form 3 and growth would not show. PLACEHOLDER, designer to adjust. Each factor is above 0 and at most 1 (a sprite
  // never overflows its tile), and a later form is never smaller than an earlier one, so growth never runs backwards.
  // pacingMilestones are the extra skill levels the Settings "Skill milestones" table reports the time to, on top of
  // the levels the data already makes interesting (each skill's slot unlock levels and its max level). PLACEHOLDER,
  // designer to adjust: they change nothing in the game, only which rows that table shows. The table never has a row
  // for level 1 (the first slot is unlocked at the start), so 2 is what makes the first level-up visible.
  ui: z.strictObject({
    tickMs: PosInt,
    shinyHueDeg: z.number().gt(0).lt(360),
    spriteFormScale: SpriteScale.refine((s) => s['1'] <= s['2'] && s['2'] <= s['3'], 'a later form must not be drawn smaller than an earlier one'),
    activityPanelMax: PosInt,
    maxNotifications: PosInt,
    maxToasts: PosInt,
    toastMs: PosInt,
    pacingMilestones: z.array(PosInt).min(1),
  }),
})

// ---------- zones.json / vessels.json / collection-tracks.json (phase 3/4; shipped empty) ----------
// The plan only promises that these schemas exist. The fields below come from design sections 8-9 and are
// the minimum the later phases need; extend them when the content lands.

export const ZoneSchema = z.strictObject({
  id: Id,
  name: Name,
  type: Id,
  wildRarityCeiling: PosInt,
  nativeSpecies: z.array(Id),
  boss: z.strictObject({ id: Id, name: Name }).nullable(),
})

export const VesselSchema = z.strictObject({ id: Id, name: Name, tier: PosInt })

export const CollectionTrackSchema = z.strictObject({ id: Id, name: Name, milestones: z.array(PosInt).min(1) })

// ---------- file registry ----------

/** One schema per file in src/data/, keyed by the file's stem (`gear-rarities` -> `gearRarities`). */
export const FILE_SCHEMAS = {
  types: z.array(TypeSchema),
  skills: z.array(SkillSchema),
  rarities: z.array(RaritySchema),
  gearRarities: z.array(GearRaritySchema),
  resources: z.array(ResourceSchema),
  abilities: z.array(AbilitySchema),
  traits: z.array(TraitSchema),
  species: z.array(SpeciesSchema),
  hybrids: z.array(HybridSchema),
  recipes: RecipesSchema,
  modifiers: z.array(ModifierSchema),
  tuning: TuningSchema,
  zones: z.array(ZoneSchema),
  vessels: z.array(VesselSchema),
  collectionTracks: z.array(CollectionTrackSchema),
} as const

export type ContentKey = keyof typeof FILE_SCHEMAS

// ---------- inferred types ----------

export type TypeDef = z.infer<typeof TypeSchema>
export type Skill = z.infer<typeof SkillSchema>
export type Rarity = z.infer<typeof RaritySchema>
export type GearRarity = z.infer<typeof GearRaritySchema>
export type Resource = z.infer<typeof ResourceSchema>
export type Ability = z.infer<typeof AbilitySchema>
export type Effect = z.infer<typeof EffectSchema>
export type SignatureTrait = z.infer<typeof SignatureTraitSchema>
export type PoolTrait = z.infer<typeof PoolTraitSchema>
export type Trait = z.infer<typeof TraitSchema>
export type Form = z.infer<typeof FormSchema>
export type Species = z.infer<typeof SpeciesSchema>
export type Hybrid = z.infer<typeof HybridSchema>
export type Recipes = z.infer<typeof RecipesSchema>
export type Modifier = z.infer<typeof ModifierSchema>
export type Tuning = z.infer<typeof TuningSchema>
export type Zone = z.infer<typeof ZoneSchema>
export type Vessel = z.infer<typeof VesselSchema>
export type CollectionTrack = z.infer<typeof CollectionTrackSchema>
