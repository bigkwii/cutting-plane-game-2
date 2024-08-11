extends Node
## Default global variables.
## [br][br]
## (Default values chosen to match demo)
## [br][br]
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## !!! CONSIDER CHANGING THE NAME OF THIS AUTOLOAD !!!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

## Default lattice grid dimensions
@export var DEFAULT_DIMENSIONS: Vector2 = Vector2(8, 6)
## Default lattice grid scaling
@export var DEFAULT_SCALING: int = 142
## Default lattice grid offset
@export var DEFAULT_OFFSET: Vector2 = Vector2(16, 28)
## Default polygon grid color
@export var DEFAULT_COLOR: Color = Color(0.8, 0.8, 0.8)
## levels directory
var LEVELS_DIR = "res://levels/"
## default level file
var DEFAULT_LEVEL = "default"
## epsilon for snapping to grid !!! TODO: autoload? !!!
var CLICK_EPSILON = 0.01
## epsilon for geometric calculations
var GEOMETRY_EPSILON = 0.00001
var GEOMETRY_EPSILON_SQ = GEOMETRY_EPSILON * GEOMETRY_EPSILON