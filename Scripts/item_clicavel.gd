extends Area2D

func _ready():
	pass
	$RoubarBtn.pressed.connect(Roubar)
func _process(delta):
	pass
	
func Roubar() -> void:
	pass # Replace with function body.
	queue_free()
