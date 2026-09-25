extends RefCounted
## Deterministic combat model, independent from rendering and input devices.

const FLOOR_Y := 562.0
const ATTACKS := {
	"light": {"startup": 0.10, "active": 0.10, "recovery": 0.22, "reach": 130.0, "damage": 9.0},
	"heavy": {"startup": 0.30, "active": 0.16, "recovery": 0.49, "reach": 180.0, "damage": 24.0},
	"special": {"startup": 0.22, "active": 0.22, "recovery": 0.56, "reach": 245.0, "damage": 34.0}
}

var pos := Vector2.ZERO
var velocity := Vector2.ZERO
var facing := 1.0
var health := 100.0
var rage := 0.0
var wins := 0
var attack := ""
var attack_time := 0.0
var connected := false
var stun := 0.0
var guarding := false
var crouching := false
var walking := false
var flash := 0.0
var ai_timer := 0.0
var ai_command: Dictionary = {}

func reset(x: float, direction: float) -> void:
	pos = Vector2(x, FLOOR_Y)
	velocity = Vector2.ZERO
	facing = direction
	health = 100.0
	rage = 0.0
	attack = ""
	attack_time = 0.0
	stun = 0.0
	flash = 0.0
	guarding = false
	crouching = false
	walking = false
	ai_timer = 0.0
	ai_command = {}

func grounded() -> bool:
	return pos.y >= FLOOR_Y - 0.1

func start_attack(kind: String) -> bool:
	if not ATTACKS.has(kind) or not attack.is_empty() or stun > 0.0 or health <= 0.0:
		return false
	if kind == "special":
		if rage < 100.0:
			return false
		rage = 0.0
	attack = kind
	attack_time = 0.0
	connected = false
	guarding = false
	return true

func tick(dt: float, command: Dictionary, opponent) -> void:
	flash = maxf(0.0, flash - dt)
	stun = maxf(0.0, stun - dt)
	if not attack.is_empty():
		attack_time += dt
		var data: Dictionary = ATTACKS[attack]
		if attack_time >= data.startup + data.active + data.recovery:
			attack = ""
	if attack.is_empty() and stun <= 0.0:
		facing = 1.0 if opponent.pos.x >= pos.x else -1.0
	guarding = false
	crouching = false
	walking = false
	if health > 0.0 and stun <= 0.0 and attack.is_empty():
		var move: float = command.get("move", 0.0)
		guarding = grounded() and (command.get("guard", false) or move * facing < 0.0)
		crouching = grounded() and command.get("crouch", false)
		velocity.x = move * (100.0 if guarding else 230.0) * (0.0 if crouching else 1.0)
		walking = absf(velocity.x) > 0.0
		if command.get("jump", false) and grounded():
			velocity.y = -690.0
			guarding = false
		for kind in ["special", "heavy", "light"]:
			if command.get(kind, false) and start_attack(kind):
				break
	else:
		velocity.x = move_toward(velocity.x, 0.0, dt * 850.0)
	velocity.y += 1850.0 * dt
	pos += velocity * dt
	pos.x = clampf(pos.x, 65.0, 1215.0)
	if pos.y >= FLOOR_Y:
		pos.y = FLOOR_Y
		velocity.y = 0.0

func active_hit() -> bool:
	if attack.is_empty() or connected:
		return false
	var data: Dictionary = ATTACKS[attack]
	return attack_time >= data.startup and attack_time < data.startup + data.active

func can_hit(opponent) -> bool:
	if not active_hit():
		return false
	var delta: Vector2 = opponent.pos - pos
	return delta.x * facing > -20.0 and absf(delta.x) <= ATTACKS[attack].reach + 28.0 and absf(delta.y) < 115.0

func receive_hit(damage: float, direction: float, heavy: bool) -> bool:
	var blocked := guarding and grounded() and facing * direction < 0.0
	health = maxf(0.0, health - (damage * 0.08 if blocked else damage))
	rage = minf(100.0, rage + (damage * 0.8 if blocked else damage * 1.5))
	stun = (0.18 if blocked else (0.46 if heavy else 0.27))
	velocity.x = direction * (100.0 if blocked else (340.0 if heavy else 190.0))
	flash = 0.15
	attack = ""
	return blocked
