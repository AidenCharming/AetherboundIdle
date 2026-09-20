// Loaders: parse every JSON file against its zod schema, fill defaults, then cross-check every ID
// reference. A bad reference throws at load listing every problem, rather than surfacing later as
// `undefined` mid-game (plan.md section 2). Nothing outside src/data/ should import the raw JSON.
import abilitiesJson from './abilities.json'
import collectionTracksJson from './collection-tracks.json'
import gearRaritiesJson from './gear-rarities.json'
import hybridsJson from './hybrids.json'
import modifiersJson from './modifiers.json'
import raritiesJson from './rarities.json'
import recipesJson from './recipes.json'
import resourcesJson from './resources.json'
import skillsJson from './skills.json'
import speciesJson from './species.json'
import traitsJson from './traits.json'
import tuningJson from './tuning.json'
import typesJson from './types.json'
import vesselsJson from './vessels.json'
import zonesJson from './zones.json'
import {
  EFFECT_KEYS,
  FILE_SCHEMAS,
  STRENGTHS,
  type Ability,
  type CollectionTrack,
  type ContentKey,
  type Effect,
  type GearRarity,
  type Hybrid,
  type Modifier,
  type Rarity,
  type Recipes,
  type Resource,
  type Skill,
  type Species,
  type Trait,
  type Tuning,
  type TypeDef,
  type Vessel,
  type Zone,
} from './schema'

export * from './schema'

/** The raw, unvalidated JSON, exposed so tests can mutate a copy and prove the loader rejects it. */
export const rawContent: Record<ContentKey, unknown> = {
  types: typesJson,
  skills: skillsJson,
  rarities: raritiesJson,
  gearRarities: gearRaritiesJson,
  resources: resourcesJson,
  abilities: abilitiesJson,
  traits: traitsJson,
  species: speciesJson,
  hybrids: hybridsJson,
  recipes: recipesJson,
  modifiers: modifiersJson,
  tuning: tuningJson,
  zones: zonesJson,
  vessels: vesselsJson,
  collectionTracks: collectionTracksJson,
}

export class ContentError extends Error {
  readonly problems: readonly string[]
  constructor(problems: readonly string[]) {
    super(`Content failed to load (${problems.length} problem${problems.length === 1 ? '' : 's'}):\n - ${problems.join('\n - ')}`)
    this.name = 'ContentError'
    this.problems = problems
  }
}

export interface Content {
  types: readonly TypeDef[]
  typeById: ReadonlyMap<string, TypeDef>
  skills: readonly Skill[]
  skillById: ReadonlyMap<string, Skill>
  rarities: readonly Rarity[]
  gearRarities: readonly GearRarity[]
  resources: readonly Resource[]
  resourceById: ReadonlyMap<string, Resource>
  abilities: readonly Ability[]
  abilityById: ReadonlyMap<string, Ability>
  /** Signature and pool traits. Every effect has `valueByStrength` filled in (unless it is dynamic). */
  traits: readonly Trait[]
  traitById: ReadonlyMap<string, Trait>
  species: readonly Species[]
  hybrids: readonly Hybrid[]
  /** Species and hybrids together, for anything that just needs "a creature definition". */
  creatureById: ReadonlyMap<string, Species | Hybrid>
  /** Default hybrid per sorted type pair; key it with `pairKey`. */
  defaultHybridByPair: ReadonlyMap<string, Hybrid>
  recipes: Recipes
  modifiers: readonly Modifier[]
  modifierByKey: ReadonlyMap<string, Modifier>
  tuning: Tuning
  zones: readonly Zone[]
  vessels: readonly Vessel[]
  collectionTracks: readonly CollectionTrack[]
}

/** Lookup key for a type pair; order-independent. */
export const pairKey = (a: string, b: string): string => [a, b].sort().join('|')

const fileName = (key: ContentKey): string => key.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`) + '.json'

function formatPath(path: readonly PropertyKey[]): string {
  return path.map((p) => (typeof p === 'number' ? `[${p}]` : `.${String(p)}`)).join('')
}

type Parsed = { [K in ContentKey]: (typeof FILE_SCHEMAS)[K]['_output'] }

function parseAll(raw: Record<ContentKey, unknown>): Parsed {
  const problems: string[] = []
  const out: Record<string, unknown> = {}
  for (const key of Object.keys(FILE_SCHEMAS) as ContentKey[]) {
    const result = FILE_SCHEMAS[key].safeParse(raw[key])
    if (result.success) {
      out[key] = result.data
      continue
    }
    const file = raw[key]
    for (const issue of result.error.issues) {
      const head = issue.path[0]
      const id = Array.isArray(file) && typeof head === 'number' ? (file[head] as { id?: string } | undefined)?.id : undefined
      problems.push(`${fileName(key)}${formatPath(issue.path)}${id ? ` (${id})` : ''}: ${issue.message}`)
    }
  }
  if (problems.length > 0) throw new ContentError(problems)
  return out as Parsed
}

function indexBy<T>(file: string, items: readonly T[], keyOf: (item: T) => string, problems: string[]): Map<string, T> {
  const map = new Map<string, T>()
  for (const item of items) {
    const key = keyOf(item)
    if (map.has(key)) problems.push(`${file}: duplicate id "${key}"`)
    map.set(key, item)
  }
  return map
}

export function loadContent(raw: Record<ContentKey, unknown>): Content {
  const data = parseAll(raw)
  const problems: string[] = []
  const check = (ok: boolean, message: string): void => {
    if (!ok) problems.push(message)
  }

  const byId = <T extends { id: string }>(file: string, items: readonly T[]) => indexBy(file, items, (i) => i.id, problems)

  const typeById = byId('types.json', data.types)
  const skillById = byId('skills.json', data.skills)
  const resourceById = byId('resources.json', data.resources)
  const abilityById = byId('abilities.json', data.abilities)
  byId('rarities.json', data.rarities)
  byId('gear-rarities.json', data.gearRarities)
  byId('zones.json', data.zones)
  byId('vessels.json', data.vessels)
  byId('collection-tracks.json', data.collectionTracks)
  const modifierByKey = indexBy('modifiers.json', data.modifiers, (m) => m.key, problems)

  // Fill traitStrength defaults, as plan.md 3.6 specifies, before anything reads an effect.
  const defaults = data.tuning.traitStrength.default
  const fillEffect = (e: Effect): Effect => (e.valueByStrength || e.dynamic ? e : { ...e, valueByStrength: { ...defaults } })
  const traits: Trait[] = data.traits.map((t) => ({ ...t, effects: t.effects.map(fillEffect) }))
  const traitById = byId('traits.json', traits)

  const creatures = [...data.species, ...data.hybrids]
  const creatureById = byId('species.json / hybrids.json', creatures)
  const speciesIds = new Set(data.species.map((s) => s.id))

  // ----- types and skills agree with each other -----
  for (const t of data.types) {
    for (const s of t.lockedSkills) {
      const skill = skillById.get(s)
      check(!!skill, `types.json ${t.id}: lockedSkills "${s}" is not a skill`)
      if (skill) check(skill.requiredType === t.id, `types.json ${t.id}: locks "${s}", but that skill's requiredType is ${skill.requiredType}`)
    }
    if (t.wheel) {
      const beats = typeById.get(t.wheel.beats)
      const resists = typeById.get(t.wheel.resists)
      check(!!beats, `types.json ${t.id}: wheel.beats "${t.wheel.beats}" is not a type`)
      check(!!resists, `types.json ${t.id}: wheel.resists "${t.wheel.resists}" is not a type`)
      check(t.wheel.beats !== t.id && t.wheel.resists !== t.id, `types.json ${t.id}: cannot beat or resist itself`)
      if (beats) check(beats.wheel?.resists === t.id, `types.json ${t.id}: beats ${beats.id}, but ${beats.id} does not resist ${t.id}`)
      if (resists) check(resists.wheel?.beats === t.id, `types.json ${t.id}: resists ${resists.id}, but ${resists.id} does not beat ${t.id}`)
    }
  }
  for (const s of data.skills) {
    if (s.requiredType === null) continue
    const type = typeById.get(s.requiredType)
    check(!!type, `skills.json ${s.id}: requiredType "${s.requiredType}" is not a type`)
    if (type) check(type.lockedSkills.includes(s.id), `skills.json ${s.id}: ${type.id} does not list it in lockedSkills`)
    check(s.maxLevel >= s.slotUnlockLevels[s.slotUnlockLevels.length - 1]!, `skills.json ${s.id}: maxLevel is below its last slot unlock`)
  }

  // ----- rarity ladders -----
  const tiersContiguous = (items: readonly { tier: number }[]) => items.every((r, i) => r.tier === i + 1)
  check(tiersContiguous(data.rarities), 'rarities.json: tiers must run 1, 2, 3, ... in order')
  check(tiersContiguous(data.gearRarities), 'gear-rarities.json: tiers must run 1, 2, 3, ... in order')
  check(data.rarities.length === data.gearRarities.length, 'rarities.json and gear-rarities.json must have the same number of tiers')

  // ----- resources -----
  for (const r of data.resources) {
    const skill = skillById.get(r.skill)
    check(!!skill, `resources.json ${r.id}: skill "${r.skill}" is not a skill`)
    check(typeById.has(r.elementType), `resources.json ${r.id}: elementType "${r.elementType}" is not a type`)
    check(r.tier <= data.rarities.length, `resources.json ${r.id}: tier ${r.tier} is above the top rarity tier`)
    if (skill && r.requiredSkillLevel !== null) {
      check(r.requiredSkillLevel <= skill.maxLevel, `resources.json ${r.id}: requiredSkillLevel is above ${r.skill}'s maxLevel`)
    }
    if (r.rareDrop) {
      const drop = resourceById.get(r.rareDrop.id)
      check(!!drop, `resources.json ${r.id}: rareDrop "${r.rareDrop.id}" is not a resource`)
      if (drop) check(drop.kind === 'rare', `resources.json ${r.id}: rareDrop "${drop.id}" must have kind "rare"`)
    }
  }

  // ----- abilities -----
  for (const a of data.abilities) {
    if (a.damageType !== null) check(typeById.has(a.damageType), `abilities.json ${a.id}: damageType "${a.damageType}" is not a type`)
  }

  // ----- modifier registry -----
  for (const key of EFFECT_KEYS) check(modifierByKey.has(key), `modifiers.json: no entry for effect key "${key}"`)

  // ----- traits -----
  const poolCategories = new Set(['universal-econ', 'universal-combat', 'void-only', ...typeById.keys()])
  for (const t of traits) {
    if (t.kind === 'signature') {
      const owner = creatureById.get(t.species)
      check(!!owner, `traits.json ${t.id}: species "${t.species}" is not a species or hybrid`)
      if (owner) check(owner.signatureTrait === t.id, `traits.json ${t.id}: ${owner.id}.signatureTrait is "${owner.signatureTrait}"`)
    } else {
      check(poolCategories.has(t.category), `traits.json ${t.id}: category "${t.category}" is not universal-econ, universal-combat, void-only or a type`)
      if (t.typeAffinity !== null) check(typeById.has(t.typeAffinity), `traits.json ${t.id}: typeAffinity "${t.typeAffinity}" is not a type`)
      if (typeById.has(t.category)) check(t.typeAffinity === t.category, `traits.json ${t.id}: a ${t.category} trait needs typeAffinity "${t.category}"`)
      if (t.category === 'void-only') check(t.minStrength === 'moderate', `traits.json ${t.id}: void-only traits roll Moderate at minimum`)
    }
    const reachable =
      t.kind === 'signature' ? [t.defaultStrength] : STRENGTHS.slice(STRENGTHS.indexOf(t.minStrength ?? 'minor'))
    for (const e of t.effects) {
      const modifier = modifierByKey.get(e.key)
      for (const s of e.scope.skills ?? []) check(skillById.has(s), `traits.json ${t.id}: scope skill "${s}" is not a skill`)
      for (const s of e.scope.types ?? []) check(typeById.has(s), `traits.json ${t.id}: scope type "${s}" is not a type`)
      if (e.elementType) check(typeById.has(e.elementType), `traits.json ${t.id}: elementType "${e.elementType}" is not a type`)
      if (e.dynamic) continue
      for (const s of reachable) {
        const v = e.valueByStrength?.[s]
        check(typeof v === 'number', `traits.json ${t.id}: ${e.key} has no value for strength "${s}"`)
        if (typeof v === 'number' && modifier?.unit === 'count') {
          check(Number.isInteger(v), `traits.json ${t.id}: ${e.key} is a count, so "${s}" must be a whole number`)
        }
      }
    }
  }

  // ----- creatures (shared checks for species and hybrids) -----
  const isOpenSkill = (id: string) => skillById.get(id)?.open === true
  for (const c of creatures) {
    const where = `${c.origin === 'wild' ? 'species' : 'hybrids'}.json ${c.id}`
    for (const t of c.types) check(typeById.has(t), `${where}: type "${t}" is not a type`)
    check(skillById.has(c.primarySkill), `${where}: primarySkill "${c.primarySkill}" is not a skill`)
    check(isOpenSkill(c.secondaryAptitude), `${where}: secondaryAptitude "${c.secondaryAptitude}" must be an open skill`)
    check(c.forms[0]?.name === c.name, `${where}: form 1 must use the creature's own name`)

    const trait = traitById.get(c.signatureTrait)
    check(!!trait, `${where}: signatureTrait "${c.signatureTrait}" is not a trait`)
    if (trait) {
      check(trait.kind === 'signature', `${where}: signatureTrait "${trait.id}" is not a signature trait`)
      if (trait.kind === 'signature') check(trait.species === c.id, `${where}: trait "${trait.id}" belongs to "${trait.species}"`)
    }

    const ability = abilityById.get(c.ability)
    check(!!ability, `${where}: ability "${c.ability}" is not an ability`)
    if (ability) {
      if (ability.effect === 'thorns') check(c.types.includes('verdant'), `${where}: thorns is Verdant only`)
      if (ability.damageType !== null) check(c.types.includes(ability.damageType), `${where}: ability type "${ability.damageType}" is not one of its types`)
    }
  }

  // ----- species: one type, works its own type's locked skills -----
  for (const s of data.species) {
    const type = typeById.get(s.types[0]!)
    const skill = skillById.get(s.primarySkill)
    if (type && skill) check(skill.requiredType === type.id, `species.json ${s.id}: primarySkill "${s.primarySkill}" is not one of ${type.id}'s locked skills`)
  }

  // ----- hybrids: cover both parents' skills, one default per pair -----
  const defaultHybridByPair = new Map<string, Hybrid>()
  for (const h of data.hybrids) {
    const [a, b] = h.types as [string, string]
    check(a !== b, `hybrids.json ${h.id}: needs two different types`)
    check(h.pair.join('|') === pairKey(a, b), `hybrids.json ${h.id}: pair must be the two types sorted (${pairKey(a, b)})`)
    const expected = new Set([a, b].flatMap((t) => typeById.get(t)?.lockedSkills ?? []))
    const covered = new Set(h.coveredSkills)
    check(
      covered.size === expected.size && [...expected].every((s) => covered.has(s)),
      `hybrids.json ${h.id}: coveredSkills must be exactly the locked skills of ${a} and ${b}`,
    )
    check(covered.has(h.primarySkill), `hybrids.json ${h.id}: primarySkill "${h.primarySkill}" is not one of its coveredSkills`)
    if (h.isDefaultForPair) {
      const key = pairKey(a, b)
      check(!defaultHybridByPair.has(key), `hybrids.json ${h.id}: "${defaultHybridByPair.get(key)?.id}" is already the default for ${key}`)
      defaultHybridByPair.set(key, h)
    }
    // "Bonus drop of the partner type's element resource": the element must be one of its types, and not the
    // type that owns its primary skill.
    const trait = traitById.get(h.signatureTrait)
    const primaryType = skillById.get(h.primarySkill)?.requiredType
    for (const e of trait?.effects ?? []) {
      if (e.key !== 'partner_element_drop_chance') continue
      check(!!e.elementType && h.types.includes(e.elementType), `hybrids.json ${h.id}: partner drop element "${e.elementType}" is not one of its types`)
      check(e.elementType !== primaryType, `hybrids.json ${h.id}: partner drop element must be the partner type, not "${primaryType}"`)
    }
  }

  // ----- recipes -----
  const seenPairs = new Set<string>()
  for (const r of data.recipes.special) {
    const [a, b] = r.parents
    check(speciesIds.has(a) && speciesIds.has(b), `recipes.json: parents "${a}" and "${b}" must both be base species`)
    check(a <= b, `recipes.json: parents ["${a}", "${b}"] must be stored sorted`)
    const key = pairKey(a, b)
    check(!seenPairs.has(key), `recipes.json: duplicate recipe for ${key}`)
    seenPairs.add(key)
    check(data.hybrids.some((h) => h.id === r.result), `recipes.json: result "${r.result}" is not a hybrid`)
  }

  // ----- tuning -----
  const { creature, traitStrength, offline } = data.tuning
  check(creature.formUnlockLevels['2'] < creature.formUnlockLevels['3'], 'tuning.json: form 2 must unlock before form 3')
  check(creature.formUnlockLevels['3'] <= creature.maxLevel, 'tuning.json: form 3 unlocks above creature.maxLevel')
  check(traitStrength.default.minor < traitStrength.default.moderate && traitStrength.default.moderate < traitStrength.default.major,
    'tuning.json: traitStrength.default must increase minor < moderate < major')
  // A gap longer than awayThresholdMs is routed through the offline path, which clamps it to capHours. A threshold
  // at or above the cap would make every routed gap a capped one, and the cap would silently become the threshold.
  check(offline.awayThresholdMs < offline.capHours * 3_600_000, 'tuning.json: offline.awayThresholdMs must be below offline.capHours')

  // ----- phase 3/4 files -----
  for (const z of data.zones) {
    check(typeById.has(z.type), `zones.json ${z.id}: type "${z.type}" is not a type`)
    for (const s of z.nativeSpecies) check(speciesIds.has(s), `zones.json ${z.id}: nativeSpecies "${s}" is not a species`)
  }

  if (problems.length > 0) throw new ContentError(problems)

  return {
    types: data.types,
    typeById,
    skills: data.skills,
    skillById,
    rarities: data.rarities,
    gearRarities: data.gearRarities,
    resources: data.resources,
    resourceById,
    abilities: data.abilities,
    abilityById,
    traits,
    traitById,
    species: data.species,
    hybrids: data.hybrids,
    creatureById,
    defaultHybridByPair,
    recipes: data.recipes,
    modifiers: data.modifiers,
    modifierByKey,
    tuning: data.tuning,
    zones: data.zones,
    vessels: data.vessels,
    collectionTracks: data.collectionTracks,
  }
}

/** The validated game content. Importing this module fails loudly if any file is malformed. */
export const content: Content = loadContent(rawContent)
