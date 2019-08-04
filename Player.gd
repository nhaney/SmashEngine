extends KinematicBody2D

const MOVE_SPEED = 500
const AIR_SPEED_MULTIPLIER = 0.75
const JUMP_FORCE = 500
const WALL_JUMP_FORCE = 300
const GRAVITY = 1400
const MAX_FALL_SPEED = 700
const KILL_PLANE = 700

onready var anim_player = $AnimationPlayer
onready var sprite = $Sprite
onready var start_pos = get_global_position()

export var snap := false
export var slide_slope_threshold := 50.0
export var velocity := Vector2()

var facing_right = false
var has_double_jumped = false
var was_on_wall_counter = 0
var wall_normal = 0

var is_fastfalling = false


func _physics_process(delta):
 
    var move_dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var should_apply_gravity = true
    
    var ground_speed = MOVE_SPEED * AIR_SPEED_MULTIPLIER if !is_on_floor() else MOVE_SPEED
    velocity.x = move_dir * ground_speed
    
    if Input.is_action_just_pressed("crouch"):
        if !snap and velocity.y > 0:
            is_fastfalling = true
    
    if Input.is_action_just_pressed("jump"):
        if snap:
            velocity.y = -JUMP_FORCE
            snap = false
        elif not has_double_jumped:
            velocity.y = -JUMP_FORCE
            has_double_jumped = true
            # double jump cancels fastfall
            is_fastfalling = false
        
    if was_on_wall_counter < 5:
        if wall_normal != 0:
            if int(move_dir) == wall_normal:
                do_wall_jump(wall_normal)
                if velocity.y < -JUMP_FORCE:
                    velocity.y = -JUMP_FORCE
                # wall jump cancels fastfall
                is_fastfalling = false
                was_on_wall_counter = 20
                should_apply_gravity = false    
    else:
        was_on_wall_counter = 20     
        
    if should_apply_gravity:
        velocity.y += (GRAVITY * delta) if !is_fastfalling else ((GRAVITY * 4) * delta)
    
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED
        
    
    
    var snap_vector = Vector2(0, 32) if snap else Vector2()
    
    velocity = move_and_slide_with_snap(velocity, snap_vector, Vector2.UP, slide_slope_threshold)
    
    if is_on_floor():
        velocity.y = 0
    
    var just_landed := is_on_floor() and not snap
    if just_landed:
        snap = true
        has_double_jumped = false
        is_fastfalling = false
        
    if is_on_wall():
        was_on_wall_counter = 0
        wall_normal = get_which_wall_collided()
    else:
        was_on_wall_counter += 1
    
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
    
    check_respawn()
    
    

func check_respawn():
    if get_global_position().y > KILL_PLANE:
        set_global_position(start_pos)
          

func flip():
    facing_right = !facing_right
    sprite.flip_h = !sprite.flip_h
    
func play_anim(anim_name):
    if anim_player.is_playing() and anim_player.current_animation == anim_name:
        return
    anim_player.play(anim_name)

func get_which_wall_collided():
    for i in range(get_slide_count()):
        var collision = get_slide_collision(i)
        if collision.normal.x > 0:
            # move dir must be one (same as normal) to wall jump
            return 1
        else:
            return -1
    return 0

func do_wall_jump(wall_jump_dir):
    velocity.x += wall_jump_dir 
    velocity.y = -JUMP_FORCE
    
    
            

