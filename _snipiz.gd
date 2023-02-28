extends Node

# snip inline timer
yield(get_tree().create_timer(bullet_reload_time), "timeout")


### HOW IT WORKS? ----------------------------------------------------------------
###
### štarta z intro animacijo in tween_on 
### ko area zazna drugega pejerja se sproži tween_off
### tween_off na koncu kliče "expand" animacijo in "trail decay"
### "expand" animacija po koncu kliče "activated" loop
### "activated" loop se ponovi n-krat in potem
###
### TRAIL
### širina traila se poveča z intro animacijo
### ko se izvaja "trail decay"
### 
### ------------------------------------------------------------------------------
