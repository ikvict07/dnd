insert into class (name, main_attribute, armor_class, inventory_multiplier, action_points_multiplier)
values ('warrior', 'strength', 'heavy', 1.2, 0.8),
       ('mage', 'intelligence', 'cloth', 0.8, 1.2),
       ('rogue', 'dexterity', 'leather', 1.0, 1.0),
       ('cleric', 'health', 'heavy', 1.0, 1.0);

insert into location (name, is_pvp)
values ('peaceful village', false),
       ('dark forest', true),
       ('ancient ruins', false),
       ('battleground', true);

insert into effect_template (effect_name, effect, affected_attribute_type, value, duration_rounds)
values ('strength boost', 'buff', 'strength', 10, 3),
       ('intelligence drain', 'de_buff', 'intelligence', -5, 2),
       ('health regeneration', 'buff', 'health', 5, 5),
       ('dexterity boost', 'buff', 'dexterity', 8, 3);

insert into spell (name, base_cost, is_pvp, spell_category, spell_element, scales_from, spell_impact_type, range, value,
                   cause_effect_id)
values ('fireball', 5, true, 'magic', 'fire', '{intelligence}'::attribute_type[], 'damage', 10.0, 25.0, null),
       ('healing light', 4, false, 'magic', 'holy', '{health}'::attribute_type[], 'healing', 5.0, 20.0, null),
       ('poison strike', 3, true, 'melee', 'poison', '{dexterity,strength}'::attribute_type[], 'damage', 2.0, 15.0, 2),
       ('blessing', 6, false, 'magic', 'holy', '{health,intelligence}'::attribute_type[], 'healing', 8.0, 15.0, 3),
       ('thunder strike', 7, true, 'ranged', 'thunder', '{dexterity}'::attribute_type[], 'damage', 15.0, 30.0, null);

insert into item (name, type, weight)
values ('steel sword', 'weapon', 5.0),
       ('leather armor', 'armor', 8.0),
       ('health potion', 'potion', 0.5),
       ('magic staff', 'weapon', 3.0),
       ('plate armor', 'armor', 15.0),
       ('dragon scale', 'trophy', 2.0);

insert into weapon (name, damage_multiplier, action_points_multiplier, scales_from, item_id)
values ('steel sword', 1.2, 0.9, '{strength}', 1),
       ('magic staff', 1.5, 0.8, '{intelligence}', 4);
insert into armor_set (name, damage_reduction, swiftness, armor_class, protects_from, item_id)
values ('leather armor', 0.8, 0.2, 'leather', 'physical', 2),
       ('plate armor', 1.5, 0.5, 'heavy', 'fire', 5);

insert into potion (name, cause_effect_id, item_id)
values ('health potion', 3, 3);
insert into inventory (capacity)
values (50.0),
       (40.0),
       (45.0);

insert into inventory_items (inventory_id, items_id)
values (1, 1);

insert into inventory_items (inventory_id, items_id)
values (1, 3);

insert into inventory_items (inventory_id, items_id)
values (2, 4);


insert into character (name, hp, lvl, xp, action_points, character_class_id, inventory_id, location_id, weapon_id,
                       armor_set_id)
values ('aragorn', 100.0, 5, 2500.0, 10, 1, 1, 1, 1, 1),
       ('gandalf', 80.0, 8, 5000.0, 12, 2, 2, 1, 2, null),
       ('goblin', 50.0, 3, 1000.0, 8, 3, 3, 2, null, null);

insert into attribute (attribute_type, value)
values ('strength', 20),
       ('intelligence', 10),
       ('dexterity', 15),
       ('constitution', 18),
       ('health', 25),
       ('intelligence', 25),
       ('strength', 8),
       ('dexterity', 12),
       ('constitution', 10),
       ('health', 15),
       ('strength', 12),
       ('dexterity', 18),
       ('intelligence', 5),
       ('constitution', 20),
       ('health', 30);
;

insert into character_attributes (character_id, attributes_id)
values (1, 1),
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

insert into character_spells (character_id, spells_id)
values (1, 3),
       (1, 2),
       (2, 1),
       (2, 2),
       (2, 4),
       (2, 5),
       (3, 3);

insert into round (index, is_finished)
values (1, false);

insert into combat (location_id)
values (1);

insert into combat_combat_rounds(combat_id, combat_rounds_id)
values (1, 1);


insert into round_participants (round_id, participants_id)
values (1, 2),
       (1, 3),
       (1, 1);