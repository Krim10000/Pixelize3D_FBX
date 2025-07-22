# Pixelize3D FBX - Generador de Spritesheets

Herramienta standalone desarrollada en Godot 4.4 para convertir modelos FBX en spritesheets optimizados para juegos RTS isométricos.

## Características

- ✅ Carga de archivos FBX con estructura específica (base + animaciones)
- ✅ Renderizado en 16 o 32 direcciones configurables
- ✅ Generación de spritesheets por animación
- ✅ Metadata JSON con información de frames
- ✅ Preview en tiempo real
- ✅ Configuración de cámara isométrica ajustable
- ✅ Exportación PNG con transparencia
- ✅ Efecto de pixelización opcional

## Estructura de Archivos FBX

### Archivo Base
```
archivo_base.fbx
├── Node3D (raíz)
├── Skeleton3D
│   ├── MeshInstance3D (mesh1)
│   ├── MeshInstance3D (mesh2)
│   └── MeshInstance3D (...)
└── AnimationPlayer (no usado)
```

### Archivo de Animación
```
archivo_animacion.fbx
├── Node3D (raíz)
├── Skeleton3D (sin meshes)
└── AnimationPlayer (con animaciones)
```

## Instalación

1. Clona o descarga el proyecto
2. Abre Godot 4.4
3. Importa el proyecto
4. Ejecuta la escena principal o exporta como aplicación standalone

## Uso

### 1. Preparación de Archivos

Organiza tus archivos FBX en carpetas por unidad:
```
UnidadEjemplo/
├── soldado_base.fbx      # Modelo con meshes
├── soldado_idle.fbx       # Animación idle
├── soldado_walk.fbx       # Animación caminar
├── soldado_attack.fbx     # Animación atacar
└── soldado_death.fbx      # Animación muerte
```

### 2. Proceso de Generación

1. **Seleccionar Carpeta**: Click en "Examinar" y selecciona la carpeta de la unidad
2. **Elegir Modelo Base**: Selecciona el FBX que contiene los meshes
3. **Seleccionar Animaciones**: Marca las animaciones a procesar
4. **Configurar Parámetros**:
   - Direcciones: 16 (recomendado) o 32
   - Tamaño de sprite: 256x256 (ajustable)
   - FPS: 12 (típico para RTS)
   - Ángulo de cámara: 45° (isométrico estándar)
5. **Preview** (opcional): Visualiza el modelo antes de renderizar
6. **Renderizar**: Inicia el proceso de generación

### 3. Archivos de Salida

La herramienta genera en la carpeta `exports/`:

```
exports/
├── soldado_idle_spritesheet.png
├── soldado_idle_metadata.json
├── soldado_walk_spritesheet.png
├── soldado_walk_metadata.json
├── soldado_attack_spritesheet.png
└── soldado_attack_metadata.json
```

## Formato del Spritesheet

Los spritesheets se organizan con:
- Una fila por dirección de vista
- Frames de animación en columnas
- Orden: empezando desde el norte, rotando en sentido horario

```
Dirección 0  : [Frame0][Frame1][Frame2]...
Dirección 1  : [Frame0][Frame1][Frame2]...
Dirección 2  : [Frame0][Frame1][Frame2]...
...
```

## Metadata JSON

Cada spritesheet incluye un archivo JSON con:

```json
{
  "name": "soldado_walk",
  "sprite_size": {
    "width": 256,
    "height": 256
  },
  "spritesheet_size": {
    "width": 3072,
    "height": 4096
  },
  "directions": [
    {
      "index": 0,
      "angle": 0.0,
      "frame_count": 12,
      "frames": [...]
    }
  ],
  "fps": 12,
  "total_frames": 192
}
```

## Configuración Avanzada

### Cámara Isométrica
- **Ángulo**: 30-60° (45° estándar)
- **Altura**: Ajusta la elevación de la cámara
- **Distancia**: Controla el zoom

### Renderizado
- **Pixelización**: Activa/desactiva el efecto retro
- **Reducción de colores**: Limita la paleta de colores
- **Tamaño de pixel**: Escala del efecto de pixelización

## Solución de Problemas

### El modelo no se carga
- Verifica que el FBX base contenga Skeleton3D con MeshInstance3D
- Asegúrate de que el archivo no esté corrupto

### Las animaciones no funcionan
- Confirma que el FBX de animación tenga AnimationPlayer
- Verifica que los nombres de huesos coincidan con el modelo base

### El spritesheet está vacío
- Revisa la configuración de la cámara
- Asegúrate de que el modelo esté dentro del rango de vista

## Exportación como Aplicación

Para crear un ejecutable standalone:

1. En Godot: Proyecto → Exportar
2. Añade un preset para tu plataforma
3. Configura las opciones de exportación
4. Exporta el ejecutable

## Requisitos del Sistema

- **Mínimos**: 4GB RAM, GPU con OpenGL 3.3
- **Recomendados**: 8GB RAM, GPU dedicada
- **SO**: Windows 10+, macOS 10.15+, Linux (Ubuntu 20.04+)

## Licencia

Este proyecto es una adaptación de pixelize3d para trabajar con archivos FBX.

## Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## Contacto

Para reportar bugs o sugerir mejoras, abre un issue en el repositorio.