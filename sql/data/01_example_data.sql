-- DnD Combat System Database Schema - Example Data

-- Insert classes
INSERT INTO class (name, main_attribute, armor_class, inventory_multiplier, action_points_multiplier)
VALUES ('Warrior', 'STRENGTH', 'HEAVY', 1.2, 0.8),
       ('Mage', 'INTELLIGENCE', 'CLOTH', 0.8, 1.2),
       ('Rogue', 'DEXTERITY', 'LEATHER', 1.0, 1.0),
       ('Cleric', 'HEALTH', 'HEAVY', 1.0, 1.0);

-- Insert locations
INSERT INTO location (name, is_pvp)
VALUES ('Peaceful Village', FALSE),
       ('Dark Forest', TRUE),
       ('Ancient Ruins', FALSE),
       ('Battleground', TRUE);

-- Insert effect templates
INSERT INTO effect_template (effect_name, effect, affected_attribute_type, value, duration_rounds)
VALUES ('Strength Boost', 'BUFF', 'STRENGTH', 10, 3),
       ('Intelligence Drain', 'DE_BUFF', 'INTELLIGENCE', -5, 2),
       ('Health Regeneration', 'BUFF', 'HEALTH', 5, 5),
       ('Dexterity Boost', 'BUFF', 'DEXTERITY', 8, 3);

-- Insert spells
INSERT INTO spell (name, base_cost, is_pvp, spell_category, spell_element, scales_from, spell_impact_type, range, value,
                   cause_effect_id)
VALUES ('Fireball', 5, TRUE, 'MAGIC', 'FIRE', '{INTELLIGENCE}'::attribute_type[], 'DAMAGE', 10.0, 25.0, NULL),
       ('Healing Light', 4, FALSE, 'MAGIC', 'HOLY', '{HEALTH}'::attribute_type[], 'HEALING', 5.0, 20.0, NULL),
       ('Poison Strike', 3, TRUE, 'MELEE', 'POISON', '{DEXTERITY,STRENGTH}'::attribute_type[], 'DAMAGE', 2.0, 15.0, 2),
       ('Blessing', 6, FALSE, 'MAGIC', 'HOLY', '{HEALTH,INTELLIGENCE}'::attribute_type[], 'HEALING', 8.0, 15.0, 3),
       ('Thunder Strike', 7, TRUE, 'RANGED', 'THUNDER', '{DEXTERITY}'::attribute_type[], 'DAMAGE', 15.0, 30.0, NULL);

-- Insert items
INSERT INTO item (name, type, weight)
VALUES ('Steel Sword', 'WEAPON', 5.0),
       ('Leather Armor', 'ARMOR', 8.0),
       ('Health Potion', 'POTION', 0.5),
       ('Magic Staff', 'WEAPON', 3.0),
       ('Plate Armor', 'ARMOR', 15.0),
       ('Dragon Scale', 'TROPHY', 2.0);

-- Insert weapons
INSERT INTO weapon (name, damage_multiplier, action_points_multiplier, scales_from, item_id)
VALUES ('Steel Sword', 1.2, 0.9, '{STRENGTH}', 1),
       ('Magic Staff', 1.5, 0.8, '{INTELLIGENCE}', 4);

-- Insert armor sets
INSERT INTO armor_set (name, damage_reduction, swiftness, armor_class, protects_from, item_id)
VALUES ('Leather Armor', 0.8, 0.2, 'LEATHER', 'PHYSICAL', 2),
       ('Plate Armor', 1.5, 0.5, 'HEAVY', 'FIRE', 5);

-- Insert potions
INSERT INTO potion (name, cause_effect_id, item_id)
VALUES ('Health Potion', 3, 3);

-- Insert inventories
INSERT INTO inventory (capacity)
VALUES (50.0),
       (40.0),
       (45.0);

-- Add Steel Sword to Aragorn's inventory
INSERT INTO inventory_items (inventory_id, items_id)
VALUES (1, 1);

-- Add Health Potion to Aragorn's inventory
INSERT INTO inventory_items (inventory_id, items_id)
VALUES (1, 3);

-- Add Magic Staff to Gandalf's inventory
INSERT INTO inventory_items (inventory_id, items_id)
VALUES (2, 4);


-- Insert characters
INSERT INTO character (name, hp, lvl, xp, action_points, character_class_id, inventory_id, location_id, weapon_id,
                       armor_set_id)
VALUES ('Aragorn', 100.0, 5, 2500.0, 10, 1, 1, 1, 1, 1),
       ('Gandalf', 80.0, 8, 5000.0, 12, 2, 2, 1, 2, NULL),
       ('Goblin', 50.0, 3, 1000.0, 8, 3, 3, 2, NULL, NULL);

-- Insert attributes
INSERT INTO attribute (attribute_type, value)
VALUES ('STRENGTH', 20),
       ('INTELLIGENCE', 10),
       ('DEXTERITY', 15),
       ('CONSTITUTION', 18),
       ('HEALTH', 25),
       ('INTELLIGENCE', 25),
       ('STRENGTH', 8),
       ('DEXTERITY', 12),
       ('CONSTITUTION', 10),
       ('HEALTH', 15),
       ('STRENGTH', 12),
       ('DEXTERITY', 18),
       ('INTELLIGENCE', 5),
       ('CONSTITUTION', 20),
       ('HEALTH', 30);
;

-- Link attributes to characters
INSERT INTO character_attributes (character_id, attributes_id)
VALUES (1, 1),
       (1, 2),
       (1, 3),
       (1, 4),
       (1, 5),
       (2, 6),
       (2, 7),
       (2, 8),
       (2, 9),
       (2, 10),
       (3, 11),
       (3, 12),
       (3, 13),
       (3, 14),
       (3, 15);

-- Link spells to characters
INSERT INTO character_spells (character_id, spells_id)
VALUES (1, 3),
       (1, 2),
       (2, 1),
       (2, 2),
       (2, 4),
       (2, 5),
       (3, 3);

-- Create a combat round
INSERT INTO round (index, is_finished)
VALUES (1, FALSE);

-- Create a combat
insert into combat (location_id)
values (1);

-- Link logs to combat
insert into combat_combat_rounds(combat_id, combat_rounds_id)
VALUES (1, 1);


-- Link characters to the round
INSERT INTO round_participants (round_id, participants_id)
VALUES (1, 2),
       (1, 3),
       (1, 1);
