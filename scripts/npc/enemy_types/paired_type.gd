@tool
class_name PairedType
extends EnemyType
## The enemy is linked to a partner. Loop around both in the chosen direction.

## How far apart linked partners try to stay.
const PAIR_DISTANCE: float = 110.0

var partner: PairedType


## Links two paired enemies as partners of each other.
static func link(first: PairedType, second: PairedType) -> void:
	first.partner = second
	second.partner = first


func has_partner() -> bool:
	return is_instance_valid(partner)


## The middle of the pair. Both partners measure from it, so they fill and knot together,
## and a figure eight nets zero.
func winding_center() -> Vector2:
	if not has_partner():
		return super.winding_center()
	return (enemy.global_position + partner.enemy.global_position) / 2.0


## Half the distance between the partners, so a loop through the gap between them doesn't count.
func min_wind_distance() -> float:
	if not has_partner():
		return super.min_wind_distance()
	return enemy.global_position.distance_to(partner.enemy.global_position) / 2.0


## Links with the other paired enemy spawned from the same scene. The partner takes over this enemy's direction.
func on_spawned(group: Array[Enemy]) -> void:
	for other: Enemy in group:
		var other_type := other.type as PairedType
		if other_type and other_type != self and not other_type.has_partner():
			link(self, other_type)
			other_type.wind_direction = wind_direction
			other_type._random_direction = _random_direction
			return


func draw_extras() -> void:
	# Nothing links partners in the editor, so link to a sibling to preview the pair
	if Engine.is_editor_hint() and not has_partner():
		on_spawned(_sibling_enemies())

	# Draw each pair link once
	if has_partner() and get_instance_id() < partner.get_instance_id():
		# From edge to edge, so the line doesn't cover either body
		var to_partner: Vector2 = partner.enemy.position - enemy.position
		var heading: Vector2 = to_partner.normalized()
		var start: Vector2 = heading * enemy.radius
		var end: Vector2 = to_partner - heading * partner.enemy.radius
		enemy.draw_dashed_line(start, end, Color(color, 0.5), 2.0, 8.0)


func steer(velocity: Vector2) -> Vector2:
	if not has_partner():
		return velocity

	# Spring towards the partner so the pair stays loopable as one
	var offset: Vector2 = partner.enemy.position - enemy.position
	return velocity + offset.normalized() * (offset.length() - PAIR_DISTANCE) * 2.0


func _sibling_enemies() -> Array[Enemy]:
	var siblings: Array[Enemy] = []
	var parent: Node = enemy.get_parent()
	if parent:
		for child: Node in parent.get_children():
			if child is Enemy:
				siblings.append(child)
	return siblings
