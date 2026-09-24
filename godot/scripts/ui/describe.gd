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
