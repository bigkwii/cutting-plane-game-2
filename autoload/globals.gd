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
## epsilon for snapping to grid when clicking
var CLICK_EPSILON = 0.01
## epsilons for geometric calculations
var GEOMETRY_EPSILON = 0.00001
var GEOMETRY_EPSILON_SQ = GEOMETRY_EPSILON * GEOMETRY_EPSILON
## gomory cut vertex click range
var GOMORY_CUT_CLICK_RANGE = 0.1
## epsilon for correcting a new point that got "close enough" to being integral
var FORGIVENESS_SNAP_EPSILON = GEOMETRY_EPSILON * 10000
var FORGIVENESS_COLINEAR_EPSILON = GEOMETRY_EPSILON * 1000
var FORGIVENESS_MERGE_EPSILON = GEOMETRY_EPSILON * 100