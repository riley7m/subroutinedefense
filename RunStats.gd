extends Node

var damage_dealt: int = 0
var damage_taken: int = 0
var data_credits_earned: int = 0
var archive_tokens_earned: int = 0
var current_wave: int = 1

func reset():
	damage_dealt = 0
	damage_taken = 0
	data_credits_earned = 0
	archive_tokens_earned = 0
	current_wave = 1
