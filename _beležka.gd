
-> error remover line



bolt ma:
	
	input_power
	- se seta s plejer inputom 
	- preverja se za stop velocity
	- preverja se v state mašini			
	
	control_enabled 
	- se seta false ob zadeku 
	- preverja se povsod kar omogoča gibanje in kontrole
	- preverja se v state mašini			


old battle code

	
	# razdalja večja od dosega rakete
	if distance_to_target >= max_attacking_distance:
		shooting("bullet")
		pass
	# razdalja manjša od dosega rakete in večja od minimalne bližine
	elif distance_to_target > min_attacking_distance and distance_to_target < max_attacking_distance :
#		modulate = Color.red
		# bremzaj, če je tarča počasna
		if target_speed < target_slow_speed:
			velocity = lerp(velocity, Vector2.ZERO, 0.1)
			engine_power = lerp(engine_power, 0, 0.1)
		# streljaj raketo, če je v coni za raketo in raketo ima
		if distance_to_target > mid_attacking_distance: # and misile_count > 0:
#			yield(get_tree().create_timer(aim_time), "timeout")
			shooting("misile")
			yield(get_tree().create_timer(2*aim_time), "timeout")
		# streljaj metk, če ni v coni za raketo in raketo ima
		else:
			# da ni istočasno z raketo ... se na pozna na hitrosti streljanja
			# na vsakem metku je aim_time zamik, med sabo pa so zamaknjeni za reload time
			yield(get_tree().create_timer(aim_time), "timeout")
			shooting("bullet")
	# razdalja manjša od minimalne bližine
	elif distance_to_target <= min_attacking_distance:
		velocity = lerp(velocity, Vector2.ZERO, 0.1)
		engine_power = 0 # majhen vpliv na vse skupaj ... prepreči pa kakšen čuden karambol
#		modulate = Color.turquoise
#		shooting("bullet")
	
	engine_power = engine_power_battle
		


	

func input_states(delta):
	
	#motion states
	if input_power > 0 and control_enabled:
		power_fwd = true
		# off
		power_rev = false
		no_power = false
	elif input_power < 0 and control_enabled:
		power_rev = true
		# off
		power_fwd = false
		no_power = false
	elif input_power == 0 or not control_enabled:
		no_power = true
		# off
		power_fwd = false
		power_rev = false
