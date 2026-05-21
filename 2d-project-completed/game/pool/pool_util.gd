class_name PoolUtil

## 풀에 등록된 노드는 풀로 반환하고, 아니면 queue_free 합니다.
static func release_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.has_meta(&"_scene_pool"):
		var pool: Node = node.get_meta(&"_scene_pool") as Node
		if pool and pool.has_method(&"release"):
			pool.release(node)
			return
	node.queue_free()
