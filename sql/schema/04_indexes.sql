-- index for character attributes lookup (used in damage calculations)
create index idx_character_attributes_character_id on character_attributes(character_id);

-- index for character location (used in combat eligibility checks)
create index idx_character_location_id on character(location_id);

-- index for active effects on characters (used in combat calculations)
create index idx_character_under_effects_character_id on character_under_effects(character_id);

-- index for spell scaling attributes (used in damage calculations)
create index idx_spell_scales_from on spell(scales_from);

-- index for combat logs by round (used in combat history queries)
create index idx_round_logs_round_id on round_logs(round_id);

-- index for combat logs by actor (used in player performance analysis)
create index idx_combat_log_actor_id on combat_log(actor_id);

-- index for combat logs by target (used in damage received analysis)
create index idx_combat_log_target_id on combat_log(target_id);

-- index for items in inventory (used in item usage checks)
create index idx_inventory_items_inventory_id on inventory_items(inventory_id);

-- index for items on the floor in a location (used in item looting)
create index idx_location_items_location_id on location_items_on_the_floor(location_id);

-- index for rounds in a combat (used in combat flow)
create index idx_combat_combat_rounds_combat_id on combat_combat_rounds(combat_id);