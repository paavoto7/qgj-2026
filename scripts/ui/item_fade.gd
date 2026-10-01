class_name ItemFade


## Static utility class for fading and pulsing items in and out.
static func pulse_item(caller: Node, item: CanvasItem) -> void:
	item.pivot_offset = item.size * 0.5
	item.scale = Vector2(0.75, 0.75)
	item.modulate.a = 0.0

	var tween := caller.create_tween()
	tween.set_parallel(true)

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(item, "scale", Vector2.ONE, 0.28)
	tween.tween_property(item, "modulate:a", 1.0, 0.20)


## Fades an item out and shrinks it slightly. Used for powerups that expire.
static func fade_item_out(caller: Node, item: CanvasItem) -> void:
	var tween := caller.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(item, "modulate:a", 0.0, 0.25)
	tween.tween_property(item, "scale", Vector2(0.92, 0.92), 0.25)
