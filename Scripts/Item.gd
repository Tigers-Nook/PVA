extends Node
# Exemplo de script para um item (res://Scenes/Item.tscn)
extends Area2D

@export var item_value = 5
    @export var item_name = "TV"
var found = false

signal item_clicked(item_node)

func _on_input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if not found and not GameManager.is_qte_active and not GameManager.is_game_over:
            item_clicked.emit(self) # Emite um sinal para a cena principal processar