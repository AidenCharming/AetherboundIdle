import { describe, expect, it } from 'vitest'
import contentDoc from '../docs/content-data.md?raw'
import { content, ContentError, EFFECT_KEYS, loadContent, pairKey, rawContent, STRENGTHS, type ContentKey } from '../src/data'

// ---------- content-data.md parsing (names must match the doc verbatim) ----------

const docLines = contentDoc.replace(/\r\n/g, '\n').split('\n')

function docSection(headingPrefix: string): string[] {
  const start = docLines.findIndex((l) => l.startsWith(headingPrefix))
  if (start < 0) throw new Error(`content-data.md has no heading "${headingPrefix}"`)
  let end = docLines.length
  for (let i = start + 1; i < docLines.length; i++) {
    if (docLines[i]!.startsWith('#')) {
      end = i
      break
    }
  }
  return docLines.slice(start + 1, end)
}

const docRows = (headingPrefix: string): string[][] =>
  docSection(headingPrefix)
    .filter((l) => l.startsWith('|'))
    .slice(2) // header and separator
    .map((l) => l.split('|').slice(1, -1).map((c) => c.trim()))

const baseRows = docRows('## Base species')
const hybridRows = docRows('## Default hybrids')
const poolRows = docRows('## Trait pool')

/** "Overgrowth: chance for extra output [Moderate]" -> name and strength. */
const parseSignature = (cell: string) => {
  const m = cell.match(/^(.+?): (.+) \[(Minor|Moderate|Major)\]$/)!
  return { name: m[1]!, desc: m[2]!, strength: m[3]!.toLowerCase() }
}
/** "Rotor Gust (single-target, Verdant)" -> name and the optional type after the comma. */
const parseAbility = (cell: string) => {
  const m = cell.match(/^(.+?) \((.+)\)$/)!
  return { name: m[1]!, type: m[2]!.split(', ')[1] ?? null }
}
const normalizeText = (s: string) => s.replace(/\s*\(.*\)$/, '').replace(/\.$/, '').toLowerCase()

const name = (id: string, map: ReadonlyMap<string, { name: string }>) => map.get(id)?.name

// ---------- counts ----------

describe('content counts', () => {
  it('loads every file with the expected number of entries', () => {
    expect(content.types).toHaveLength(6)
    expect(content.skills).toHaveLength(11)
    expect(content.rarities).toHaveLength(9)
    expect(content.gearRarities).toHaveLength(9)
    expect(content.species).toHaveLength(24)
    expect(content.hybrids).toHaveLength(15)
    expect(content.abilities).toHaveLength(39)
    expect(content.traits).toHaveLength(24 + 15 + 30)
    expect(content.traits.filter((t) => t.kind === 'signature')).toHaveLength(39)
    expect(content.traits.filter((t) => t.kind === 'pool')).toHaveLength(30)
    expect(content.modifiers).toHaveLength(EFFECT_KEYS.length)
    expect(content.creatureById.size).toBe(39)
  })

  it('ships the phase 3/4 files empty but valid', () => {
    expect(content.zones).toEqual([])
    expect(content.vessels).toEqual([])
    expect(content.collectionTracks).toEqual([])
    expect(content.recipes.special).toEqual([])
  })

  it('has bench emission that doubles per rarity tier (design section 5)', () => {
    expect(content.rarities.map((r) => r.benchEmissionPerMin)).toEqual([1, 2, 4, 8, 16, 32, 64, 128, 256])
  })
})

// ---------- every species and hybrid loads and cross-resolves ----------

describe('every species loads and cross-resolves', () => {
  it.each(content.species)('$name', (s) => {
    const type = content.typeById.get(s.types[0]!)
    expect(type, 'type').toBeDefined()

    const primary = content.skillById.get(s.primarySkill)
    expect(primary, 'primary skill').toBeDefined()
    expect(type!.lockedSkills, 'primary skill belongs to its type').toContain(s.primarySkill)
    expect(content.skillById.get(s.secondaryAptitude)?.open, 'secondary aptitude is an open skill').toBe(true)

    const trait = content.traitById.get(s.signatureTrait)
    expect(trait?.kind, 'signature trait').toBe('signature')
    expect(trait?.kind === 'signature' && trait.species, 'trait points back at the species').toBe(s.id)

    const ability = content.abilityById.get(s.ability)
    expect(ability, 'ability').toBeDefined()
    if (ability!.damageType) expect(ability!.damageType, 'ability uses its own type').toBe(s.types[0])

    expect(s.forms.map((f) => f.form)).toEqual([1, 2, 3])
    expect(s.forms[0]!.name, 'form 1 uses the species name').toBe(s.name)
    expect(s.forms.every((f) => f.art), 'base species forms carry art prompts').toBe(true)
    expect(s.origin).toBe('wild')
  })
})

describe('every hybrid loads and cross-resolves', () => {
  it.each(content.hybrids)('$name', (h) => {
    const [a, b] = h.types as [string, string]
    expect(content.typeById.has(a) && content.typeById.has(b), 'both parent types').toBe(true)
    expect(h.pair, 'pair is the two types, sorted').toEqual([a, b].sort())

    const locked = [a, b].flatMap((t) => content.typeById.get(t)!.lockedSkills)
    expect([...h.coveredSkills].sort(), 'covers exactly both parents\' skills').toEqual([...new Set(locked)].sort())
    expect(h.coveredSkills, 'primary skill is covered').toContain(h.primarySkill)
    expect(content.skillById.get(h.secondaryAptitude)?.open).toBe(true)

    const trait = content.traitById.get(h.signatureTrait)
    expect(trait?.kind, 'signature trait').toBe('signature')
    expect(trait?.kind === 'signature' && trait.species).toBe(h.id)

    const ability = content.abilityById.get(h.ability)
    expect(ability, 'ability').toBeDefined()
    if (ability!.damageType) expect(h.types, 'ability type is a parent type').toContain(ability!.damageType)

    expect(h.forms.map((f) => f.form)).toEqual([1, 2, 3])
    expect(h.forms[0]!.name).toBe(h.name)
    expect(h.origin).toBe('breed')
  })

  it('has exactly one default hybrid for each of the 15 possible type pairs', () => {
    const ids = content.types.map((t) => t.id)
    const pairs = ids.flatMap((a, i) => ids.slice(i + 1).map((b) => pairKey(a, b)))
    expect(pairs).toHaveLength(15)
    expect([...content.defaultHybridByPair.keys()].sort()).toEqual([...pairs].sort())
    expect(content.hybrids.every((h) => h.isDefaultForPair)).toBe(true)
  })

  it('gives every hybrid a partner-element drop, except Gridrift', () => {
    for (const h of content.hybrids) {
      const trait = content.traitById.get(h.signatureTrait)!
      const drop = trait.effects.find((e) => e.key === 'partner_element_drop_chance')
      if (h.id === 'gridrift') {
        expect(trait.effects.map((e) => e.key)).toEqual(['bench_aether_emission'])
        expect(trait.kind === 'signature' && trait.defaultStrength).toBe('major')
        continue
      }
      expect(drop, h.id).toBeDefined()
      expect(h.types, `${h.id}: element is one of its types`).toContain(drop!.elementType)
      const primaryType = content.skillById.get(h.primarySkill)!.requiredType
      expect(drop!.elementType, `${h.id}: element is the partner, not the primary skill's type`).not.toBe(primaryType)
      expect(drop!.scope.skills, `${h.id}: only while working its primary skill`).toEqual([h.primarySkill])
    }
  })
})

// ---------- abilities, traits, resources ----------

describe('abilities', () => {
  it('has one ability per creature, none shared or orphaned', () => {
    const used = [...content.species, ...content.hybrids].map((c) => c.ability)
    expect(new Set(used).size).toBe(39)
    expect([...used].sort()).toEqual(content.abilities.map((a) => a.id).sort())
  })

  it('gives every damage ability a type that exists', () => {
    for (const a of content.abilities) {
      if (a.effect === 'single-target-damage' || a.effect === 'multi-target-damage') expect(a.damageType, a.id).not.toBeNull()
      if (a.damageType) expect(content.typeById.has(a.damageType), a.id).toBe(true)
    }
  })

  it('keeps thorns Verdant-only and models Bucket Block as a heavy 1.5x self shield (plan 3.5)', () => {
    const thorns = content.abilities.filter((a) => a.effect === 'thorns')
    expect(thorns.map((a) => a.id)).toEqual(['thorn-roll'])
    const bucket = content.abilityById.get('bucket-block')!
    expect(bucket).toMatchObject({ effect: 'shield-self', tempo: 'heavy', magnitude: 1.5 })
  })
})

describe('traits', () => {
  it('resolves every effect against the modifier registry, skills and types', () => {
    for (const t of content.traits) {
      for (const e of t.effects) {
        expect(content.modifierByKey.has(e.key), `${t.id}: ${e.key} is in modifiers.json`).toBe(true)
        for (const s of e.scope.skills ?? []) expect(content.skillById.has(s), `${t.id}: skill ${s}`).toBe(true)
        for (const s of e.scope.types ?? []) expect(content.typeById.has(s), `${t.id}: type ${s}`).toBe(true)
        if (e.elementType) expect(content.typeById.has(e.elementType), `${t.id}: element ${e.elementType}`).toBe(true)
      }
    }
  })

  it('fills a value for every strength a trait can roll (loader defaults from tuning.json)', () => {
    for (const t of content.traits) {
      const reachable = t.kind === 'signature' ? [t.defaultStrength] : STRENGTHS.slice(STRENGTHS.indexOf(t.minStrength ?? 'minor'))
      for (const e of t.effects) {
        if (e.dynamic) continue
        for (const s of reachable) expect(typeof e.valueByStrength?.[s], `${t.id} ${e.key} ${s}`).toBe('number')
      }
    }
    const defaults = content.tuning.traitStrength.default
    expect(content.traitById.get('overgrowth')!.effects[0]!.valueByStrength).toEqual(defaults)
  })

  it('marks exactly the two aura signatures as strongest-only auras', () => {
    const auras = content.traits.filter((t) => t.effects.some((e) => e.aura)).map((t) => t.id)
    expect(auras.sort()).toEqual(['resonant-frequency', 'sea-breeze'])
    const rf = content.traitById.get('resonant-frequency')!.effects[0]!
    expect(rf.scope).toEqual({ target: 'other-active-in-skill', skills: ['mining'] })
    const sb = content.traitById.get('sea-breeze')!.effects[0]!
    expect(sb.scope).toEqual({ target: 'active-creatures', types: ['aqueous'] })
  })

  it('models Overclocked as a dynamic stacking reduction and Void Grasp as a count', () => {
    const oc = content.traitById.get('overclocked')!.effects[0]!
    expect(oc.dynamic).toMatchObject({ kind: 'stacking-until-complete' })
    const vg = content.traitById.get('void-grasp')!
    expect(vg.effects[0]!.valueByStrength).toEqual({ moderate: 1, major: 2 })
    expect(content.modifierByKey.get('free_bind_attempts')!.unit).toBe('count')
  })

  it('keeps Void-only traits at Moderate minimum and the chase traits rare', () => {
    const pool = content.traits.filter((t) => t.kind === 'pool')
    for (const t of pool.filter((p) => p.category === 'void-only')) expect(t.minStrength, t.id).toBe('moderate')
    expect(pool.filter((p) => p.category === 'void-only')).toHaveLength(4)
    const commonWeight = pool.find((p) => p.id === 'lucky')!.rollWeight
    for (const id of ['geneticist', 'champion', 'aether-drenched', 'rift-tethered', 'starlight-magnet', 'void-grasp']) {
      const t = pool.find((p) => p.id === id)!
      expect(t.rollWeight, id).toBeLessThan(commonWeight)
    }
  })

  it('keeps Champion a small upgrade over Brawn: rare, and about 60% of Brawn on each of two stats', () => {
    const champion = content.traitById.get('champion')!
    const brawn = content.traitById.get('brawn')!
    expect(champion.effects.map((e) => e.key)).toEqual(['bonus_power', 'bonus_guard'])
    for (const e of champion.effects) expect(e.valueByStrength).toEqual({ minor: 0.03, moderate: 0.06, major: 0.12 })
    const brawnValues = brawn.effects[0]!.valueByStrength!
    for (const s of STRENGTHS) {
      expect(champion.effects[0]!.valueByStrength![s]! / brawnValues[s]!, s).toBeCloseTo(0.6, 10)
    }
  })

  it('keeps Geneticist under the shared mutation cap', () => {
    const cap = content.modifierByKey.get('mutation_odds')!.cap
    expect(cap).toBe(0.03)
    const values = Object.values(content.traitById.get('geneticist')!.effects[0]!.valueByStrength!)
    expect(Math.max(...values)).toBeLessThanOrEqual(cap)
  })
})

describe('resources', () => {
  it('ships Woodcutting T1-T3 gated at skill level 1 / 15 / 30 (plan 3.4)', () => {
    const logs = ['oak-log', 'willow-log', 'yew-log'].map((id) => content.resourceById.get(id)!)
    expect(logs.map((r) => r.tier)).toEqual([1, 2, 3])
    expect(logs.map((r) => r.requiredSkillLevel)).toEqual([1, 15, 30])
    expect(logs.every((r) => r.skill === 'woodcutting' && r.kind === 'raw')).toBe(true)
  })

  it('scales Woodcutting tiers up in time, xp and gold, so levelling into a tier has a point (placeholders)', () => {
    const logs = ['oak-log', 'willow-log', 'yew-log'].map((id) => content.resourceById.get(id)!)
    expect(logs.map((r) => r.baseActionMs)).toEqual([3000, 4000, 5000])
    expect(logs.map((r) => r.xpPerAction)).toEqual([10, 25, 50])
    expect(logs.map((r) => r.goldValue)).toEqual([2, 6, 15])
    // Higher tiers must pay more xp per second than the tier below, or nobody would ever move up.
    const xpPerSec = logs.map((r) => r.xpPerAction! / (r.baseActionMs! / 1000))
    expect(xpPerSec[1]!).toBeGreaterThan(xpPerSec[0]!)
    expect(xpPerSec[2]!).toBeGreaterThan(xpPerSec[1]!)
  })

  it('gives every resource its own emoji, including the seedcache', () => {
    const emojis = content.resources.map((r) => r.emoji)
    expect(emojis.every((e) => typeof e === 'string' && e.length > 0), 'every resource has an emoji').toBe(true)
    expect(new Set(emojis).size, 'no two resources share an emoji').toBe(content.resources.length)
    expect(content.resourceById.get('verdant-seedcache')!.emoji).toBeTruthy()
  })

  it('treats the emoji as optional (the UI falls back to a dot) but rejects a non-emoji', () => {
    const raw = structuredClone(rawContent) as Record<string, any>
    delete raw.resources[0].emoji
    expect(loadContent(raw).resources[0]!.emoji).toBeUndefined()
    expect(problemsFor((r) => (r.resources[0].emoji = '(log)')).join('\n')).toContain('resources.json[0].emoji')
    expect(problemsFor((r) => (r.resources[0].emoji = '')).join('\n')).toContain('resources.json[0].emoji')
  })

  it('gives every skill its own emoji (the sidebar and the skill page show it)', () => {
    const emojis = content.skills.map((s) => s.emoji)
    expect(emojis.every((e) => typeof e === 'string' && e.length > 0), 'every skill has an emoji').toBe(true)
    expect(new Set(emojis).size, 'no two skills share an emoji').toBe(content.skills.length)
  })

  it('treats a skill emoji as optional but rejects a non-emoji', () => {
    const raw = structuredClone(rawContent) as Record<string, any>
    delete raw.skills[0].emoji
    expect(loadContent(raw).skills[0]!.emoji).toBeUndefined()
    expect(problemsFor((r) => (r.skills[0].emoji = '(axe)')).join('\n')).toContain('skills.json[0].emoji')
    expect(problemsFor((r) => (r.skills[0].emoji = '')).join('\n')).toContain('skills.json[0].emoji')
  })

  it('resolves every skill, element type and rare drop', () => {
    for (const r of content.resources) {
      expect(content.skillById.has(r.skill), `${r.id}: skill`).toBe(true)
      expect(content.typeById.has(r.elementType), `${r.id}: elementType`).toBe(true)
      if (r.rareDrop) expect(content.resourceById.get(r.rareDrop.id)?.kind, `${r.id}: rareDrop`).toBe('rare')
    }
  })
})

// ---------- names and text match content-data.md exactly ----------

describe('names match content-data.md verbatim', () => {
  it('skills', () => {
    const line = docLines.find((l) => l.startsWith('Skills: '))!
    const docSkills = line.replace(/^Skills: /, '').replace(/\.$/, '').split(', ')
    expect(content.skills.map((s) => s.name)).toEqual(docSkills)
  })

  it('base species: name, forms, type, skills, lean, ability, tempo, signature trait', () => {
    expect(content.species).toHaveLength(baseRows.length)
    baseRows.forEach((row, i) => {
      const [speciesName, type, form2, form3, primary, sig, lean, ability, tempo, secondary] = row as [
        string, string, string, string, string, string, string, string, string, string,
      ]
      const s = content.species[i]!
      const signature = parseSignature(sig)
      const ab = parseAbility(ability)
      expect(s.name).toBe(speciesName)
      expect(s.forms.map((f) => f.name)).toEqual([speciesName, form2, form3])
      expect(name(s.types[0]!, content.typeById)).toBe(type)
      expect(name(s.primarySkill, content.skillById)).toBe(primary)
      expect(name(s.secondaryAptitude, content.skillById)).toBe(secondary)
      expect(s.statLean).toBe(lean.toLowerCase())
      const trait = content.traitById.get(s.signatureTrait)!
      expect(trait.name).toBe(signature.name)
      expect(trait.kind === 'signature' && trait.defaultStrength).toBe(signature.strength)
      expect(normalizeText(trait.text)).toBe(normalizeText(signature.desc))
      const abilityDef = content.abilityById.get(s.ability)!
      expect(abilityDef.name).toBe(ab.name)
      expect(abilityDef.tempo).toBe(tempo.toLowerCase())
      expect(abilityDef.damageType ? name(abilityDef.damageType, content.typeById) : null).toBe(ab.type)
    })
  })

  it('default hybrids: name, pair, forms, skills, lean, ability, tempo, signature trait', () => {
    expect(content.hybrids).toHaveLength(hybridRows.length)
    hybridRows.forEach((row, i) => {
      const [hybridName, pair, form2, form3, primary, covered, sig, lean, ability, tempo, secondary] = row as [
        string, string, string, string, string, string, string, string, string, string, string,
      ]
      const h = content.hybrids[i]!
      const signature = parseSignature(sig)
      const ab = parseAbility(ability)
      expect(h.name).toBe(hybridName)
      expect(h.forms.map((f) => f.name)).toEqual([hybridName, form2, form3])
      expect(h.types.map((t) => name(t, content.typeById)).join('/')).toBe(pair)
      expect(name(h.primarySkill, content.skillById)).toBe(primary)
      expect(h.coveredSkills.map((s) => name(s, content.skillById)).join(', ')).toBe(covered)
      expect(name(h.secondaryAptitude, content.skillById)).toBe(secondary)
      expect(h.statLean).toBe(lean.toLowerCase())
      const trait = content.traitById.get(h.signatureTrait)!
      expect(trait.name).toBe(signature.name)
      expect(trait.kind === 'signature' && trait.defaultStrength).toBe(signature.strength)
      expect(normalizeText(trait.text)).toBe(normalizeText(signature.desc))
      const abilityDef = content.abilityById.get(h.ability)!
      expect(abilityDef.name).toBe(ab.name)
      expect(abilityDef.tempo).toBe(tempo.toLowerCase())
      expect(abilityDef.damageType ? name(abilityDef.damageType, content.typeById) : null).toBe(ab.type)
    })
  })

  it('pool traits: name, category, effect text', () => {
    const pool = content.traits.filter((t) => t.kind === 'pool')
    expect(pool).toHaveLength(poolRows.length)
    poolRows.forEach(([traitName, category, effect], i) => {
      const t = pool[i]!
      expect(t.name).toBe(traitName)
      expect(t.kind === 'pool' && t.category).toBe(category!.toLowerCase().replace(/ /g, '-'))
      expect(normalizeText(t.text)).toBe(normalizeText(effect!))
    })
  })

  it('base-species art prompts come straight from the form descriptions', () => {
    const bullets = docSection('### Base species form descriptions').filter((l) => l.startsWith('- '))
    for (const s of content.species) {
      const bullet = bullets.find((l) => l.startsWith(`- ${s.name}: `))!
      expect(bullet, s.name).toBeDefined()
      for (const f of s.forms) expect(bullet, `${s.name} form ${f.form}`).toContain(f.art)
    }
    expect(content.species.find((s) => s.id === 'cinderpup')!.artNote).toBe('Stays cute.')
    expect(content.species.find((s) => s.id === 'voltfluff')!.artNote).toBe('Stays cute.')
  })
})

describe('form emoji', () => {
  it('are real emoji characters, never placeholders, and distinct within a creature', () => {
    for (const c of [...content.species, ...content.hybrids]) {
      for (const f of c.forms) {
        expect(f.emoji, `${c.id} form ${f.form}`).toMatch(/^\p{Extended_Pictographic}/u)
        expect(f.emoji, `${c.id} form ${f.form}`).not.toMatch(/[A-Za-z()]/)
      }
      expect(new Set(c.forms.map((f) => f.emoji)).size, c.id).toBe(3)
    }
  })
})

// ---------- the loader fails loudly ----------

type Loose = Record<ContentKey, any> // eslint-disable-line @typescript-eslint/no-explicit-any
const problemsFor = (mutate: (raw: Loose) => void): readonly string[] => {
  const raw = structuredClone(rawContent) as Loose
  mutate(raw)
  try {
    loadContent(raw)
  } catch (e) {
    if (e instanceof ContentError) return e.problems
    throw e
  }
  throw new Error('expected loadContent to throw a ContentError')
}

describe('loadContent rejects bad data instead of loading it', () => {
  it('accepts the shipped data unchanged', () => {
    expect(() => loadContent(structuredClone(rawContent))).not.toThrow()
  })

  it('reports an ability ID that does not resolve', () => {
    const p = problemsFor((r) => (r.species[0].ability = 'no-such-ability'))
    expect(p.join('\n')).toContain('no-such-ability')
  })

  it('rejects a placeholder in an emoji field', () => {
    const p = problemsFor((r) => (r.species[0].forms[0].emoji = '(seedling)'))
    expect(p.join('\n')).toMatch(/emoji/)
  })

  it('rejects an effect key outside the allowed vocabulary', () => {
    const p = problemsFor((r) => (r.traits[0].effects[0].key = 'summon_dragon'))
    expect(p.join('\n')).toContain('traits.json')
  })

  it('rejects a duplicate ID', () => {
    const p = problemsFor((r) => r.species.push(structuredClone(r.species[0])))
    expect(p.join('\n')).toMatch(/duplicate id "sproutlet"/)
  })

  it('rejects an unsorted hybrid pair and a wrong covered-skills list', () => {
    const p = problemsFor((r) => {
      r.hybrids[0].pair = ['verdant', 'pyric']
      r.hybrids[0].coveredSkills = ['woodcutting', 'herbalism']
    })
    expect(p.join('\n')).toMatch(/pair must be the two types sorted/)
    expect(p.join('\n')).toMatch(/coveredSkills must be exactly/)
  })

  it('rejects a rare drop that points at a missing resource', () => {
    const p = problemsFor((r) => (r.resources[0].rareDrop.id = 'missing-drop'))
    expect(p.join('\n')).toContain('missing-drop')
  })

  it('rejects a signature trait whose owner points elsewhere', () => {
    const p = problemsFor((r) => (r.species[1].signatureTrait = r.species[0].signatureTrait))
    expect(p.join('\n')).toMatch(/signatureTrait/)
  })

  it('requires a modifier-registry entry for every effect key', () => {
    const p = problemsFor((r) => (r.modifiers = r.modifiers.filter((m: { key: string }) => m.key !== 'bind_rate')))
    expect(p.join('\n')).toContain('bind_rate')
  })

  it('requires tuning.creature.maxPoolTraits (the dev panel picker slot count) to be a positive whole number', () => {
    expect(content.tuning.creature.maxPoolTraits).toBe(3) // design.md section 3: up to 3 pool traits
    expect(problemsFor((r) => delete r.tuning.creature.maxPoolTraits).join('\n')).toContain('tuning.json.creature.maxPoolTraits')
    for (const bad of [0, -1, 2.5]) expect(problemsFor((r) => (r.tuning.creature.maxPoolTraits = bad)).join('\n'), String(bad)).toContain('tuning.json.creature.maxPoolTraits')
  })

  it('requires tuning.ui.tickMs to be a positive whole number', () => {
    expect(Number.isInteger(content.tuning.ui.tickMs) && content.tuning.ui.tickMs > 0).toBe(true)
    expect(problemsFor((r) => delete r.tuning.ui).join('\n')).toContain('tuning.json.ui')
    expect(problemsFor((r) => (r.tuning.ui.tickMs = 0)).join('\n')).toContain('tuning.json.ui.tickMs')
    expect(problemsFor((r) => (r.tuning.ui.tickMs = 12.5)).join('\n')).toContain('tuning.json.ui.tickMs')
  })

  it('requires tuning.ui.shinyHueDeg to sit strictly between 0 and 360, so a shiny always looks different', () => {
    const deg = content.tuning.ui.shinyHueDeg
    expect(deg > 0 && deg < 360).toBe(true)
    expect(problemsFor((r) => delete r.tuning.ui.shinyHueDeg).join('\n')).toContain('tuning.json.ui.shinyHueDeg')
    for (const bad of [0, 360, -30, 400]) expect(problemsFor((r) => (r.tuning.ui.shinyHueDeg = bad)).join('\n'), String(bad)).toContain('tuning.json.ui.shinyHueDeg')
  })

  it('requires the notification numbers (activityPanelMax, maxNotifications, maxToasts, toastMs) to be positive whole numbers', () => {
    for (const key of ['activityPanelMax', 'maxNotifications', 'maxToasts', 'toastMs'] as const) {
      const value = content.tuning.ui[key]
      expect(Number.isInteger(value) && value > 0, key).toBe(true)
      expect(problemsFor((r) => delete r.tuning.ui[key]).join('\n'), `${key} missing`).toContain(`tuning.json.ui.${key}`)
      for (const bad of [0, -1, 2.5]) expect(problemsFor((r) => (r.tuning.ui[key] = bad)).join('\n'), `${key} = ${bad}`).toContain(`tuning.json.ui.${key}`)
    }
  })

  it('requires tuning.ui.pacingMilestones to be ascending, distinct, whole levels no higher than a skill max level', () => {
    const levels = content.tuning.ui.pacingMilestones
    expect(levels.length).toBeGreaterThan(0)
    expect(levels, 'level 2 is what makes the first level-up (about 75 s) a row of the Settings table, which never lists level 1').toContain(2)
    expect(levels).toEqual([...levels].sort((a, b) => a - b))
    expect(new Set(levels).size).toBe(levels.length)
    for (const skill of content.skills) for (const level of levels) expect(level, `${skill.id} has no level ${level}`).toBeLessThanOrEqual(skill.maxLevel)
    expect(problemsFor((r) => delete r.tuning.ui.pacingMilestones).join('; ')).toContain('tuning.json.ui.pacingMilestones')
    expect(problemsFor((r) => (r.tuning.ui.pacingMilestones = [])).join('; ')).toContain('tuning.json.ui.pacingMilestones')
    for (const bad of [[0], [-5], [2.5], ['ten']]) expect(problemsFor((r) => (r.tuning.ui.pacingMilestones = bad)).join('; '), JSON.stringify(bad)).toContain('tuning.json.ui.pacingMilestones')
  })

  it('requires tuning.offline.awayThresholdMs to be a positive whole number below the cap', () => {
    const { awayThresholdMs, capHours } = content.tuning.offline
    expect(Number.isInteger(awayThresholdMs) && awayThresholdMs > 0).toBe(true)
    expect(awayThresholdMs).toBeLessThan(capHours * 3_600_000)
    expect(problemsFor((r) => delete r.tuning.offline.awayThresholdMs).join('\n')).toContain('tuning.json.offline.awayThresholdMs')
    for (const bad of [0, -1, 1500.5]) expect(problemsFor((r) => (r.tuning.offline.awayThresholdMs = bad)).join('\n'), String(bad)).toContain('tuning.json.offline.awayThresholdMs')
    expect(problemsFor((r) => (r.tuning.offline.awayThresholdMs = r.tuning.offline.capHours * 3_600_000)).join('\n')).toContain('awayThresholdMs must be below')
  })

  it('lists every problem at once, not just the first', () => {
    const p = problemsFor((r) => {
      r.species[0].ability = 'nope-a'
      r.species[1].ability = 'nope-b'
    })
    expect(p.join('\n')).toContain('nope-a')
    expect(p.join('\n')).toContain('nope-b')
  })
})
