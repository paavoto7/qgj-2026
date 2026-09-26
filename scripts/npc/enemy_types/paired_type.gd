class_name PairedType
extends EnemyType
## The enemy is linked to a partner. One loop around both, in either direction, knots them together.

## How far apart linked partners try to stay.
const PAIR_DISTANCE: float = 110.0

@export var color: Color = Color(0.6, 1.0, 0.5)

var partner: PairedType


## Links two paired enemies as partners of each other.
static func link(first: PairedType, second: PairedType) -> void:
	first.partner = second
	second.partner = first


func has_partner() -> bool:
	return is_instance_valid(partner)


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	var winding: float = windings.get(enemy, 0.0)
	if not has_partner():
		return winding

	# Both must be wound the same way, so a loop around the pair counts but a figure eight doesn't
	var partner_winding: float = windings.get(partner.enemy, 0.0)
	if signf(winding) != signf(partner_winding):
		return 0.0
	return minf(absf(winding), absf(partner_winding))


func get_color() -> Color:
	return color


func steer(velocity: Vector2) -> Vector2:
	if not has_partner():
		return velocity

	# Spring towards the partner so the pair stays loopable as one
	var offset: Vector2 = partner.enemy.position - enemy.position
	return velocity + offset.normalized() * (offset.length() - PAIR_DISTANCE) * 2.0
