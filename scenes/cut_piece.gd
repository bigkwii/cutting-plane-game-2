extends RigidBody2D
## A small polygon with collision. A simple vfx for cutting.

## note: lattice coords. convert to game coords with SCALING and OFFSET
@export var packed_vertices: PackedVector2Array = PackedVector2Array()
@export var color: Color = Color(1, 1, 1)
@export var alpha: float = 1
@export var SCALING: Vector2 = GLOBALS.DEFAULT_SCALING
@export var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ANIM_PLAYER: AnimationPlayer = $AnimationPlayer

@export var initial_velocity_dir: Vector2 = Vector2(0, 0)
var speed: float = 1000
var air_res: float = 10
var radian_randomness: float = 0.0

func _ready():
	collision_shape.shape = ConvexPolygonShape2D.new()
	# apply SCALING and OFFSET
	for i in range(packed_vertices.size()):
		packed_vertices[i] = packed_vertices[i] * SCALING + OFFSET
	collision_shape.shape.set_points(packed_vertices)
	# add some randomness to the initial velocity
	initial_velocity_dir = initial_velocity_dir.rotated(RANDOM.RNG.randf_range(-radian_randomness, radian_randomness))
	linear_velocity = initial_velocity_dir * speed
	# schedule for self destruction
	ANIM_PLAYER.play("fade")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	queue_redraw()
	# apply air resistance
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, air_res * delta)

func _draw():
	if packed_vertices.size() < 3:
		DEBUG.log("polygon._draw: Polygon must have at least 3 vertices! %s given." % packed_vertices.size())
		return
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for vert in packed_vertices:
		points.append( vert ) # should be actual position by now
		colors.append( Color(color, 0.2 * alpha) ) # semi-transparent fill
	draw_polygon(points, colors)
	points.append(points[0]) # complete round trip
	draw_polyline(points, Color(color, 1), 2 * alpha) # solid border

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade":
		queue_free()
