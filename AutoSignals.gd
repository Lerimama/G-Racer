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


signal misile_destroyed # avtorju pošljem signal za "reloaded" stanje

# enemy AI
signal navigation_completed # enemiju pošljem lokacije floor tiletov po izračunu tal
signal path_changed (path) # pošlje nov array točk na navgicajski poti (ta signal se sproži skoraj vsak frejm
signal target_reached # trenutno ni v uporabi
