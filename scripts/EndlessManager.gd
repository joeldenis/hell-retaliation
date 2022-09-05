extends Node2D

# ENEMIES
var enemiesToInclude: Array
onready var clockSpawner = preload("res://actors/ClockSpawner.tscn")

var currStageCount : int
var currStage

var willSwitch : bool = false

onready var stageTimer = $StageTimer

export (float) var timePerStage = 60.0


func _ready():
	# loading currStageCount from save
	# we subtract 1 cause totalStages
	if GlobalVariables.loadLastSave == true:
		currStageCount = SaveManager.loader() as int
		if currStageCount > 0:
			currStageCount -= 1
	elif GlobalVariables.loadLastSave == false:
		currStageCount = 0
	
	GlobalVariables.initialStageTime = timePerStage

func _process(delta):
	# this will be a mess. DO NOT PUT ENEMIES OUTSIDE STAGES IN ENEMY GROUP
	# If you want ie a bossfight that boss should be it's own group
	var numOfEnemies = get_tree().get_nodes_in_group("ENEMY").size()
	
	if numOfEnemies <= 0:
		willSwitch = true
	
	if willSwitch:
		instanceNextScene()
		currStageCount += 1
		SaveManager.saver(currStageCount)
		SaveManager.hpSaver(GlobalVariables.playerHP)
		print("SAVED: ", currStageCount as int, "HP SAVED: ",GlobalVariables.playerHP)
		willSwitch = false
	GlobalVariables.stageTimer = stageTimer.time_left

func instanceNextScene():
	match_enemies_to_include()

	var newStage = create_new_stage(currStageCount)

	currStage = newStage
	get_parent().add_child_below_node(self, currStage);

	stageTimer.stop()
	stageTimer.start(timePerStage)


func create_new_stage(currStageCount):
	var stage = Node2D.new()
	# Anzahl an Gegnern
	for i in rand_range(2,5):
		# instance enemy out of the inclusion array
		var enemy = enemiesToInclude[randi() % enemiesToInclude.size()].instance()
		stage.add_child(enemy)
		# setze die Position des Gegners
		enemy.position = Vector2(rand_range(0, get_viewport_rect().size.x), rand_range(0, get_viewport_rect().size.y))
		# prevent enemy overlap
		for j in i:
			# wenn die Positionen der Gegner zu nah beieinander sind
			if stage.get_child(j).position.distance_to(enemy.position) < 60:
				# setze die Position des Gegners neu
				enemy.position = Vector2(rand_range(0, get_viewport_rect().size.x), rand_range(0, get_viewport_rect().size.y))
				# setze den counter auf 0, damit alle Gegner nochmal überprüft werden
				j = 0
	return stage


func match_enemies_to_include():
	#TODO: Wie werden nach progressiven Stages die Odds angepasst?
	enemiesToInclude.append(clockSpawner)


func _on_StageTimer_timeout():
	# get all remaining ENEMY 
	var remainingEnemies = get_tree().get_nodes_in_group("ENEMY")
	for enemy in remainingEnemies:
		#TODO: handle this mess AAAAAA
		# remove from ENEMY group -> 0 in group -> next 
		
		enemy.remove_from_group("ENEMY")
		enemy.queue_free()
		# get animationPlayer of node
		var animPlayer = enemy.get_node("AnimationPlayer")
		animPlayer.play("DIE")