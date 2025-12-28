extends Object

func set_icon(chain: ModLoaderHookChain):
	
	var icon = chain.reference_object as ItemInventoryIcon
	
	chain.execute_next()
	
	var path = "res://Art/Upgrades/" + str(icon.upgrade_name) + ".png"
	if Util.get_cached_texture(path) == null:
		icon.icon.texture = Util.get_cached_texture("res://Art/Upgrades/Old/myopia.png")
