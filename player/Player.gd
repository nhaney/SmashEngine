extends KinematicBody2D

enum STATE{
    JUMP_SQUAT,
    IDLE,
    JUMP,
    RUN,
    CROUCH
}

var state = STATE.IDLE

const MOVE_SPEED = 500
const AIR_SPEED_MULTIPLIER = 0.75
const JUMP_FORCE = 600
const SHORT_HOP_FORCE = 400
const WALL_JUMP_FORCE = 300
const GRAVITY = 1600
const MAX_FALL_SPEED = 700
const KILL_PLANE = 700


const JUMP_SQUAT_LENGTH = 3
var jump_squat_timer = 0
var will_short_hop = false

onready var anim_player = $AnimationPlayer
onready var sprite = $Sprite
onready var start_pos = get_global_position()

var move_dir

export var snap := false
export var slide_slope_threshold := 50.0
export var velocity := Vector2()
var should_apply_gravity = true

var facing_right = false
var has_double_jumped = false
var was_on_wall_counter = 0
var wall_normal = 0

var is_fastfalling = false

var jump_timer = 0

var is_crouching = false

# Melee states to work on
# idle
# jumpsquat
# running
# dashing
# jumping
# double jumping


func _physics_process(delta):
    print(is_crouching)
    should_apply_gravity = true
    
    calculate_x_velocity()
    
    if Input.is_action_just_pressed("crouch"):
        handle_down_press()
    
    if Input.is_action_just_released("crouch"):
        handle_down_release()
    
    if Input.is_action_just_pressed("jump"):
        handle_jump()
    
    if Input.is_action_just_released("jump"):
        jump_released()
    
    check_jump_squat()
    
    check_wall()
    
    apply_gravity(delta)
    
    move()
    
    do_animation()

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
    

func calculate_x_velocity():
    move_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    
    var ground_speed = MOVE_SPEED * AIR_SPEED_MULTIPLIER if !is_on_floor() else MOVE_SPEED
    velocity.x = move_dir * ground_speed

func handle_down_press():
    if !snap and velocity.y > 0:
            is_fastfalling = true
    
    if snap:
        if move_dir != 0:
            move_dir = 0
        is_crouching = true


func handle_down_release():
    if snap:
        is_crouching = false

func handle_jump():
    if is_on_floor():
        jump_squat_timer = 1
    else:
        jump()     

func jump():
    if snap:
        velocity.y = -JUMP_FORCE if !will_short_hop else -SHORT_HOP_FORCE
        will_short_hop = false
        snap = false
    elif not has_double_jumped:
        velocity.y = -JUMP_FORCE
        has_double_jumped = true
        # double jump cancels fastfall
        is_fastfalling = false

func jump_released():
    if state == STATE.JUMP_SQUAT:
        will_short_hop = true

func check_wall():
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
 
func apply_gravity(delta):
    if should_apply_gravity:
        velocity.y += (GRAVITY * delta) if !is_fastfalling else ((GRAVITY * 4) * delta)
    
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

func move():
    var snap_vector = Vector2(0, 32) if snap else Vector2()
    velocity = move_and_slide_with_snap(velocity, snap_vector, Vector2.UP, slide_slope_threshold)
    
    if is_on_floor():
        velocity.y = 0
        if move_dir != 0 and is_crouching:
            is_crouching = false
    else:
        snap = false
        is_crouching = false
    
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

func check_jump_squat():
    if jump_squat_timer > JUMP_SQUAT_LENGTH:
        if is_on_floor():
            jump()
        jump_squat_timer = 0
    elif jump_squat_timer:
        jump_squat_timer += 1
    
func do_animation():
    if facing_right and move_dir > 0:
        flip()
    if !facing_right and move_dir < 0:
        flip()
    
    if is_on_floor():
        if jump_squat_timer:
            state = STATE.JUMP_SQUAT
            play_anim("squat")
        elif is_crouching:
            state = STATE.CROUCH
            play_anim("crouch")
        elif move_dir == 0:
            state = STATE.IDLE
            play_anim("idle")
        else:
            state = STATE.RUN
            play_anim("walk")
    else:
        state = STATE.JUMP
        play_anim("jump")
    
    
