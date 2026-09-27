class_name WaveWeight
extends Resource
## How likely something is on a given wave, compared to the other options it's picked from.
## Used for random enemies, drops and movement patterns. An empty weight slot counts as 1.

## Weight on From Wave.
@export var weight: float = 1.0
## Added every wave after From Wave. Negative makes it rarer over time.
@export var per_wave: float = 0.0
## The weight is 0 before this wave.
@export var from_wave: int = 1
## The weight is 0 after this wave. 0 means no end.
@export var until_wave: int = 0
## Highest weight it can grow to. 0 means no cap.
@export var max_weight: float = 0.0
## Optional. Replaces Weight and Per Wave: x is the wave number, y the weight.
## Set the curve's Min and Max Domain to the waves it covers, e.g. 1 to 20. Later waves use the last value.
@export var curve: Curve = null


func get_weight(wave: int) -> float:
	if wave < from_wave or (until_wave > 0 and wave > until_wave):
		return 0.0

	var value: float
	if curve:
		value = curve.sample_baked(wave)
	else:
		value = weight + per_wave * (wave - from_wave)

	if max_weight > 0.0:
		value = minf(value, max_weight)
	return maxf(value, 0.0)
