class_name StateBase
extends RefCounted
## Base class for states run by a StateMachine. Extend it with a class_name and override the callbacks.


## Called when the state machine enters this state.
func on_enter() -> void:
	pass


## Called when leaving this state, before the next state's on_enter.
func on_exit(_next_state: StateBase) -> void:
	pass


## Called every time the state machine is updated while this state is active.
func on_update(_delta: float) -> void:
	pass
