-- DnD Combat System Database Schema - Example Data

-- Insert classes
INSERT INTO class (id, name, main_attribute, armor_class, inventory_multiplier, action_points_multiplier)
VALUES 
    (nextval('class_seq'), 'Warrior', 'STRENGTH', 'HEAVY', 1.2, 0.8),
    (nextval('class_seq'), 'Mage', 'INTELLIGENCE', 'CLOTH', 0.8, 1.2),
    (nextval('class_seq'), 'Rogue', 'DEXTERITY', 'LEATHER', 1.0, 1.0),
    (nextval('class_seq'), 'Cleric', 'HEALTH', 'HEAVY', 1.0, 1.0);

-- Insert locations
INSERT INTO location (id, name, is_pvp)
VALUES 
    (nextval('location_seq'), 'Peaceful Village', FALSE),
    (nextval('location_seq'), 'Dark Forest', TRUE),
    (nextval('location_seq'), 'Ancient Ruins', FALSE),
    (nextval('location_seq'), 'Battleground', TRUE);

-- Insert effect templates
INSERT INTO effect_template (id, effect_name, effect, affected_attribute_type, value, duration_rounds)
VALUES 
    (nextval('effect_template_seq'), 'Strength Boost', 'BUFF', 'STRENGTH', 10, 3),
    (nextval('effect_template_seq'), 'Intelligence Drain', 'DE_BUFF', 'INTELLIGENCE', -5, 2),
    (nextval('effect_template_seq'), 'Health Regeneration', 'BUFF', 'HEALTH', 5, 5),
    (nextval('effect_template_seq'), 'Dexterity Boost', 'BUFF', 'DEXTERITY', 8, 3);

-- Insert spells
INSERT INTO spell (id, name, base_cost, is_pvp, spell_category, spell_element, scales_from, spell_impact_type, range, value, cause_effect_id)
VALUES 
    (nextval('spell_seq'), 'Fireball', 5, TRUE, 'MAGIC', 'FIRE', 'INTELLIGENCE', 1, 10.0, 25.0, NULL),
    (nextval('spell_seq'), 'Healing Light', 4, FALSE, 'MAGIC', 'HOLY', 'HEALTH', 2, 5.0, 20.0, NULL),
    (nextval('spell_seq'), 'Poison Strike', 3, TRUE, 'MELEE', 'POISON', 'DEXTERITY,STRENGTH', 1, 2.0, 15.0, 2),
    (nextval('spell_seq'), 'Blessing', 6, FALSE, 'MAGIC', 'HOLY', 'HEALTH,INTELLIGENCE', 2, 8.0, 15.0, 3),
    (nextval('spell_seq'), 'Thunder Strike', 7, TRUE, 'RANGED', 'THUNDER', 'DEXTERITY', 1, 15.0, 30.0, NULL);

-- Insert items
INSERT INTO item (id, name, type, weight)
VALUES 
    (nextval('item_seq'), 'Steel Sword', 1, 5.0),
    (nextval('item_seq'), 'Leather Armor', 0, 8.0),
    (nextval('item_seq'), 'Health Potion', 2, 0.5),
    (nextval('item_seq'), 'Magic Staff', 1, 3.0),
    (nextval('item_seq'), 'Plate Armor', 0, 15.0),
    (nextval('item_seq'), 'Dragon Scale', 3, 2.0);

-- Insert weapons
INSERT INTO weapon (id, name, damage_multiplier, action_points_multiplier, scales_from, item_id)
VALUES 
    (nextval('weapon_seq'), 'Steel Sword', 1.2, 0.9, 'STRENGTH', 1),
    (nextval('weapon_seq'), 'Magic Staff', 1.5, 0.8, 'INTELLIGENCE', 4);

-- Insert armor sets
INSERT INTO armor_set (id, name, damage_reduction, swiftness, armor_class, protects_from, item_id)
VALUES 
    (nextval('armor_set_seq'), 'Leather Armor', 0.8, 0.2, 'LEATHER', 'PHYSICAL', 2),
    (nextval('armor_set_seq'), 'Plate Armor', 1.5, 0.5, 'HEAVY', 'FIRE', 5);

-- Insert potions
INSERT INTO potion (id, name, cause_effect_id, item_id)
VALUES 
    (nextval('item_seq'), 'Health Potion', 3, 3);

-- Insert inventories
INSERT INTO inventory (id, capacity)
VALUES 
    (nextval('inventory_seq'), 50.0),
    (nextval('inventory_seq'), 40.0),
    (nextval('inventory_seq'), 45.0);

-- Insert characters
INSERT INTO character (id, name, hp, lvl, xp, action_points, character_class_id, inventory_id, location_id, weapon_id, armor_set_id)
VALUES 
    (nextval('character_seq'), 'Aragorn', 100.0, 5, 2500.0, 10, 1, 1, 1, 1, 1),
    (nextval('character_seq'), 'Gandalf', 80.0, 8, 5000.0, 12, 2, 2, 1, 2, NULL),
    (nextval('character_seq'), 'Goblin', 50.0, 3, 1000.0, 8, 3, 3, 2, NULL, NULL);

-- Insert attributes
INSERT INTO attribute (id, attribute_type, value)
VALUES 
    (nextval('attribute_seq'), 'STRENGTH', 20),
    (nextval('attribute_seq'), 'INTELLIGENCE', 10),
    (nextval('attribute_seq'), 'DEXTERITY', 15),
    (nextval('attribute_seq'), 'CONSTITUTION', 18),
    (nextval('attribute_seq'), 'HEALTH', 25),
    (nextval('attribute_seq'), 'INTELLIGENCE', 25),
    (nextval('attribute_seq'), 'STRENGTH', 8),
    (nextval('attribute_seq'), 'DEXTERITY', 12),
    (nextval('attribute_seq'), 'CONSTITUTION', 10),
    (nextval('attribute_seq'), 'HEALTH', 15),
    (nextval('attribute_seq'), 'STRENGTH', 12),
    (nextval('attribute_seq'), 'DEXTERITY', 18),
    (nextval('attribute_seq'), 'INTELLIGENCE', 5);

-- Link attributes to characters
INSERT INTO character_attributes (character_id, attributes_id)
VALUES 
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
    (2, 6), (2, 7), (2, 8), (2, 9), (2, 10),
    (3, 11), (3, 12), (3, 13);

-- Link spells to characters
INSERT INTO character_spells (character_id, spells_id)
VALUES 
    (1, 3), (1, 2),
    (2, 1), (2, 2), (2, 4), (2, 5),
    (3, 3);

-- Create a combat round
INSERT INTO round (id, index, is_finished)
VALUES 
    (nextval('combat_seq'), 1, FALSE);

-- Link characters to the round
INSERT INTO round_participants (round_id, participants_id)
VALUES 
    (1, 2), (1, 3);

-- Create combat logs
INSERT INTO combat_log (id, actor_id, action_id, target_id, action_points_spent, impact, caused_effect_id, description)
VALUES 
    (nextval('combat_seq'), 2, 1, 3, 5, 35, NULL, 'Gandalf cast Fireball on Goblin - Hit for 35 damage');
