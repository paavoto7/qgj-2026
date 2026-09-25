class_name StateMachine
extends RefCounted
## Code-driven state machine. States are StateBase objects keyed by their class_name.
##
## Usage from the owner:
##     state_machine.add_state(IdleState.new(self))
##     state_machine.add_state(AttackState.new(self))
##     state_machine.initialize(&"IdleState")
##     # in _physics_process: state_machine.update(delta)
##     # anywhere: state_machine.change_state(&"AttackState")

signal state_changed(previous: StateBase, current: StateBase)

var current_state: StateBase = null
var previous_state: StateBase = null

var _states: Dictionary[StringName, StateBase] = {}


## Registers a state under its class_name. States without a class_name can't be looked up by name.
func add_state(state: StateBase) -> void:
	_states[_get_state_name(state)] = state


func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)


func get_state(state_name: StringName) -> StateBase:
	return _states.get(state_name, null)


## Enters the first state without calling on_exit on anything.
func initialize(state_name: StringName) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: unknown state '%s'" % state_name)
		return

	current_state = _states[state_name]
	current_state.on_enter()


## Registers the state if needed and enters it.
func initialize_with_state(state: StateBase) -> void:
	add_state(state)
	initialize(_get_state_name(state))


func update(delta: float) -> void:
	if current_state:
		current_state.on_update(delta)


func change_state(state_name: StringName) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: unknown state '%s'" % state_name)
		return

	change_state_to_state(_states[state_name])


## Switches to the given state instance, even if it hasn't been added.
func change_state_to_state(next_state: StateBase) -> void:
	previous_state = current_state
	current_state = next_state
	if previous_state:
		previous_state.on_exit(current_state)

	current_state.on_enter()
	state_changed.emit(previous_state, current_state)


## Returns true if the active state is the one registered under state_name.
func is_in_state(state_name: StringName) -> bool:
	return current_state != null and current_state == _states.get(state_name)


func _get_state_name(state: StateBase) -> StringName:
	return state.get_script().get_global_name()
