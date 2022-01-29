class_name IntTree

var nodes = []	# The value of each node
var children = []	# Lists of children for each node
var parents = []	# Lists of parents for each node

func add_child(parent_index:int, val:int):
	if(node_exists(parent_index)):
		nodes.push_back(val)
		children.push_back([])
		parents.push_back([])
		var child_index = len(nodes) -1
		create_edge(parent_index, child_index)
		return child_index
	print("Error adding node")
	return -1


func get_parent(index:int):
	if(node_exists(index)):
		return parents[index]
	print("Error getting parent")
	return -1


func get_children(index:int):
	if(node_exists(index)):
		return children[index]
	print("Error getting children")
	return -1


func create_edge(parent_index:int, child_index:int):
	parents[child_index].push_back(parent_index)	# Add parent to the child
	children[parent_index].push_back(child_index)	# Add child to the parent


func get_index(value:int):
	for node in nodes:
		if node == value:
			return node
	return -1


func node_exists(index:int):
	if(index < 0 or index >= len(nodes)):
		return false
	return true
