extends TextureButton

func _pressed():
	var game_scene = load("res://game/game.tscn")
	var game_instance = game_scene.instantiate()
	game_instance.position.x = get_viewport().size.x
	get_tree().current_scene.add_child(game_instance)
	var tween = get_tree().create_tween()
	tween.tween_property(game_instance, "position:x", 0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_remove_menu"))

func _remove_menu():
	get_tree().current_scene.queue_free()
