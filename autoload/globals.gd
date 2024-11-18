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
## epsilon for determining when a MOUSE_1 drag was small enough to be considered a stationary click
var MOUSE_1_DRAG_EPSILON = 10
## epsilon for determining when a touch control drag was small enough to be considered a stationary click
var TOUCH_DRAG_EPSILON = 10
## epsilon for geometric calculations
var GEOMETRY_EPSILON = 0.00001
## epsilon for geometric calculations involving area
var GEOMETRY_EPSILON_AREA = GEOMETRY_EPSILON
## epsilon for cross product checking
var CROSS_PRODUCT_EPSILON = GEOMETRY_EPSILON * 5000 # the very existence of this variable is a testament to the fragility of floating point arithmetic and the human spirit
# in other words, this epsilon is used EXCLUSIVELY in polygon.is_point_on_segment. terrible.
## epsilon for snapping newly discovered intersection points
var INTERSECTION_SNAP_EPSILON = GEOMETRY_EPSILON * 10
## gomory cut vertex click range
var GOMORY_CUT_CLICK_RANGE = 0.15
## epsilon for correcting a new point that got "close enough" to being integral
var FORGIVENESS_SNAP_EPSILON = GEOMETRY_EPSILON * 10000
## epsilon for correcting a point that "close enough" to being colinear with it's 2 neighbors
var FORGIVENESS_COLINEAR_EPSILON = GEOMETRY_EPSILON * 1000
## epsilon for the radius under which a number of points are considered to be the same point
var FORGIVENESS_MERGE_EPSILON = GEOMETRY_EPSILON * 100
