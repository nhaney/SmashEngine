extends KinematicBody2D

const MOVE_SPEED = 500
const AIR_SPEED_MULTIPLIER = 0.85
const JUMP_FORCE = 600
const GRAVITY = 1400

onready var anim_player = $AnimationPlayer
onready var sprite = $Sprite

export var snap := false
export var slide_slope_threshold := 50.0
export var velocity := Vector2()

var facing_right = false
var has_double_jumped = false

func _physics_process(delta):
 
    var move_dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    
    var ground_speed = MOVE_SPEED * AIR_SPEED_MULTIPLIER if !is_on_floor() else MOVE_SPEED
    velocity.x = move_dir * ground_speed
    
    if Input.is_action_just_pressed("jump"):
        if snap:
            velocity.y = -JUMP_FORCE
            snap = false
        elif not has_double_jumped:
            velocity.y = -JUMP_FORCE
            has_double_jumped = true

    
    velocity.y += GRAVITY * delta
    
    var snap_vector = Vector2(0, 32) if snap else Vector2()
    
    velocity = move_and_slide_with_snap(velocity, snap_vector, Vector2.UP, slide_slope_threshold)
    
    if is_on_floor() and (Input.is_action_just_released("move_right") or Input.is_action_just_released("move_left")):
        velocity.y = 0
    
    var just_landed := is_on_floor() and not snap
    if just_landed:
        snap = true
        has_double_jumped = false
    
    if facing_right and move_dir > 0:
        flip()
    if !facing_right and move_dir < 0:
        flip()
    
    if is_on_floor():
        if move_dir == 0:
            play_anim("idle")
        else:
            play_anim("walk")
    else:
        play_anim("jump")

func flip():
    facing_right = !facing_right
    sprite.flip_h = !sprite.flip_h
    
func play_anim(anim_name):
    if anim_player.is_playing() and anim_player.current_animation == anim_name:
        return
    anim_player.play(anim_name)

