extends CharacterBody2D


const SPEED = 250.0

@onready var sprite = $AnimatedSprite2D


func _ready():
	add_to_group("player")


func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()
	if direction == Vector2.ZERO:
		sprite.stop()
		return
	if direction.x > 0 and direction.y==0:
			sprite.play("right")
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.play("right")
		else:
			sprite.play("left")
	else:
		if direction.y > 0:
			sprite.play("down")
		else:
			sprite.play("up")
