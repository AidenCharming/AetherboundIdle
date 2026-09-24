extends RefCounted
## The test bridge stays off unless the game is started with -- --bridge.

var t


func test_bridge_is_off_by_default() -> void:
	t.ok(not TestBridge.enabled, "no --bridge, no listening port")
	t.ok(not TestBridge.is_processing(), "and it does nothing each frame")
