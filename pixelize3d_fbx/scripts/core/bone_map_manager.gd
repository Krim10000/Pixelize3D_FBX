# scripts/core/bone_map_manager.gd
extends Node

func create_bone_map_for_model(skeleton: Skeleton3D) -> BoneMap:
	var bone_map = BoneMap.new()
	
	# Mapear huesos comunes (ajusta según tu rig)
	var bone_mappings = {
		"Root": "Root",
		"Hips": "mixamorig:Hips", 
		"Spine": "mixamorig:Spine",
		"Spine1": "mixamorig:Spine1",
		"Spine2": "mixamorig:Spine2",
		"Neck": "mixamorig:Neck",
		"Head": "mixamorig:Head",
		"LeftShoulder": "mixamorig:LeftShoulder",
		"LeftArm": "mixamorig:LeftArm",
		"LeftForeArm": "mixamorig:LeftForeArm",
		"LeftHand": "mixamorig:LeftHand",
		# ... más huesos según tu rig
	}
	
	for godot_bone in bone_mappings:
		var skeleton_bone = bone_mappings[godot_bone]
		if skeleton.find_bone(skeleton_bone) != -1:
			bone_map.set_skeleton_bone_name(godot_bone, skeleton_bone)
	
	return bone_map
