class_name TerritoryDefinition
extends Resource
## Territory data template (Phase 2B). A region is either bound to a city
## (owner follows the city's ownership) or fixed (base territories).
## Geometry is a pre-defined axis-aligned quad: no procedural generation,
## no runtime Voronoi. Aether income goes to the owning side.

const FOLLOW_CITY: int = -1

@export var id: StringName = &"west"
@export var display_name: String = "West Territory"
@export var description: String = ""

@export_group("Ownership")
## City id this region follows, or empty for fixed base territories.
@export var linked_city_id: StringName = &""
## FOLLOW_CITY (-1) = follow linked city. Otherwise 0/1/2 fixed owner
## (same numbering as RTSCity.Owner: NEUTRAL/PLAYER/ENEMY).
@export var fixed_owner: int = FOLLOW_CITY

@export_group("Aether")
@export var aether_income_bonus: float = 0.35 # Aether per second for the owner

@export_group("Layout")
@export var center: Vector3 = Vector3.ZERO
@export var size: Vector2 = Vector2(24, 22) # meters, XZ quad
@export var neighbor_ids: Array[String] = []
