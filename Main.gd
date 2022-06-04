extends Node2D

const TILE_SIZE = 16;

const LEVEL_SIZES = [
	Vector2(30,30),
	Vector2(35,35),
	Vector2(40,40),
	Vector2(45,45),
	Vector2(50,50),
]

const LEVEL_ROOM_COUNTS = [5,7,9,12,15]
const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8

enum Tile {Wall, Floor, Ladder}

# Current Level ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

var level_num = 0
var map = []
var rooms = []
var level_size

# Refs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

onready var tile_map = $GameBoard/TileMap
onready var player = $Player/PlayerSprite

# Game State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

var player_tile
var score = 0

# Methods ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _ready():
	OS.set_window_size(Vector2(1280, 720))
	randomize()
	buildLevel()

func buildLevel():
	#start with a clear map
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	level_size = LEVEL_SIZES[level_num]
	for x in range(level_size.x):
		map.append([])
		for y in range(level_size.y):
			map[x].append(Tile.Floor)
			tile_map.set_cell(x,y, Tile.Floor)
			
	var free_regions = [Rect2(Vector2(2,2), level_size - Vector2(4,4))] # sets a rectangle at 2,2 with level_size - 2 tile border
	var num_rooms = LEVEL_ROOM_COUNTS[level_num]
	for i in range(num_rooms): #add num_rooms within free_regions
		add_room(free_regions)
		if free_regions.empty():
			break


func add_room(free_regions):
	var region = free_regions[randi() % free_regions.size()] # % sets upper bound for randi, max remainder can equal is free_regions.size()
	var size_x = MIN_ROOM_DIMENSION
	var size_y = MIN_ROOM_DIMENSION
	var start_x = region.position.x
	var start_y = region.position.y
	
	if region.size.x > MIN_ROOM_DIMENSION:
		size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION) # grows room size randomly from MINIMUM_ROOM_DIMENSION
		
	if region.size.y > MIN_ROOM_DIMENSION:
		size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION) # grows room size randomly from MINIMUM_ROOM_DIMENSION
	
	size_x = min(size_x, MAX_ROOM_DIMENSION) # constrain room growth to MAX_ROOM_DIMENSION
	size_y = min(size_y, MAX_ROOM_DIMENSION)
	
	if region.size.x > size_x:
		start_x += randi() % int(region.size.x -size_x) # place randomly on map board
		
	if region.size.y > size_y:
		start_y += randi() % int(region.size.y -size_y)
	
	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)
	
	#set tile placement for rooms
	for x in range(start_x, start_x + size_x): #Set top and bottom edges of rooms to walls
		set_tile(x, start_y, Tile.Wall)
		set_tile(x, start_y + size_y - 1, Tile.Wall)
		
	for y in range(start_y + 1, start_y + size_y - 1): #Set left and right edges of rooms to walls
		set_tile(start_x, y, Tile.Wall)
		set_tile(start_x + size_x - 1, y, Tile.Wall)
		
		for x in range(start_x + 1, start_x + size_x - 1): #set floor tiles within walls
			set_tile(x, y, Tile.Floor)
	
	cut_regions(free_regions, room)

func set_tile(x, y, type):
	map[x][y] = type
	tile_map.set_cell(x, y, type)

func cut_regions(free_regions, region_to_remove):
	var removal_queue = []
	var addition_queue = []
	
	for region in free_regions: #check if any regions intersect, if so, remove room and check if that room can be made in leftover space
		if region.intersects(region_to_remove):
			removal_queue.append(region)
			
			#calculate leftover space
			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region.end.x - region_to_remove.end.x -1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1
			
			#add all possible new room placements to addition_queue
			if leftover_left >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
			if leftover_right >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
			if leftover_above >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
			if leftover_below >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))
	
	for region in removal_queue:
		free_regions.erase(region)
	
	for region in addition_queue:
		free_regions.append(region)
