class_name Zone
extends Resource
## One place the band can play. Names, prices and art are edited in the inspector, one
## .tres per zone in world/zones/. A zone without a background is not built yet and
## shows on the map as "???", with only its blurb as a teaser.

@export var id: StringName
## Small caption above the name in the HUD's place panel.
@export var eyebrow: String = ""
@export var title: String = ""
## One line with a bit of humour for the map card.
@export_multiline var blurb: String = ""
## 0 for zones owned from the start.
@export var price: int = 0
@export var background: Texture2D
## Map card picture; the background is used when this is empty.
@export var thumbnail: Texture2D
## Icon for the HUD's place panel; empty shows the procedural house.
@export var place_icon: Texture2D
@export var protagonist_position: Vector2 = Vector2(760, 1000)
@export var bassist_position: Vector2 = Vector2(1320, 1000)
## Ground under the drum stool; the kit is drawn behind the two guitarists.
@export var drummer_position: Vector2 = Vector2(1040, 895)
## Who can turn up and ask to join while the band plays here; empty for nobody.
@export var recruit: Bandmate
## A shop item and the level it must reach before this zone can be bought; empty id for
## no requirement.
@export var requires_item: StringName
@export var requires_level: int = 0


func is_built() -> bool:
	return background != null
