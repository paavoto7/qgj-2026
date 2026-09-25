class_name DamageZone
extends Node
## Damages bodies with a Health component that enter the parent Area2D or Area3D, e.g. spikes, lava or kill planes.

@export var damage: int = 25
@export var kills_immediately: bool = false
## Damage again every this many seconds while the body stays inside. 0 damages only on enter.
@export var repeat_interval: float = 0.0
## Only damage bodies in this group. Empty damages everything with a Health.
@export var target_group: StringName = &""

var _bodies_inside: Array[Node] = []
var _repeat_timer: Timer


func _ready() -> void:
	var area: Node = get_parent()
	if not (area is Area2D or area is Area3D):
		push_warning("DamageZone: parent must be an Area2D or Area3D")
		return

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	if repeat_interval > 0.0:
		_repeat_timer = Timer.new()
		_repeat_timer.wait_time = repeat_interval
		_repeat_timer.timeout.connect(_on_repeat_timeout)
		add_child(_repeat_timer)


func _on_body_entered(body: Node) -> void:
	if not target_group.is_empty() and not body.is_in_group(target_group):
		return

	_damage(body)
	if _repeat_timer:
		_bodies_inside.append(body)
		if _repeat_timer.is_stopped():
			_repeat_timer.start()


func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)
	if _repeat_timer and _bodies_inside.is_empty():
		_repeat_timer.stop()


func _on_repeat_timeout() -> void:
	for body: Node in _bodies_inside.duplicate():
		if is_instance_valid(body):
			_damage(body)
		else:
			_bodies_inside.erase(body)


func _damage(body: Node) -> void:
	var health: Health = Health.find_in(body)
	if health == null:
		return

	if kills_immediately:
		health.kill()
	else:
		health.take_damage(damage)
