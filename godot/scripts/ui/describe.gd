class_name Describe
extends RefCounted
## Player-facing text for game rules.


static func ability(ab: Dictionary) -> String:
	var dmg: String = Data.types[ab.damageType].name if ab.damageType != null and Data.types.has(ab.damageType) else ""
	match ab.effect:
		"single-target-damage":
			return "Hits one enemy with %s damage." % dmg
		"multi-target-damage":
			return "Hits every enemy with %s damage." % dmg
		"heal-instant":
			return "Heals the whole party at once."
		"heal-over-time":
			return "Heals the whole party over a few seconds."
		"buff-power":
			return "Raises the party's Power for a while."
		"buff-guard":
			return "Raises the party's Guard for a while."
		"shield-party":
			return "Shields every party member."
		"shield-self":
			return "Puts a strong shield on itself."
		"thorns":
			return "Shields itself and reflects part of the damage it takes."
	return ""


## One short line per work perk from Skills.work_perks(), e.g. "+50% rare finds". Kept short:
## the picker cards show one line each.
static func work_perk(perk: Dictionary) -> String:
	var pct := F.pct(perk.value)
	match perk.key:
		"extra_output_chance":
			return "%s double output" % pct
		"offline_extra_output_chance":
			return "+%s double output away" % pct
		"save_material_chance":
			return "%s save materials" % pct
		"rare_drop_chance":
			return "+%s rare finds" % pct
		"treasure_drop_chance":
			return "+%s treasure finds" % pct
		"bonus_xp":
			return "+%s XP" % pct
		"partner_element_drop_chance":
			return "%s extra %s" % [pct, Data.item_name(perk.item)]
	return ""
