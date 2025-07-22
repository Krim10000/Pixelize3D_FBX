# scripts/export/engine_integration.gd
extends Node

# Input: Spritesheets generados y metadata
# Output: Archivos de integración para diferentes motores de juego

signal integration_complete(engine: String, files: Array)
signal integration_failed(engine: String, error: String)

# Templates para diferentes motores
const UNITY_SCRIPT_TEMPLATE = """using UnityEngine;
using System.Collections.Generic;

[CreateAssetMenu(fileName = "%UNIT_NAME%_AnimationData", menuName = "Pixelize3D/%UNIT_NAME% Animation Data")]
public class %UNIT_NAME%AnimationData : ScriptableObject
{
	[System.Serializable]
	public class AnimationInfo
	{
		public string name;
		public Sprite[] sprites;
		public float fps = %FPS%;
		public bool loop = true;
	}
	
	[System.Serializable]
	public class DirectionalAnimation
	{
		public int direction;
		public float angle;
		public AnimationInfo[] animations;
	}
	
	public DirectionalAnimation[] directions = new DirectionalAnimation[%DIRECTIONS%];
	public int frameWidth = %WIDTH%;
	public int frameHeight = %HEIGHT%;
	
	private Dictionary<string, Dictionary<int, Sprite[]>> animationCache;
	
	public void Initialize()
	{
		animationCache = new Dictionary<string, Dictionary<int, Sprite[]>>();
		
		foreach (var dir in directions)
		{
			foreach (var anim in dir.animations)
			{
				if (!animationCache.ContainsKey(anim.name))
					animationCache[anim.name] = new Dictionary<int, Sprite[]>();
				
				animationCache[anim.name][dir.direction] = anim.sprites;
			}
		}
	}
	
	public Sprite[] GetAnimation(string animationName, int direction)
	{
		if (animationCache == null) Initialize();
		
		if (animationCache.ContainsKey(animationName) && 
			animationCache[animationName].ContainsKey(direction))
		{
			return animationCache[animationName][direction];
		}
		
		return null;
	}
	
	public Sprite GetFrame(string animationName, int direction, int frame)
	{
		var sprites = GetAnimation(animationName, direction);
		if (sprites != null && frame >= 0 && frame < sprites.Length)
		{
			return sprites[frame];
		}
		return null;
	}
}
"""

const GODOT_RESOURCE_TEMPLATE = """[gd_resource type="Resource" script_class="SpriteSheetAnimation" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/sprite_sheet_animation.gd" id="1"]

[resource]
script = ExtResource("1")
unit_name = "%UNIT_NAME%"
sprite_sheet_path = "%SPRITE_PATH%"
frame_width = %WIDTH%
frame_height = %HEIGHT%
directions = %DIRECTIONS%
fps = %FPS%
animations = {
%ANIMATIONS%
}
"""

const UNREAL_SCRIPT_TEMPLATE = """#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "Engine/Texture2D.h"
#include "%UNIT_NAME%AnimationData.generated.h"

USTRUCT(BlueprintType)
struct FDirectionalSprites
{
	GENERATED_BODY()
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	int32 Direction;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float Angle;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<UTexture2D*> Frames;
};

USTRUCT(BlueprintType)
struct FAnimationData
{
	GENERATED_BODY()
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FString AnimationName;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FDirectionalSprites> Directions;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float FramesPerSecond = %FPS%;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bLooping = true;
};

UCLASS(BlueprintType)
class YOURPROJECT_API U%UNIT_NAME%AnimationData : public UDataAsset
{
	GENERATED_BODY()
	
public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Animation")
	TArray<FAnimationData> Animations;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	int32 FrameWidth = %WIDTH%;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	int32 FrameHeight = %HEIGHT%;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	int32 TotalDirections = %DIRECTIONS%;
	
	UFUNCTION(BlueprintCallable, Category = "Animation")
	UTexture2D* GetFrame(const FString& AnimationName, int32 Direction, int32 Frame) const;
	
	UFUNCTION(BlueprintCallable, Category = "Animation")
	TArray<UTexture2D*> GetAnimation(const FString& AnimationName, int32 Direction) const;
};
"""

const CONSTRUCT3_JSON_TEMPLATE = """{
	"name": "%UNIT_NAME%",
	"animations": {
%ANIMATIONS_JSON%
	},
	"spritesheet": {
		"url": "%SPRITE_URL%",
		"frameWidth": %WIDTH%,
		"frameHeight": %HEIGHT%,
		"columns": %COLUMNS%,
		"rows": %ROWS%
	}
}"""

func generate_unity_integration(unit_data: Dictionary, output_path: String) -> void:
	var unit_name = unit_data.name.capitalize().replace(" ", "")
	
	# Generar script C#
	var script_content = UNITY_SCRIPT_TEMPLATE
	script_content = script_content.replace("%UNIT_NAME%", unit_name)
	script_content = script_content.replace("%FPS%", str(unit_data.fps))
	script_content = script_content.replace("%DIRECTIONS%", str(unit_data.directions))
	script_content = script_content.replace("%WIDTH%", str(unit_data.sprite_size.width))
	script_content = script_content.replace("%HEIGHT%", str(unit_data.sprite_size.height))
	
	var script_path = output_path.path_join(unit_name + "AnimationData.cs")
	_save_file(script_path, script_content)
	
	# Generar archivo de importación
	var import_script = _generate_unity_import_script(unit_data)
	var import_path = output_path.path_join(unit_name + "Importer.cs")
	_save_file(import_path, import_script)
	
	# Generar instrucciones
	var readme = _generate_unity_readme(unit_name)
	var readme_path = output_path.path_join("Unity_Integration_README.txt")
	_save_file(readme_path, readme)
	
	emit_signal("integration_complete", "Unity", [script_path, import_path, readme_path])

func generate_godot_integration(unit_data: Dictionary, output_path: String) -> void:
	var resource_content = GODOT_RESOURCE_TEMPLATE
	resource_content = resource_content.replace("%UNIT_NAME%", unit_data.name)
	resource_content = resource_content.replace("%SPRITE_PATH%", unit_data.sprite_path)
	resource_content = resource_content.replace("%WIDTH%", str(unit_data.sprite_size.width))
	resource_content = resource_content.replace("%HEIGHT%", str(unit_data.sprite_size.height))
	resource_content = resource_content.replace("%DIRECTIONS%", str(unit_data.directions))
	resource_content = resource_content.replace("%FPS%", str(unit_data.fps))
	
	# Formatear animaciones
	var animations_str = ""
	for anim in unit_data.animations:
		animations_str += '\t"%s": {\n' % anim.name
		animations_str += '\t\t"frames": %d,\n' % anim.frames
		animations_str += '\t\t"loop": %s,\n' % str(anim.loop).to_lower()
		animations_str += '\t\t"directions": %s\n' % str(anim.directions)
		animations_str += '\t},\n'
	
	resource_content = resource_content.replace("%ANIMATIONS%", animations_str)
	
	var resource_path = output_path.path_join(unit_data.name + "_animation.tres")
	_save_file(resource_path, resource_content)
	
	# Generar script de animación
	var anim_script = _generate_godot_animation_script()
	var script_path = output_path.path_join("sprite_sheet_animation.gd")
	_save_file(script_path, anim_script)
	
	emit_signal("integration_complete", "Godot", [resource_path, script_path])

func generate_unreal_integration(unit_data: Dictionary, output_path: String) -> void:
	var unit_name = unit_data.name.capitalize().replace(" ", "")
	
	# Generar header C++
	var header_content = UNREAL_SCRIPT_TEMPLATE
	header_content = header_content.replace("%UNIT_NAME%", unit_name)
	header_content = header_content.replace("%FPS%", str(unit_data.fps))
	header_content = header_content.replace("%WIDTH%", str(unit_data.sprite_size.width))
	header_content = header_content.replace("%HEIGHT%", str(unit_data.sprite_size.height))
	header_content = header_content.replace("%DIRECTIONS%", str(unit_data.directions))
	
	var header_path = output_path.path_join(unit_name + "AnimationData.h")
	_save_file(header_path, header_content)
	
	# Generar implementación C++
	var cpp_content = _generate_unreal_cpp(unit_name)
	var cpp_path = output_path.path_join(unit_name + "AnimationData.cpp")
	_save_file(cpp_path, cpp_content)
	
	# Generar Blueprint helper
	var bp_script = _generate_unreal_blueprint_script(unit_name)
	var bp_path = output_path.path_join(unit_name + "_BP_Helper.txt")
	_save_file(bp_path, bp_script)
	
	emit_signal("integration_complete", "Unreal", [header_path, cpp_path, bp_path])

func generate_web_integration(unit_data: Dictionary, output_path: String) -> void:
	# Generar para Construct 3
	var c3_content = CONSTRUCT3_JSON_TEMPLATE
	c3_content = c3_content.replace("%UNIT_NAME%", unit_data.name)
	c3_content = c3_content.replace("%SPRITE_URL%", unit_data.name + "_spritesheet.png")
	c3_content = c3_content.replace("%WIDTH%", str(unit_data.sprite_size.width))
	c3_content = c3_content.replace("%HEIGHT%", str(unit_data.sprite_size.height))
	c3_content = c3_content.replace("%COLUMNS%", str(unit_data.columns))
	c3_content = c3_content.replace("%ROWS%", str(unit_data.rows))
	
	var animations_json = _format_animations_json(unit_data.animations)
	c3_content = c3_content.replace("%ANIMATIONS_JSON%", animations_json)
	
	var c3_path = output_path.path_join(unit_data.name + "_construct3.json")
	_save_file(c3_path, c3_content)
	
	# Generar para Phaser
	var phaser_config = _generate_phaser_config(unit_data)
	var phaser_path = output_path.path_join(unit_data.name + "_phaser.js")
	_save_file(phaser_path, phaser_config)
	
	# Generar ejemplo HTML
	var html_example = _generate_html_example(unit_data)
	var html_path = output_path.path_join(unit_data.name + "_example.html")
	_save_file(html_path, html_example)
	
	emit_signal("integration_complete", "Web", [c3_path, phaser_path, html_path])

func generate_all_integrations(unit_data: Dictionary, output_path: String) -> void:
	# Crear subcarpetas para cada motor
	var engines = ["Unity", "Godot", "Unreal", "Web"]
	
	for engine in engines:
		var engine_path = output_path.path_join(engine)
		DirAccess.make_dir_recursive_absolute(engine_path)
		
		match engine:
			"Unity":
				generate_unity_integration(unit_data, engine_path)
			"Godot":
				generate_godot_integration(unit_data, engine_path)
			"Unreal":
				generate_unreal_integration(unit_data, engine_path)
			"Web":
				generate_web_integration(unit_data, engine_path)

# Funciones auxiliares para generar código
func _generate_unity_import_script(unit_data: Dictionary) -> String:
	return """using UnityEngine;
using UnityEditor;
using System.IO;

public class %sImporter : EditorWindow
{
	[MenuItem("Pixelize3D/Import %s Sprites")]
	static void ImportSprites()
	{
		string path = EditorUtility.OpenFilePanel("Select Spritesheet", "", "png");
		if (string.IsNullOrEmpty(path)) return;
		
		// Import texture
		string relativePath = "Assets" + path.Substring(Application.dataPath.Length);
		AssetDatabase.ImportAsset(relativePath);
		
		// Configure import settings
		TextureImporter importer = AssetImporter.GetAtPath(relativePath) as TextureImporter;
		importer.textureType = TextureImporterType.Sprite;
		importer.spriteImportMode = SpriteImportMode.Multiple;
		importer.spritePixelsPerUnit = 100;
		importer.filterMode = FilterMode.Point;
		importer.textureCompression = TextureImporterCompression.Uncompressed;
		
		// Generate sprites
		var spritesheet = new SpriteMetaData[%d];
		int index = 0;
		
		for (int dir = 0; dir < %d; dir++)
		{
			for (int frame = 0; frame < %d; frame++)
			{
				spritesheet[index] = new SpriteMetaData
				{
					name = string.Format("{0}_dir{1}_frame{2}", "%s", dir, frame),
					rect = new Rect(frame * %d, dir * %d, %d, %d),
					pivot = new Vector2(0.5f, 0.5f),
					alignment = 9
				};
				index++;
			}
		}
		
		importer.spritesheet = spritesheet;
		AssetDatabase.ImportAsset(relativePath, ImportAssetOptions.ForceUpdate);
		
		Debug.Log("Sprites imported successfully!");
	}
}""" % [unit_data.name, unit_data.name, 
		unit_data.total_frames, unit_data.directions, 
		unit_data.frames_per_animation, unit_data.name,
		unit_data.sprite_size.width, unit_data.sprite_size.height,
		unit_data.sprite_size.width, unit_data.sprite_size.height]

func _generate_godot_animation_script() -> String:
	return """extends Resource
class_name SpriteSheetAnimation

@export var unit_name: String = ""
@export var sprite_sheet_path: String = ""
@export var frame_width: int = 128
@export var frame_height: int = 128
@export var directions: int = 16
@export var fps: float = 12.0
@export var animations: Dictionary = {}

var sprite_sheet: Texture2D

func _init():
	if sprite_sheet_path != "":
		sprite_sheet = load(sprite_sheet_path)

func get_frame_texture(animation_name: String, direction: int, frame: int) -> AtlasTexture:
	if not sprite_sheet:
		return null
	
	if not animation_name in animations:
		return null
	
	var atlas = AtlasTexture.new()
	atlas.texture = sprite_sheet
	
	var x = frame * frame_width
	var y = direction * frame_height
	
	atlas.region = Rect2(x, y, frame_width, frame_height)
	
	return atlas

func get_animation_length(animation_name: String) -> float:
	if animation_name in animations:
		return animations[animation_name].frames / fps
	return 0.0

func setup_animated_sprite(sprite: AnimatedSprite2D, animation_name: String):
	sprite.sprite_frames = SpriteFrames.new()
	
	for dir in range(directions):
		var anim_name = "%s_dir%d" % [animation_name, dir]
		sprite.sprite_frames.add_animation(anim_name)
		sprite.sprite_frames.set_animation_speed(anim_name, fps)
		
		if animation_name in animations:
			for frame in range(animations[animation_name].frames):
				var atlas = get_frame_texture(animation_name, dir, frame)
				sprite.sprite_frames.add_frame(anim_name, atlas)
"""

func _generate_unreal_cpp(unit_name: String) -> String:
	return """#include "%sAnimationData.h"

UTexture2D* U%sAnimationData::GetFrame(const FString& AnimationName, int32 Direction, int32 Frame) const
{
	for (const FAnimationData& AnimData : Animations)
	{
		if (AnimData.AnimationName == AnimationName)
		{
			for (const FDirectionalSprites& DirSprites : AnimData.Directions)
			{
				if (DirSprites.Direction == Direction)
				{
					if (Frame >= 0 && Frame < DirSprites.Frames.Num())
					{
						return DirSprites.Frames[Frame];
					}
				}
			}
		}
	}
	return nullptr;
}

TArray<UTexture2D*> U%sAnimationData::GetAnimation(const FString& AnimationName, int32 Direction) const
{
	TArray<UTexture2D*> Result;
	
	for (const FAnimationData& AnimData : Animations)
	{
		if (AnimData.AnimationName == AnimationName)
		{
			for (const FDirectionalSprites& DirSprites : AnimData.Directions)
			{
				if (DirSprites.Direction == Direction)
				{
					Result = DirSprites.Frames;
					break;
				}
			}
			break;
		}
	}
	
	return Result;
}""" % [unit_name, unit_name, unit_name]

func _save_file(path: String, content: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
	else:
		emit_signal("integration_failed", "File", "No se pudo crear: " + path)

func _format_animations_json(animations: Array) -> String:
	var result = ""
	for i in range(animations.size()):
		var anim = animations[i]
		result += '        "%s": {\n' % anim.name
		result += '            "frames": %d,\n' % anim.frames
		result += '            "fps": %d,\n' % anim.fps
		result += '            "loop": %s\n' % str(anim.loop).to_lower()
		result += '        }'
		if i < animations.size() - 1:
			result += ","
		result += "\n"
	return result

func _generate_phaser_config(unit_data: Dictionary) -> String:
	return """// Phaser 3 Configuration for %s
const %sConfig = {
	key: '%s',
	frameWidth: %d,
	frameHeight: %d,
	animations: [
%s
	]
};

// Load spritesheet
function preload() {
	this.load.spritesheet('%s', '%s_spritesheet.png', {
		frameWidth: %sConfig.frameWidth,
		frameHeight: %sConfig.frameHeight
	});
}

// Create animations
function create() {
	%sConfig.animations.forEach(anim => {
		this.anims.create(anim);
	});
}""" % [unit_data.name, unit_data.name, unit_data.name,
		unit_data.sprite_size.width, unit_data.sprite_size.height,
		_generate_phaser_animations(unit_data),
		unit_data.name, unit_data.name, unit_data.name, unit_data.name]

func _generate_phaser_animations(unit_data: Dictionary) -> String:
	var anims = ""
	for anim in unit_data.animations:
		for dir in range(unit_data.directions):
			anims += """        {
			key: '%s_dir%d',
			frames: this.anims.generateFrameNumbers('%s', {
				start: %d,
				end: %d
			}),
			frameRate: %d,
			repeat: %d
		},\n""" % [anim.name, dir, unit_data.name,
				dir * anim.frames, (dir + 1) * anim.frames - 1,
				unit_data.fps, -1 if anim.loop else 0]
	return anims

func _generate_html_example(unit_data: Dictionary) -> String:
	return """<!DOCTYPE html>
<html>
<head>
	<title>%s Sprite Preview</title>
	<style>
		body { margin: 0; padding: 20px; background: #222; color: white; font-family: Arial; }
		#canvas { border: 1px solid #444; background: #000; }
		.controls { margin-top: 20px; }
		button { margin: 5px; padding: 10px; }
	</style>
</head>
<body>
	<h1>%s Sprite Preview</h1>
	<canvas id="canvas" width="800" height="600"></canvas>
	
	<div class="controls">
		<button onclick="changeAnimation('idle')">Idle</button>
		<button onclick="changeAnimation('walk')">Walk</button>
		<button onclick="changeAnimation('attack')">Attack</button>
		<button onclick="changeDirection(-1)">← Rotate Left</button>
		<button onclick="changeDirection(1)">Rotate Right →</button>
	</div>
	
	<script src="%s_phaser.js"></script>
	<script>
		// Simple sprite viewer implementation
		let currentAnimation = 'idle';
		let currentDirection = 0;
		let maxDirections = %d;
		
		function changeAnimation(anim) {
			currentAnimation = anim;
			updateSprite();
		}
		
		function changeDirection(delta) {
			currentDirection = (currentDirection + delta + maxDirections) %% maxDirections;
			updateSprite();
		}
		
		function updateSprite() {
			// Implementation depends on the framework used
			console.log('Animation:', currentAnimation, 'Direction:', currentDirection);
		}
	</script>
</body>
</html>""" % [unit_data.name, unit_data.name, unit_data.name, unit_data.directions]

func _generate_unity_readme(unit_name: String) -> String:
	return """Unity Integration Instructions for %s

1. Import the generated C# scripts into your Unity project
2. Place the spritesheet PNG in your Assets folder
3. Run the importer from the menu: Pixelize3D > Import %s Sprites
4. Create a ScriptableObject asset:
   - Right-click in Project window
   - Create > Pixelize3D > %s Animation Data
5. Configure the animation data in the inspector
6. Use the provided API to access sprites in your game

Example usage:
```csharp
public class %sController : MonoBehaviour
{
	public %sAnimationData animationData;
	private SpriteRenderer spriteRenderer;
	private int currentDirection = 0;
	private string currentAnimation = "idle";
	
	void Start()
	{
		spriteRenderer = GetComponent<SpriteRenderer>();
		animationData.Initialize();
	}
	
	void Update()
	{
		// Get current frame based on time
		int frame = (int)(Time.time * animationData.directions[0].animations[0].fps) %% 
				   animationData.GetAnimation(currentAnimation, currentDirection).Length;
		
		// Update sprite
		spriteRenderer.sprite = animationData.GetFrame(currentAnimation, currentDirection, frame);
	}
}
```""" % [unit_name, unit_name, unit_name, unit_name, unit_name]
