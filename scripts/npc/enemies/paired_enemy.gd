class_name PairedEnemy
extends Enemy
## Enemy linked to a partner. One loop around both, in either direction, knots them together.

## How far apart linked partners try to stay.
const PAIR_DISTANCE: float = 110.0

@export var enemy_color: Color = Color(0.6, 1.0, 0.5)

var partner: PairedEnemy


## Links two enemies as partners of each other.
static func link(first: PairedEnemy, second: PairedEnemy) -> void:
	first.partner = second
	second.partner = first


func has_partner() -> bool:
	return is_instance_valid(partner)


func _wound_amount(windings: Dictionary[Enemy, float]) -> float:
	var winding: float = windings.get(self, 0.0)
	if not has_partner():
		return winding

	# Both must be wound the same way, so a loop around the pair counts but a figure eight doesn't
	var partner_winding: float = windings.get(partner, 0.0)
	if signf(winding) != signf(partner_winding):
		return 0.0
	return minf(absf(winding), absf(partner_winding))


func _get_color() -> Color:
	return enemy_color


func _get_velocity() -> Vector2:
	var velocity: Vector2 = super()
	if has_partner():
		# Spring towards the partner so the pair stays loopable as one
		var offset: Vector2 = partner.position - position
		velocity += offset.normalized() * (offset.length() - PAIR_DISTANCE) * 2.0
	return velocity
