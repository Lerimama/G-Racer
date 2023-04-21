
-> error remover line
# zaenkrat je tukaj samo popis signalov

# AI path and target
signal path_changed (path)
	- enemy pošlje array točk potke do tarče ... 
	- pošilja se ob vsaki spremembi št. pik
	- enemi sprejme signal agenta, in ga potem pošlje z novim signalom od enemija, preko arene (node creation parent) do levela
signal path_reached # trenutno ni v uporabi
signal misile_destroyed 
	- trenutno v uporabi samo za AI
	- poveže se ob spawnanju rakete
	- raketa, ko je uničena, pošlje signal enemiju, ki na sebi spremeni stanje v "reloaded"
signal navigation_completed 
	- edge tilemap global lokacije vseh tiletov z nav komponento (floor_tiles)
	- signal sprejme level

# stats 
signal just_hit # bolt in damage
	- zaenkrat pošiljam škodo in poškodovanca ... kasneje tudi lasntika (za točke)
	- s signalom se v ready poveže arena (GM)
	- ob zadetku bolt pošlje signal s podatki, arena ga pograbi zaigra funkcijo manage stats
