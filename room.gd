extends Control

#const ENEMY_MAX_HP = 100
#const DAMAGE_PER_HIT = 25
#const MAGE_MAX_HP = 100

var tasks: Array
var correct_answer: float
var enemy_hp: int
var mage_hp : int
var current_task: Dictionary

@onready var formula_panel = %FormulaPanel
@onready var formula_prompt = %FormulaPrompt
@onready var formula_buttons = %FormulaButtons
@onready var health_bar = %EnemyHealthBar
@onready var task_label = %TaskLabel
@onready var answer_input = %AnswerInput
@onready var cast_button = %CastButton
@onready var result_label = %ResultLabel
@onready var mage_health = %MageHealthBar
@onready var restart_button = %RestartButton
@onready var enemy_sprite = %EnemySprite
@onready var mage_sprite = %MageSprite


func _ready():
	answer_input.text_submitted.connect(func(_text): _on_cast_pressed())
	load_tasks()
	mage_hp = Globals.MAGE_MAX_HP
	enemy_hp = Globals.ENEMY_MAX_HP
	update_health_bar()
	generate_task()
	cast_button.pressed.connect(_on_cast_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

func generate_task():
	if tasks.is_empty():
		task_label.text = "Нет задач: проверьте tasks.json"
		return
	var task = tasks.pick_random()
	current_task = task
	var values = {}
	var texts = {}
	for key in task["vars"]:
		var v = task["vars"][key].pick_random()
		values [key] = v 
		texts [key] = fmt(v)
	task_label.text = task["text"].format(texts)
	correct_answer = calculate(task["expr"], values)
	if is_nan(correct_answer):
		generate_task() 
		return
	show_formula_panel()

func _on_cast_pressed():
	if cast_button.disabled:
		return
	var text = answer_input.text.replace(",",".")
	if not text.is_valid_float():
		result_label.text = "Введи число."
		return
	var player_value = text.to_float()
	if abs(player_value-correct_answer) < 0.01:
		cast_button.disabled = true
		answer_input.text = ""
		await hit_enemy()
		if enemy_hp > 0:
			result_label.text = "Разряд прошел! Здоровье врага: %d HP"% max(enemy_hp, 0)
	
	else:
		answer_input.text = ""
		await take_hit()
		if mage_hp > 0 and mage_hp <= 25:
			result_label.text = "Неверно! Здоровье мага: %d HP \nОсторожно! Критический запас здоровья!"%mage_hp
		elif mage_hp > 0:
			result_label.text = "Неверно! Здоровье мага: %d HP" % mage_hp


func update_health_bar():
	health_bar.value = enemy_hp
	mage_health.value = mage_hp

func hit_enemy():
	play_once(mage_sprite, "attack")
	await mage_sprite.animation_finished
	enemy_hp -= Globals.DAMAGE_PER_HIT
	play_once(enemy_sprite, "hurt")
	if enemy_hp <= 0:
		end_game()
	else:
		cast_button.disabled = false
		generate_task()
	update_health_bar()

func take_hit():
	cast_button.disabled = true
	play_once(mage_sprite, "hurt")
	mage_hp = max(0, mage_hp - Globals.DAMAGE_PER_HIT)
	update_health_bar()
	await mage_sprite.animation_finished
	if mage_hp > 0:
		cast_button.disabled = false
	if mage_hp <= 0:
		end_game()

func end_game():
	if enemy_hp <= 0:
		result_label.text = "Победа! Враг уничтожен!"
		enemy_sprite.play("death")
	elif mage_hp <= 0:
		result_label.text = "Вы умерли!"
		mage_sprite.play("death")
	set_quest_visible(false)
	formula_panel.visible = false
	task_label.text = ""
	restart_button.visible = true

func _on_restart_pressed():
	get_tree().reload_current_scene()

func load_tasks():
	var file = FileAccess.open("res://tasks.json", FileAccess.READ)
	if file == null:
		print("Ошибка в файле tasks.json!")
		return
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		print("В tasks.json ошибка синтаксиса")
		return
	tasks = data

func fmt(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(value))
	return str(value)

func play_once(sprite: AnimatedSprite2D, anim: String):
	sprite.play(anim)
	await sprite.animation_finished
	if sprite.animation == anim:
		sprite.play("idle")

func calculate(expr_text: String, values: Dictionary) -> float:
	var expr = Expression.new()
	var error = expr.parse(expr_text, values.keys())
	if error != OK:
		print("Ошибка в формуле: ", expr_text)
		return NAN
	var result = expr.execute(values.values())
	if expr.has_execute_failed():
		print("Не удалось вычислить: ", expr_text)
		return NAN
	return float(result)

func show_formula_panel():
	if not current_task.has("formulas"):
		return
	set_quest_visible(false)
	formula_prompt.text = "Выбери формулу для решения:\n" + task_label.text
	for child in formula_buttons.get_children():
		child.queue_free()
	var order = range(current_task["formulas"].size())
	order.shuffle()
	for idx in order:
		var btn = Button.new()
		btn.text = current_task["formulas"][idx]
		btn.pressed.connect(_on_formula_chosen.bind(idx, btn))
		formula_buttons.add_child(btn)
	formula_panel.visible = true


func _on_formula_chosen(idx: int, btn: Button):
	if idx == int(current_task["right"]):
		set_quest_visible(true)
		formula_panel.visible = false
		task_label.visible = true
		answer_input.grab_focus()
		result_label.text = "Формула верна! Теперь вычисли значение!"
	else:
		take_hit()
		btn.disabled = true
		if mage_hp > 0:
			result_label.text = "Формула неверна! Попробуй еще раз!"

func set_quest_visible(value:bool):
	cast_button.visible = value
	answer_input.visible = value
	task_label.visible = value
