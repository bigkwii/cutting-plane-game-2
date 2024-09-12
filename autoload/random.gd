extends Node

var RNG = RandomNumberGenerator.new()
var _seed_str = "cool seed"

func _ready():
	RNG.seed = hash(_seed_str)
