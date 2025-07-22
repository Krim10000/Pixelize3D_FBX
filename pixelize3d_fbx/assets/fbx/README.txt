PIXELIZE3D FBX - ESTRUCTURA DE CARPETAS
=====================================

Organiza tus archivos FBX usando esta estructura:

res://assets/fbx/
├── soldier/
│   ├── soldier_base.fbx      # Modelo con meshes y skeleton
│   ├── soldier_idle.fbx      # Animación idle
│   ├── soldier_walk.fbx      # Animación caminar
│   └── soldier_attack.fbx    # Animación atacar
├── archer/
│   ├── archer_base.fbx
│   └── archer_shoot.fbx
└── mage/
	├── mage_base.fbx
	└── mage_cast.fbx

IMPORTANTE:
- El archivo "_base.fbx" debe contener meshes + skeleton
- Los archivos de animación deben contener solo animaciones
- Los nombres de huesos deben coincidir entre archivos
- Godot importará automáticamente los archivos FBX

NOTA: Después de añadir archivos, haz clic en "🔄 Refrescar Lista"
