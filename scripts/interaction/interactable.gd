class_name Interactable
extends Node
## Makes the parent Area2D or Area3D interactable by an Interactor.
##
## Either connect the interacted signal in the editor, or extend this script and override interact().

signal interacted(interactor: Node)

@export var prompt_text: String = "Interact"
## Disabled interactables are ignored by interactors.
@export var enabled: bool = true
## Disable after the first interaction, e.g. for pickups.
@export var one_shot: bool = false
## Interact as soon as an Interactor overlaps it, without the interact action, e.g. for pickups.
@export var interact_on_touch: bool = false

var area: Node:
	get:
		return get_parent()


## Called by the Interactor. Override to react, and call super() to keep the signal and one_shot working.
func interact(interactor: Node) -> void:
	interacted.emit(interactor)
	if one_shot:
		enabled = false


## Returns the Interactable child of an area, or null.
static func find_in(node: Node) -> Interactable:
	for child: Node in node.get_children():
		if child is Interactable:
			return child

	return null
