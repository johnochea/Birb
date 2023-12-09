extends Control

@export var Address = "172.25.0.1"
@export var port = 35
var peer
var character_select
var game_start

func _ready():
	var viewport_size = get_viewport_rect().size
	var reference_size = Vector2(1920, 1080)  # Your reference size for scaling
	GameManager.scale_factor = viewport_size / reference_size
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	scale = GameManager.scale_factor
	pass
	
func _process(_delta):
	pass
func _on_play_btn_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	if error != OK:
		print("Hosting failed! Error: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	SendPlayerInformation(multiplayer.get_unique_id())
	$"Main Menu/Button_sound".play()
	await get_tree().create_timer(0.17).timeout
	
func _on_join_btn_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	$"Main Menu/Button_sound".play()
	await get_tree().create_timer(0.17).timeout
	
func _on_quit_btn_pressed():	
	$"Main Menu/Button_sound".play()
	await get_tree().create_timer(0.17).timeout
	CharacterSelect.rpc()
	
@rpc('any_peer')
func SendPlayerInformation(id):
	var player = 1

	if !GameManager.Players.has(id):
		for i in GameManager.Players:
			if GameManager.Players[i].player == player:
				player += 1
		GameManager.Players[id] = {
			"id": id,
			"character": "C4",
			"selected": 0,
			"player": player,
			"dead": false
		}
		
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(i)
			


@rpc('any_peer', 'call_local')
func CharacterSelect():
	character_select = load('res://CharacterSelection.tscn').instantiate()
	get_tree().root.add_child(character_select)
	character_select.scale = GameManager.scale_factor
	self.hide()
	

func peer_connected(id):
	print("Player Connected" + str(id))
	pass
	
func peer_disconnected(id):
	print("Player Disconnected" + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()

func connected_to_server():
	
	print("Connected to server!")
	SendPlayerInformation.rpc_id(1, multiplayer.get_unique_id())
	
func connection_failed():
	print("Connection failed!")
