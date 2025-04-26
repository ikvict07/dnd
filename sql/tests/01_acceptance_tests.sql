-- DnD Combat System Database Schema - Acceptance Tests

CREATE OR REPLACE PROCEDURE run_acceptance_tests()
    LANGUAGE plpgsql
AS $$
DECLARE
    v_test_passed BOOLEAN;
    v_error_message TEXT;
    v_test_count INTEGER := 0;
    v_pass_count INTEGER := 0;
    v_effect_id INTEGER;
    v_attribute_id INTEGER;
BEGIN
    -- Test 1: Verify character stats summary view
    v_test_count := v_test_count + 1;
    BEGIN
        PERFORM COUNT(*) FROM character_stats_summary;
        v_test_passed := TRUE;
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'Test 1: Character Stats Summary View - PASSED';
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 1: Character Stats Summary View - FAILED: %', v_error_message;
    END;

    -- Test 2: Verify combat activity summary view
    v_test_count := v_test_count + 1;
    BEGIN
        PERFORM COUNT(*) FROM combat_activity_summary;
        v_test_passed := TRUE;
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'Test 2: Combat Activity Summary View - PASSED';
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 2: Combat Activity Summary View - FAILED: %', v_error_message;
    END;

    -- Add necessary effect records before testing procedures
    BEGIN
        -- Ensure effect templates exist
        INSERT INTO effect_template (id, effect_name, effect, duration_rounds, value, affected_attribute_type)
        VALUES
            (1, 'Burning', 'DOT', 3, 5, 'HEALTH'),
            (2, 'Freezing', 'SLOW', 2, 10, 'SPEED')
        ON CONFLICT (id) DO NOTHING;

        -- Ensure effect records exist
        INSERT INTO effect (id, effect_template_id, rounds_left)
        VALUES
            (1, 1, 3),
            (2, 2, 2)
        ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Setup: Effect records - FAILED: %', v_error_message;
    END;

    -- Test 3: Test spell casting procedure
    v_test_count := v_test_count + 1;
    BEGIN
        -- Move characters to the same location
        UPDATE character SET location_id = 2 WHERE id IN (1, 3);

        -- Set action points
        UPDATE character SET action_points = 10 WHERE id = 1;

        -- Cast spell
        PERFORM sp_cast_spell(1, 3, 3);

        -- Verify combat log was created
        IF EXISTS (SELECT 1 FROM combat_log WHERE actor_id = 1 AND target_id = 3 AND action_id = 3) THEN
            v_test_passed := TRUE;
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE 'Test 3: Spell Casting Procedure - PASSED';
        ELSE
            v_test_passed := FALSE;
            RAISE NOTICE 'Test 3: Spell Casting Procedure - FAILED: Combat log not created';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 3: Spell Casting Procedure - FAILED: %', v_error_message;
    END;

    -- Test 4: Test character rest procedure
    v_test_count := v_test_count + 1;
    BEGIN
        -- Set character HP to lower value
        UPDATE character SET hp = 50 WHERE id = 1;

        -- Move to non-combat location
        UPDATE character SET location_id = 1 WHERE id = 1;

        -- Rest
        PERFORM sp_rest_character(1);

        -- Verify HP increased
        IF (SELECT hp FROM character WHERE id = 1) > 50 THEN
            v_test_passed := TRUE;
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE 'Test 4: Character Rest Procedure - PASSED';
        ELSE
            v_test_passed := FALSE;
            RAISE NOTICE 'Test 4: Character Rest Procedure - FAILED: HP did not increase';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 4: Character Rest Procedure - FAILED: %', v_error_message;
    END;

    -- Test 5: Test item looting procedure
    v_test_count := v_test_count + 1;
    BEGIN
        -- Place item in location
        DELETE FROM inventory_items WHERE items_id = 6;
        INSERT INTO location_items_on_the_floor (location_id, items_on_the_floor_id)
        VALUES (1, 6)
        ON CONFLICT DO NOTHING;

        -- Loot item
        CALL loot_item(1, 6);

        -- Verify item is now in inventory
        IF EXISTS (
            SELECT 1 FROM inventory_items ii
                              JOIN character c ON ii.inventory_id = c.inventory_id
            WHERE ii.items_id = 6 AND c.id = 1
        ) THEN
            v_test_passed := TRUE;
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE 'Test 5: Item Looting Procedure - PASSED';
        ELSE
            v_test_passed := FALSE;
            RAISE NOTICE 'Test 5: Item Looting Procedure - FAILED: Item not moved to inventory';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 5: Item Looting Procedure - FAILED: %', v_error_message;
    END;

    -- Test 6: Test combat round management
    v_test_count := v_test_count + 1;
    BEGIN
        -- Set up combat in location 2
        UPDATE character SET location_id = 2 WHERE id IN (1, 3);

        -- Start combat
        CALL enter_combat(2);

        -- Verify round was created and AP allocated
        IF EXISTS (
            SELECT 1 FROM round r
            WHERE r.is_finished = FALSE
        ) AND (
                  SELECT action_points FROM character WHERE id = 1
              ) > 0 THEN
            v_test_passed := TRUE;
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE 'Test 6: Combat Round Management - PASSED';
        ELSE
            v_test_passed := FALSE;
            RAISE NOTICE 'Test 6: Combat Round Management - FAILED: Round not created or AP not allocated';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 6: Combat Round Management - FAILED: %', v_error_message;
    END;

    -- Test 7: Test damage calculation
    v_test_count := v_test_count + 1;
    BEGIN
        -- Calculate damage for a spell
        DECLARE
            v_damage INTEGER;
        BEGIN
            v_damage := calculate_spell_impact(1, 2, 3);

            -- Verify damage is calculated
            IF v_damage > 0 THEN
                v_test_passed := TRUE;
                v_pass_count := v_pass_count + 1;
                RAISE NOTICE 'Test 7: Damage Calculation - PASSED (Damage: %)', v_damage;
            ELSE
                v_test_passed := FALSE;
                RAISE NOTICE 'Test 7: Damage Calculation - FAILED: No damage calculated';
            END IF;
        END;
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 7: Damage Calculation - FAILED: %', v_error_message;
    END;

    -- Test 8: Test character death procedure
    v_test_count := v_test_count + 1;
    BEGIN
        -- Give character an item
        INSERT INTO inventory_items (inventory_id, items_id)
        SELECT c.inventory_id, 3
        FROM character c
        WHERE c.id = 3
        ON CONFLICT DO NOTHING;

        -- Remove from location if it exists there
        DELETE FROM location_items_on_the_floor WHERE items_on_the_floor_id = 3;

        -- Set HP to 0
        UPDATE character SET hp = 0 WHERE id = 3;

        -- Process death
        CALL process_character_death(3);

        -- Verify items dropped and inventory cleared
        IF EXISTS (
            SELECT 1 FROM location_items_on_the_floor lif
                              JOIN character c ON lif.location_id = c.location_id
            WHERE lif.items_on_the_floor_id = 3 AND c.id = 3
        ) AND NOT EXISTS (
            SELECT 1 FROM inventory_items ii
                              JOIN character c ON ii.inventory_id = c.inventory_id
            WHERE ii.items_id = 3 AND c.id = 3
        ) THEN
            v_test_passed := TRUE;
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE 'Test 8: Character Death Procedure - PASSED';
        ELSE
            v_test_passed := FALSE;
            RAISE NOTICE 'Test 8: Character Death Procedure - FAILED: Items not dropped properly';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 8: Character Death Procedure - FAILED: %', v_error_message;
    END;

    -- Test 9: Test effect application and expiration
    v_test_count := v_test_count + 1;
    BEGIN
        -- Create a test character if needed
        IF NOT EXISTS (SELECT 1 FROM character WHERE id = 4) THEN
            INSERT INTO character (id, name, hp, action_points, location_id, inventory_id, character_class_id)
            VALUES (4, 'Test Character', 100, 10, 1, 1, 1);
        END IF;

        -- Create a test effect template if needed
        IF NOT EXISTS (SELECT 1 FROM effect_template WHERE id = 3) THEN
            INSERT INTO effect_template (id, effect_name, effect, duration_rounds, value, affected_attribute_type)
            VALUES (3, 'Test Effect', 'BUFF', 2, 10, 'STRENGTH');
        END IF;

        -- Ensure character has the attribute
        IF NOT EXISTS (
            SELECT 1 FROM attribute a
            JOIN character_attributes ca ON a.id = ca.attributes_id
            WHERE ca.character_id = 4 AND a.attribute_type = 'STRENGTH'
        ) THEN
            -- Create a new attribute
            INSERT INTO attribute (id, attribute_type, value)
            VALUES (nextval('attribute_seq'), 'STRENGTH', 50)
            RETURNING id INTO v_attribute_id;

            -- Link it to the character
            INSERT INTO character_attributes (character_id, attributes_id)
            VALUES (4, v_attribute_id);
        ELSE
            -- Update existing attribute
            UPDATE attribute a
            SET value = 50
            FROM character_attributes ca
            WHERE a.id = ca.attributes_id
            AND ca.character_id = 4
            AND a.attribute_type = 'STRENGTH';
        END IF;

        -- Apply effect to character
        v_effect_id := sp_apply_effect_from_template(3, 4);

        -- Verify effect was applied and attribute was modified
        IF (
            SELECT a.value 
            FROM attribute a
            JOIN character_attributes ca ON a.id = ca.attributes_id
            WHERE ca.character_id = 4 AND a.attribute_type = 'STRENGTH'
        ) = 60 THEN
            -- Create a combat session
            INSERT INTO combat (id, location_id)
            VALUES (999, 1)
            ON CONFLICT (id) DO NOTHING;

            -- Create an initial round
            INSERT INTO round (id, index, is_finished)
            VALUES (999, 1, FALSE)
            ON CONFLICT (id) DO NOTHING;

            -- Link round to combat
            INSERT INTO combat_combat_rounds (combat_id, combat_rounds_id)
            VALUES (999, 999)
            ON CONFLICT DO NOTHING;

            -- Add character to round
            INSERT INTO round_participants (participants_id, round_id)
            VALUES (4, 999)
            ON CONFLICT DO NOTHING;

            -- Reset round (should decrement effect rounds_left)
            PERFORM sp_reset_round(999);

            -- Verify rounds_left was decremented
            IF (SELECT rounds_left FROM effect WHERE id = v_effect_id) = 1 THEN
                -- Reset round again (should remove effect)
                PERFORM sp_reset_round(999);

                -- Verify effect was removed and attribute was restored
                IF NOT EXISTS (SELECT 1 FROM effect WHERE id = v_effect_id) 
                   AND (
                       SELECT a.value 
                       FROM attribute a
                       JOIN character_attributes ca ON a.id = ca.attributes_id
                       WHERE ca.character_id = 4 AND a.attribute_type = 'STRENGTH'
                   ) = 50 THEN
                    v_test_passed := TRUE;
                    v_pass_count := v_pass_count + 1;
                    RAISE NOTICE 'Test 9: Effect Application and Expiration - PASSED';
                ELSE
                    v_test_passed := FALSE;
                    RAISE NOTICE 'Test 9: Effect Application and Expiration - FAILED: Effect not removed or attribute not restored';
                END IF;
            ELSE
                v_test_passed := FALSE;
                RAISE NOTICE 'Test 9: Effect Application and Expiration - FAILED: Effect rounds_left not decremented';
            END IF;
        ELSE
            v_test_passed := FALSE;
            RAISE NOTICE 'Test 9: Effect Application and Expiration - FAILED: Effect not applied or attribute not modified';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_test_passed := FALSE;
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Test 9: Effect Application and Expiration - FAILED: %', v_error_message;
    END;

    -- Summary
    RAISE NOTICE '------------------------------------';
    RAISE NOTICE 'Test Summary: % of % tests passed', v_pass_count, v_test_count;
    RAISE NOTICE '------------------------------------';
END;
$$;
