-- Index for character attributes lookup (used in damage calculations)
CREATE INDEX idx_character_attributes_character_id ON character_attributes(character_id);

-- Index for character location (used in combat eligibility checks)
CREATE INDEX idx_character_location_id ON character(location_id);

-- Index for active effects on characters (used in combat calculations)
CREATE INDEX idx_character_under_effects_character_id ON character_under_effects(character_id);

-- Index for spell scaling attributes (used in damage calculations)
CREATE INDEX idx_spell_scales_from ON spell(scales_from);

-- Index for combat logs by round (used in combat history queries)
CREATE INDEX idx_round_logs_round_id ON round_logs(round_id);

-- Index for combat logs by actor (used in player performance analysis)
CREATE INDEX idx_combat_log_actor_id ON combat_log(actor_id);

-- Index for combat logs by target (used in damage received analysis)
CREATE INDEX idx_combat_log_target_id ON combat_log(target_id);

-- Index for items in inventory (used in item usage checks)
CREATE INDEX idx_inventory_items_inventory_id ON inventory_items(inventory_id);

-- Index for items on the floor in a location (used in item looting)
CREATE INDEX idx_location_items_location_id ON location_items_on_the_floor(location_id);

-- Index for rounds in a combat (used in combat flow)
CREATE INDEX idx_combat_combat_rounds_combat_id ON combat_combat_rounds(combat_id);