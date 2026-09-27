class_name WeightedRandom
extends RefCounted
## Helpers for picking one option out of several by weight, e.g. with WaveWeight.

static var _rng := RandomNumberGenerator.new()


## Returns a random index, each with a chance proportional to its weight. -1 if every weight is 0.
static func pick_index(weights: PackedFloat32Array) -> int:
	var anyOverZero: bool = false
	for value: float in weights:
		if value > 0.0:
			anyOverZero = true
			break
	if not anyOverZero:
		return -1

	return _rng.rand_weighted(weights)


## The weight of wave_weight on the given wave, or default when it's not set.
static func weight_of(wave_weight: WaveWeight, wave: int, default: float = 1.0) -> float:
	return wave_weight.get_weight(wave) if wave_weight else default
