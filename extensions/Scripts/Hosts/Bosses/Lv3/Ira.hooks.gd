extends Object

var hooks_installed = false

func _ready(chain: ModLoaderHookChain):
	
	var ira = chain.reference_object
	
	if ModLoaderMod.is_mod_loaded("BurgerMinus-EndpointManagement") and not hooks_installed:
		hooks_installed = true
		var mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join("BurgerMinus-DownloadMoreRAM")
		var EM_dir_path = ModLoaderMod.get_unpacked_dir().path_join("BurgerMinus-EndpointManagement")
	#	ModLoaderMod.install_script_hooks(EM_dir_path.path_join("extensions/Scripts/Hosts/Bosses/Lv3/GolemBoss.gd"), mod_dir_path.path_join("extensions/Scripts/Hosts/Bosses/Lv3/GolemBoss.hooks.gd"))
		ModLoaderMod.install_script_hooks("res://Scripts/Hosts/Bosses/Lv3/GolemBoss.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/Bosses/Lv3/GolemBoss.hooks.gd"))
	
	chain.execute_next()
	
