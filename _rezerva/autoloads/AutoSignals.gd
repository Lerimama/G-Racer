## ------------------------------------------------------------------------------------------------------------------------------
##
##	! autolad filet !
##
## 	KAJ JE ...
##	- tukaj se nabirajo signali, ki niso povezani neposredno ... t.i. inline-signali
##	- tisti signali, ki niso defoltni določenemu nodetu
##
##	KAKO?
##	- tukaj je signal s komentarjem njegove povezave ... mob_died(value)
##	- v oddajniku daš ... Signals.emit_signal("mob_died", points)
##	- v sprejemniku povežemo na autoload signal ... Signals.connect("mob_died", self, "_on_Events_mob_died")
##
## -----------------------------------------------------------------------------------------------------------------------------

extends Node

# zaenkrat je tukaj samo popis signalov

# AI path and target
#signal path_changed (path)
#signal path_reached # trenutno ni v uporabi
#signal misile_destroyed 
#signal navigation_completed 
