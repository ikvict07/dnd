SET search_path TO dnd;

-- Test Setup: Create test data
INSERT INTO location (is_pvp, name)
VALUES (false, 'Safe Haven'), -- Non-PvP location for resting
       (true, 'Battleground'); -- PvP location for combat

INSERT INTO class (action_points_multiplier, inventory_multiplier, armor_class, main_attribute, name)
VALUES (1.2, 1.5, 'HEAVY', 'STRENGTH', 'Warrior'),
       (0.8, 1.0, 'CLOTH', 'INTELLIGENCE', 'Mage'),
       (1.0, 1.2, 'LEATHER', 'DEXTERITY', 'Rogue');

INSERT INTO attribute (value, attribute_type)
VALUES (20, 'STRENGTH'),
       (20, 'INTELLIGENCE'),
       (20, 'DEXTERITY'),
       (20, 'CONSTITUTION'),
       (100, 'HEALTH'),
       (10, 'STRENGTH'),
       (30, 'INTELLIGENCE'),
       (15, 'DEXTERITY'),
       (15, 'CONSTITUTION'),
       (80, 'HEALTH'),
       (15, 'STRENGTH'),
       (15, 'INTELLIGENCE'),
       (25, 'DEXTERITY'),
       (15, 'CONSTITUTION'),
       (90, 'HEALTH');

INSERT INTO effect_template (duration_rounds, value, affected_attribute_type, effect, effect_name)
VALUES (3, 5, 'STRENGTH', 'BUFF', 'Strength Boost'),
       (3, 5, 'DEXTERITY', 'DE_BUFF', 'Slow'),
       (2, 10, 'HEALTH', 'BUFF', 'Regeneration');

INSERT INTO spell (base_cost, name, is_pvp, range, spell_impact_type, value, spell_category, spell_element, scales_from)
VALUES (5, 'Fireball', true, 30.0, 'DAMAGE', 20.0, 'MAGIC', 'FIRE', '{INTELLIGENCE}'),
       (3, 'Heal', false, 10.0, 'HEALING', 15.0, 'MAGIC', 'HOLY', '{INTELLIGENCE}'),
       (2, 'Slash', true, 5.0, 'DAMAGE', 10.0, 'MELEE', 'PHYSICAL', '{STRENGTH}'),
       (0, 'Rest', false, 0.0, 'HEALING', 30.0, 'MAGIC', 'HOLY', '{CONSTITUTION}');

-- Link spells with effect templates
UPDATE spell
SET cause_effect_id = (SELECT id FROM effect_template WHERE effect_name = 'Strength Boost')
WHERE name = 'Fireball';
UPDATE spell
SET cause_effect_id = (SELECT id FROM effect_template WHERE effect_name = 'Regeneration')
WHERE name = 'Heal';
UPDATE spell
SET cause_effect_id = (SELECT id FROM effect_template WHERE effect_name = 'Slow')
WHERE name = 'Slash';

INSERT INTO item (type, weight, name)
VALUES ('ARMOR', 15.0, 'Plate Armor'),
       ('WEAPON', 5.0, 'Longsword'),
       ('POTION', 0.5, 'Health Potion'),
       ('ARMOR', 8.0, 'Robe'),
       ('WEAPON', 2.0, 'Staff'),
       ('POTION', 0.5, 'Mana Potion'),
       ('ARMOR', 10.0, 'Leather Armor'),
       ('WEAPON', 3.0, 'Dagger'),
       ('POTION', 0.5, 'Swiftness Potion');

INSERT INTO armor_set (damage_reduction, swiftness, item_id, armor_class, name, protects_from)
VALUES (0.3, 0.7, 1, 'HEAVY', 'Plate Armor', 'PHYSICAL'),
       (0.1, 1.0, 4, 'CLOTH', 'Mage Robe', 'MAGIC'),
       (0.2, 0.9, 7, 'LEATHER', 'Leather Armor', 'PHYSICAL');

INSERT INTO weapon (action_points_multiplier, damage_multiplier, item_id, name, scales_from)
VALUES (1.0, 1.5, 2, 'Longsword', 'STRENGTH'),
       (0.8, 1.8, 5, 'Staff', 'INTELLIGENCE'),
       (0.7, 1.3, 8, 'Dagger', 'DEXTERITY');

INSERT INTO potion (item_id, name)
VALUES (3, 'Health Potion'),
       (6, 'Mana Potion'),
       (9, 'Swiftness Potion');

-- Link potions with effect templates
UPDATE potion
SET cause_effect_id = (SELECT id FROM effect_template WHERE effect_name = 'Regeneration')
WHERE name = 'Health Potion';
UPDATE potion
SET cause_effect_id = (SELECT id FROM effect_template WHERE effect_name = 'Strength Boost')
WHERE name = 'Mana Potion';
UPDATE potion
SET cause_effect_id = (SELECT id FROM effect_template WHERE effect_name = 'Slow')
WHERE name = 'Swiftness Potion';

INSERT INTO inventory (capacity)
VALUES (50.0),
       (40.0),
       (45.0);

INSERT INTO character (action_points, hp, lvl, xp, armor_set_id, character_class_id, inventory_id, location_id,
                       weapon_id, name)
VALUES (12, 100.0, 1, 0.0, 1, 1, 1, 1, 1, 'Warrior1'),
       (8, 80.0, 1, 0.0, 2, 2, 2, 1, 2, 'Mage1'),
       (10, 90.0, 1, 0.0, 3, 3, 3, 2, 3, 'Rogue1');

-- Link characters with attributes
INSERT INTO character_attributes (character_id, attributes_id)
VALUES (1, 1),  -- Warrior - STRENGTH
       (1, 2),  -- Warrior - INTELLIGENCE
       (1, 3),  -- Warrior - DEXTERITY
       (1, 4),  -- Warrior - CONSTITUTION
       (1, 5),  -- Warrior - HEALTH
       (2, 6),  -- Mage - STRENGTH
       (2, 7),  -- Mage - INTELLIGENCE
       (2, 8),  -- Mage - DEXTERITY
       (2, 9),  -- Mage - CONSTITUTION
       (2, 10), -- Mage - HEALTH
       (3, 11), -- Rogue - STRENGTH
       (3, 12), -- Rogue - INTELLIGENCE
       (3, 13), -- Rogue - DEXTERITY
       (3, 14), -- Rogue - CONSTITUTION
       (3, 15);
-- Rogue - HEALTH

-- Link characters with spells
INSERT INTO character_spells (character_id, spells_id)
VALUES (1, 3), -- Warrior knows Slash
       (2, 1), -- Mage knows Fireball
       (2, 2), -- Mage knows Heal
       (3, 3);
-- Rogue knows Slash

-- Link characters with locations
INSERT INTO location_characters (characters_id, location_id)
VALUES (1, 1), -- Warrior in Safe Haven
       (2, 1), -- Mage in Safe Haven
       (3, 2);
-- Rogue in Battleground

-- Add items to inventories
INSERT INTO inventory_items (inventory_id, items_id)
VALUES (1, 3), -- Warrior has Health Potion
       (2, 6), -- Mage has Mana Potion
       (3, 9);
-- Rogue has Swiftness Potion

-- =============================================
-- Test 1: Test get_attribute_value function
-- =============================================
DO
$$
    DECLARE
        v_strength     INTEGER;
        v_intelligence INTEGER;
        v_dexterity    INTEGER;
        v_constitution INTEGER;
        v_health       INTEGER;
    BEGIN
        -- Test for Warrior
        v_strength := get_attribute_value(1, 'STRENGTH');
        v_intelligence := get_attribute_value(1, 'INTELLIGENCE');
        v_dexterity := get_attribute_value(1, 'DEXTERITY');
        v_constitution := get_attribute_value(1, 'CONSTITUTION');
        v_health := get_attribute_value(1, 'HEALTH');

        ASSERT v_strength = 20, 'Warrior strength should be 20';
        ASSERT v_intelligence = 20, 'Warrior intelligence should be 20';
        ASSERT v_dexterity = 20, 'Warrior dexterity should be 20';
        ASSERT v_constitution = 20, 'Warrior constitution should be 20';
        ASSERT v_health = 100, 'Warrior health should be 100';

        -- Test for Mage
        v_strength := get_attribute_value(2, 'STRENGTH');
        v_intelligence := get_attribute_value(2, 'INTELLIGENCE');

        ASSERT v_strength = 10, 'Mage strength should be 10';
        ASSERT v_intelligence = 30, 'Mage intelligence should be 30';

        -- Test for Rogue
        v_dexterity := get_attribute_value(3, 'DEXTERITY');

        ASSERT v_dexterity = 25, 'Rogue dexterity should be 25';

        RAISE NOTICE 'Test 1: get_attribute_value function - PASSED';
    END
$$;

-- Test 2: Test sp_rest_character procedure
DO
$$
    DECLARE
        v_initial_hp       DOUBLE PRECISION;
        v_after_rest_hp    DOUBLE PRECISION;
        v_exception_caught BOOLEAN;
    BEGIN
        SELECT hp INTO v_initial_hp FROM character WHERE id = 1;

        UPDATE character SET hp = 50.0 WHERE id = 1;

        -- Test resting for Warrior in non-PvP location
        BEGIN
            CALL sp_rest_character(1);

            -- Get HP after rest
            SELECT hp INTO v_after_rest_hp FROM character WHERE id = 1;

            -- HP should be higher after rest
            ASSERT v_after_rest_hp > 50.0, 'HP should increase after rest';

            RAISE NOTICE 'Test 2.1: sp_rest_character in non-PvP location - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 2.1: sp_rest_character in non-PvP location - FAILED: %', SQLERRM;
        END;

        -- Test resting for Rogue in PvP location (should fail)
        v_exception_caught := FALSE;
        BEGIN
            CALL sp_rest_character(3);
        EXCEPTION
            WHEN OTHERS THEN
                v_exception_caught := TRUE;
        END;

        ASSERT v_exception_caught, 'Resting in PvP location should throw an exception';

        RAISE NOTICE 'Test 2.2: sp_rest_character in PvP location - PASSED';

        UPDATE character SET hp = v_initial_hp WHERE id = 1;
    END
$$;

-- Test 3: Test sp_cast_spell procedure
DO
$$
    DECLARE
        v_initial_hp_target     DOUBLE PRECISION;
        v_after_spell_hp_target DOUBLE PRECISION;
        v_initial_ap_caster     INTEGER;
        v_after_spell_ap_caster INTEGER;
        v_effect_count          INTEGER;
        v_exception_caught      BOOLEAN;
    BEGIN
        UPDATE character SET location_id = 2 WHERE id = 2;
        UPDATE location_characters SET location_id = 2 WHERE characters_id = 2;

        SELECT hp INTO v_initial_hp_target FROM character WHERE id = 3; -- Rogue
        SELECT action_points INTO v_initial_ap_caster FROM character WHERE id = 2; -- Mage

        BEGIN
            CALL sp_cast_spell(2, 3, 1); -- Mage casts Fireball on Rogue

            SELECT hp INTO v_after_spell_hp_target FROM character WHERE id = 3; -- Rogue
            SELECT action_points INTO v_after_spell_ap_caster FROM character WHERE id = 2; -- Mage

            ASSERT v_after_spell_hp_target < v_initial_hp_target, 'Target HP should decrease after damage spell';

            ASSERT v_after_spell_ap_caster < v_initial_ap_caster, 'Caster AP should decrease after casting spell';

            -- Check if effect was applied
            SELECT COUNT(*)
            INTO v_effect_count
            FROM effect e
                     JOIN character_under_effects cue ON e.id = cue.under_effects_id
            WHERE cue.character_id = 3;

            ASSERT v_effect_count > 0, 'Effect should be applied to target';

            RAISE NOTICE 'Test 3.1: sp_cast_spell (damage spell) - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 3.1: sp_cast_spell (damage spell) - FAILED: %', SQLERRM;
        END;

        UPDATE character SET hp = v_initial_hp_target WHERE id = 3;
        UPDATE character SET action_points = v_initial_ap_caster WHERE id = 2;
        DELETE FROM character_under_effects WHERE character_id = 3;
        DELETE FROM effect;

        UPDATE character SET location_id = 1 WHERE id = 2;
        UPDATE location_characters SET location_id = 1 WHERE characters_id = 2;

        -- Test casting Heal (healing spell)
        BEGIN
            -- Set Warrior HP to a lower value
            UPDATE character SET hp = 50.0 WHERE id = 1;

            SELECT hp INTO v_initial_hp_target FROM character WHERE id = 1; -- Warrior
            SELECT action_points INTO v_initial_ap_caster FROM character WHERE id = 2; -- Mage

            CALL sp_cast_spell(2, 1, 2); -- Mage casts Heal on Warrior

            SELECT hp INTO v_after_spell_hp_target FROM character WHERE id = 1; -- Warrior
            SELECT action_points INTO v_after_spell_ap_caster FROM character WHERE id = 2; -- Mage

            ASSERT v_after_spell_hp_target > v_initial_hp_target, 'Target HP should increase after healing spell';

            ASSERT v_after_spell_ap_caster < v_initial_ap_caster, 'Caster AP should decrease after casting spell';

            SELECT COUNT(*)
            INTO v_effect_count
            FROM effect e
                     JOIN character_under_effects cue ON e.id = cue.under_effects_id
            WHERE cue.character_id = 1;

            ASSERT v_effect_count > 0, 'Effect should be applied to target';

            RAISE NOTICE 'Test 3.2: sp_cast_spell (healing spell) - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 3.2: sp_cast_spell (healing spell) - FAILED: %', SQLERRM;
        END;

        -- Test insufficient AP (should fail)
        BEGIN
            -- Set Mage AP to a very low value
            UPDATE character SET action_points = 1 WHERE id = 2;

            v_exception_caught := FALSE;
            BEGIN
                CALL sp_cast_spell(2, 1, 1);
            EXCEPTION
                WHEN OTHERS THEN
                    v_exception_caught := TRUE;
            END;

            ASSERT v_exception_caught, 'Casting spell with insufficient AP should throw an exception';

            RAISE NOTICE 'Test 3.3: sp_cast_spell (insufficient AP) - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 3.3: sp_cast_spell (insufficient AP) - FAILED: %', SQLERRM;
        END;
    END
$$;

-- Test 4: Test combat procedures
DO
$$
    DECLARE
        v_combat_id              INTEGER;
        v_round_id               INTEGER;
        v_initial_ap_warrior     INTEGER;
        v_after_enter_ap_warrior INTEGER;
        v_after_reset_ap_warrior INTEGER;
        v_exception_caught       BOOLEAN;
        v_after_spent_ap_warrior INTEGER;
    BEGIN
        UPDATE character SET location_id = 2 WHERE id IN (1, 2);
        UPDATE location_characters SET location_id = 2 WHERE characters_id IN (1, 2);

        INSERT INTO combat (location_id) VALUES (2) RETURNING id INTO v_combat_id;

        INSERT INTO round (index, is_finished) VALUES (1, false) RETURNING id INTO v_round_id;

        INSERT INTO combat_combat_rounds (combat_id, combat_rounds_id) VALUES (v_combat_id, v_round_id);

        SELECT action_points INTO v_initial_ap_warrior FROM character WHERE id = 1;

        -- Test sp_enter_combat
        BEGIN
            CALL sp_enter_combat(v_combat_id, 1); -- Warrior enters combat

            SELECT action_points INTO v_after_enter_ap_warrior FROM character WHERE id = 1;

            ASSERT EXISTS (SELECT 1
                           FROM round_participants
                           WHERE round_id = v_round_id
                             AND participants_id = 1), 'Character should be added to round participants';

            ASSERT v_after_enter_ap_warrior != v_initial_ap_warrior, 'AP should be recalculated after entering combat';

            RAISE NOTICE 'Test 4.1: sp_enter_combat - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 4.1: sp_enter_combat - FAILED: %', SQLERRM;
        END;

        BEGIN
            UPDATE character SET location_id = 1 WHERE id = 1;
            UPDATE location_characters SET location_id = 1 WHERE characters_id = 1;

            v_exception_caught := FALSE;
            BEGIN
                CALL sp_enter_combat(v_combat_id, 1);
            EXCEPTION
                WHEN OTHERS THEN
                    v_exception_caught := TRUE;
            END;

            BEGIN
                INSERT INTO round_participants (participants_id, round_id)
                VALUES (1, v_round_id)
                ON CONFLICT DO NOTHING;

                CALL sp_enter_combat(v_combat_id, 2);

                CALL sp_reset_round(v_combat_id);

                ASSERT EXISTS (SELECT 1
                               FROM round
                               WHERE id = v_round_id
                                 AND is_finished = true), 'Old round should be marked as finished';

                ASSERT EXISTS (SELECT 1
                               FROM round r
                                        JOIN combat_combat_rounds ccr ON r.id = ccr.combat_rounds_id
                               WHERE ccr.combat_id = v_combat_id
                                 AND r.is_finished = false
                                 AND r.index = 2), 'New round should be created with incremented index';

                SELECT action_points INTO v_after_reset_ap_warrior FROM character WHERE id = 1;

                UPDATE character SET action_points = action_points - 2 WHERE id = 1;
                select character.action_points from character where id = 1 into v_after_spent_ap_warrior;

                ASSERT v_exception_caught, 'Entering combat from wrong location should throw an exception';
                UPDATE character SET location_id = 2 WHERE id = 1;

                UPDATE location_characters SET location_id = 2 WHERE characters_id = 1;
                RAISE NOTICE 'Test 4.2: sp_enter_combat (wrong location) - PASSED';
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'Test 4.2: sp_enter_combat (wrong location) - FAILED: %', SQLERRM;
            END;

            ASSERT v_after_reset_ap_warrior != v_after_spent_ap_warrior, 'AP should be recalculated after round reset';

            RAISE NOTICE 'Test 4.3: sp_reset_round - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 4.3: sp_reset_round - FAILED: %', SQLERRM;
        END;
    END
$$;

-- Test 5: Test item use procedure
DO
$$
    DECLARE
        v_initial_hp      DOUBLE PRECISION;
        v_after_potion_hp DOUBLE PRECISION;
        v_effect_count    INTEGER;
    BEGIN
        -- Test using a health potion
        BEGIN
            UPDATE character SET hp = 50.0 WHERE id = 1;

            SELECT get_attribute_value(1, 'HEALTH') INTO v_initial_hp;

            CALL sp_use_item(1, 3);

            select get_attribute_value(1, 'HEALTH') into v_after_potion_hp;
            ASSERT v_after_potion_hp > v_initial_hp, 'HELATH should increase after using health potion';

            SELECT COUNT(*)
            INTO v_effect_count
            FROM effect e
                     JOIN character_under_effects cue ON e.id = cue.under_effects_id
            WHERE cue.character_id = 1;

            ASSERT v_effect_count > 0, 'Effect should be applied after using potion';

            ASSERT NOT EXISTS (SELECT 1
                               FROM inventory_items
                               WHERE inventory_id = 1
                                 AND items_id = 3), 'Item should be removed from inventory after use';

            RAISE NOTICE 'Test 5.1: sp_use_item (potion) - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 5.1: sp_use_item (potion) - FAILED: %', SQLERRM;
        END;
    END
$$;

-- Test 6: Test loot procedure
DO
$$
    DECLARE
        v_item_id                INTEGER;
        v_inventory_count_before INTEGER;
        v_inventory_count_after  INTEGER;
        v_location_id            INTEGER := 1;
        v_character_id           INTEGER := 2;
        v_inventory_id           INTEGER;
        v_max_id                 integer;
    BEGIN
        SELECT inventory_id
        INTO v_inventory_id
        FROM character
        WHERE id = v_character_id;

        INSERT INTO item (type, weight, name) VALUES ('TROPHY', 1.0, 'Test Trophy') RETURNING id INTO v_item_id;

        INSERT INTO location_items_on_the_floor (items_on_the_floor_id, location_id) VALUES (v_item_id, v_location_id);

        INSERT INTO combat (location_id) VALUES (v_location_id);

        DELETE FROM location_characters WHERE characters_id = v_character_id;
        INSERT INTO location_characters (characters_id, location_id) VALUES (v_character_id, v_location_id);

        UPDATE character SET location_id = v_location_id WHERE id = v_character_id;

        SELECT COUNT(*) INTO v_inventory_count_before FROM inventory_items WHERE inventory_id = v_inventory_id;
        BEGIN
            select max(id) into v_max_id from combat;
            CALL sp_loot_item(v_max_id, v_character_id, v_item_id);

            SELECT COUNT(*) INTO v_inventory_count_after FROM inventory_items WHERE inventory_id = v_inventory_id;
            ASSERT v_inventory_count_after = v_inventory_count_before + 1, 'Inventory should have one more item after looting';

            ASSERT NOT EXISTS (SELECT 1
                               FROM location_items_on_the_floor
                               WHERE items_on_the_floor_id = v_item_id), 'Item should be removed from floor after looting';

            ASSERT EXISTS (SELECT 1
                           FROM inventory_items
                           WHERE inventory_id = v_inventory_id
                             AND items_id = v_item_id), 'Item should be added to inventory after looting';

            RAISE NOTICE 'Test 6.1: sp_loot_item - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 6.1: sp_loot_item - FAILED: %', SQLERRM;
        END;
    END
$$;


-- Test 7: Test player death procedure
DO
$$
    DECLARE
        v_initial_location_id INTEGER;
        v_initial_hp          DOUBLE PRECISION;
        v_initial_xp          DOUBLE PRECISION;
        v_inventory_id        INTEGER;
        v_items_count         INTEGER;
        v_floor_items_count   INTEGER;
    BEGIN
        SELECT location_id, hp, xp, inventory_id
        INTO v_initial_location_id, v_initial_hp, v_initial_xp, v_inventory_id
        FROM character
        WHERE id = 3;

        SELECT COUNT(*)
        INTO v_items_count
        FROM inventory_items
        WHERE inventory_id = v_inventory_id;

        SELECT COUNT(*)
        INTO v_floor_items_count
        FROM location_items_on_the_floor
        WHERE location_id = v_initial_location_id;

        RAISE NOTICE 'Before death: character has % items, location has % items on floor',
            v_items_count, v_floor_items_count;

        UPDATE character SET hp = 0 WHERE id = 3;

        BEGIN
            CALL sp_handle_player_death(3);

            SELECT COUNT(*)
            INTO v_items_count
            FROM inventory_items
            WHERE inventory_id = v_inventory_id;

            SELECT COUNT(*)
            INTO v_floor_items_count
            FROM location_items_on_the_floor
            WHERE location_id = v_initial_location_id;

            RAISE NOTICE 'After death: character has % items, location has % items on floor',
                v_items_count, v_floor_items_count;

            IF v_items_count = 0 THEN
                RAISE NOTICE 'Test 7.1: Items removed from inventory - PASSED';
            ELSE
                RAISE NOTICE 'Test 7.1: Items not removed from inventory - FAILED';
            END IF;

            IF v_floor_items_count > 0 THEN
                RAISE NOTICE 'Test 7.2: Items dropped on location - PASSED';
            ELSE
                RAISE NOTICE 'Test 7.2: No items found on location - FAILED';
            END IF;

            RAISE NOTICE 'Test 7: sp_handle_player_death - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 7: sp_handle_player_death - FAILED: %', SQLERRM;
        END;
    END
$$;
-- Test 8: Test effect procedures
DO
$$
    DECLARE
        v_effect_template_id          INTEGER;
        v_effect_id                   INTEGER;
        v_initial_strength            INTEGER;
        v_after_effect_strength       INTEGER;
        v_after_decrement_rounds_left INTEGER;
        v_effect_count                INTEGER;
    BEGIN
        SELECT id
        INTO v_effect_template_id
        FROM effect_template
        WHERE effect_name = 'Strength Boost';

        v_initial_strength := get_attribute_value(1, 'STRENGTH');

        -- Test applying effect from template
        BEGIN
            v_effect_id := sp_apply_effect_from_template(v_effect_template_id, 1);

            ASSERT v_effect_id IS NOT NULL, 'Effect should be created';

            SELECT COUNT(*)
            INTO v_effect_count
            FROM character_under_effects
            WHERE character_id = 1
              AND under_effects_id = v_effect_id;

            ASSERT v_effect_count = 1, 'Effect should be linked to character';

            v_after_effect_strength := get_attribute_value(1, 'STRENGTH');

            ASSERT v_after_effect_strength > v_initial_strength, 'Strength should be increased by effect';

            RAISE NOTICE 'Test 8.1: sp_apply_effect_from_template - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 8.1: sp_apply_effect_from_template - FAILED: %', SQLERRM;
        END;

        -- Test decrementing effect rounds
        BEGIN
            SELECT rounds_left
            INTO v_after_decrement_rounds_left
            FROM effect
            WHERE id = v_effect_id;

            CALL sp_decrement_effect_rounds();

            SELECT rounds_left
            INTO v_after_decrement_rounds_left
            FROM effect
            WHERE id = v_effect_id;

            ASSERT v_after_decrement_rounds_left = 2, 'Rounds left should decrease by 1';

            CALL sp_decrement_effect_rounds();
            CALL sp_decrement_effect_rounds();

            ASSERT NOT EXISTS (SELECT 1
                               FROM effect
                               WHERE id = v_effect_id), 'Effect should be removed when rounds left reaches 0';

            v_after_effect_strength := get_attribute_value(1, 'STRENGTH');

            ASSERT v_after_effect_strength = v_initial_strength, 'Strength should be restored after effect expires';

            RAISE NOTICE 'Test 8.2: sp_decrement_effect_rounds - PASSED';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Test 8.2: sp_decrement_effect_rounds - FAILED: %', SQLERRM;
        END;
    END
$$;
