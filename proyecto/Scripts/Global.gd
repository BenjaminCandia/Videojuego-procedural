extends Node  # No CanvasLayer

var coins_total := 4  # empieza con 4 monedas

func award_coin():
	coins_total += 1
