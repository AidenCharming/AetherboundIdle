class_name ItemTip
extends HBoxContainer
## An icon-and-number row for an item whose tooltip is a small card: the item's picture, name and tier, how many
## you have, what it's for (or that it only sells), instead of the plain name.

var item := ""


func _make_custom_tooltip(_for_text: String) -> Object:
	return UI.item_tooltip(item)
