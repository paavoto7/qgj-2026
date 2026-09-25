class_name Interactor
extends Node
## Finds Interactables that overlap the parent Area2D or Area3D and interacts with the closest one on the interact input action.
##
## Connect focus_changed to the HUD to show or hide an interaction prompt.

signal focus_changed(interactable: Interactable)

@export var interact_action: StringName = &"interact"
## Node passed to Interactable.interact(), usually the player. Defaults to the area's parent.
@export var owner_node: Node

var focused: Interactable = null

var _in_range: Array[Interactable] = []

@onready var _area: Node = get_parent()


func _ready() -> void:
	if not (_area is Area2D or _area is Area3D):
		push_warning("Interactor: parent must be an Area2D or Area3D")
		set_physics_process(false)
		return

	if owner_node == null:
		owner_node = _area.get_parent()

	_area.area_entered.connect(_on_area_entered)
	_area.area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	# Re-evaluated every physics frame because the closest target changes as things move
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(interact_action) or focused == null:
		return

	get_viewport().set_input_as_handled()
	focused.interact(owner_node)
	_update_focus()


func _on_area_entered(area: Node) -> void:
	var interactable: Interactable = Interactable.find_in(area)
	if interactable != null and interactable not in _in_range:
		_in_range.append(interactable)


func _on_area_exited(area: Node) -> void:
	var interactable: Interactable = Interactable.find_in(area)
	if interactable != null:
		_in_range.erase(interactable)


func _update_focus() -> void:
	var closest: Interactable = _get_closest()
	if closest == focused:
		return

	focused = closest
	focus_changed.emit(focused)


func _get_closest() -> Interactable:
	var closest: Interactable = null
	var closest_distance: float = INF
	for interactable: Interactable in _in_range.duplicate():
		if not is_instance_valid(interactable):
			_in_range.erase(interactable)
			continue
		if not interactable.enabled:
			continue

		var distance: float = _area.global_position.distance_squared_to(interactable.area.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = interactable

	return closest
