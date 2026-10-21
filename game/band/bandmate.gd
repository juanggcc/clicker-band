class_name Bandmate
extends Resource
## A musician who can turn up and ask to join the band. What they say is edited in the
## inspector, one .tres per musician in band/members/; the zone they turn up in points
## at it.

@export var id: StringName
@export var name: String = ""
@export_multiline var line: String = ""
## What they bring to the band; the dialog adds what each tap will be worth with them.
@export var effect: String = ""
@export var portrait: Texture2D
