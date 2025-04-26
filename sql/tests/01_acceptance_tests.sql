-- Test for player death procedure
-- This test creates a character with inventory and items,
-- then calls the player death procedure and verifies the results

-- Set schema
SET search_path TO dnd;

-- Define the player death procedure
CREATE OR REPLACE FUNCTION sp_handle_player_death(
    p_character_id BIGINT
) RETURNS VOID AS $$
DECLARE
    v_location_id BIGINT;
    v_inventory_id BIGINT;
    v_item_id BIGINT;
BEGIN
    -- Get character's location and inventory
    SELECT location_id, inventory_id 
    INTO v_location_id, v_inventory_id
    FROM character
    WHERE id = p_character_id;

    IF v_location_id IS NULL OR v_inventory_id IS NULL THEN
        RAISE EXCEPTION 'Character not found or missing location/inventory';
    END IF;

    -- Drop all items from character's inventory to their current location
    FOR v_item_id IN (
        SELECT items_id
        FROM inventory_items
        WHERE inventory_id = v_inventory_id
    ) LOOP
        -- Add item to location floor
        INSERT INTO location_items_on_the_floor (location_id, items_on_the_floor_id)
        VALUES (v_location_id, v_item_id);

        -- Remove item from inventory
        DELETE FROM inventory_items
        WHERE inventory_id = v_inventory_id AND items_id = v_item_id;
    END LOOP;

    -- Delete character's records in the correct order to avoid foreign key constraint violations

    -- Remove character from combat logs
    DELETE FROM combat_log_items_used
    WHERE combat_log_id IN (
        SELECT id FROM combat_log WHERE actor_id = p_character_id OR target_id = p_character_id
    );

    DELETE FROM round_logs
    WHERE logs_id IN (
        SELECT id FROM combat_log WHERE actor_id = p_character_id OR target_id = p_character_id
    );

    DELETE FROM combat_log
    WHERE actor_id = p_character_id OR target_id = p_character_id;

    -- Remove character from rounds
    DELETE FROM round_participants
    WHERE participants_id = p_character_id;

    -- Remove character's effects
    DELETE FROM character_under_effects
    WHERE character_id = p_character_id;

    -- Remove character's spells
    DELETE FROM character_spells
    WHERE character_id = p_character_id;

    -- Remove character's attributes
    DELETE FROM character_attributes
    WHERE character_id = p_character_id;

    -- Remove character from location
    DELETE FROM location_characters
    WHERE characters_id = p_character_id;

    -- Finally, delete the character record
    DELETE FROM character
    WHERE id = p_character_id;

    -- Delete the character's inventory
    DELETE FROM inventory
    WHERE id = v_inventory_id;
END;
$$ LANGUAGE plpgsql;

-- Create test data
DO $$
DECLARE
    v_location_id BIGINT;
    v_inventory_id BIGINT;
    v_character_id BIGINT;
    v_item_id1 BIGINT;
    v_item_id2 BIGINT;
    v_attribute_id BIGINT;
    v_items_on_floor INTEGER;
    v_character_exists BOOLEAN;
BEGIN
    -- Create a test location
    INSERT INTO location (id, is_pvp, name)
    VALUES (nextval('location_seq'), FALSE, 'Test Location')
    RETURNING id INTO v_location_id;

    -- Create a test inventory
    INSERT INTO inventory (id, capacity)
    VALUES (nextval('inventory_seq'), 100.0)
    RETURNING id INTO v_inventory_id;

    -- Create test items
    INSERT INTO item (id, type, weight, name)
    VALUES (nextval('item_seq'), 1, 5.0, 'Test Item 1')
    RETURNING id INTO v_item_id1;

    INSERT INTO item (id, type, weight, name)
    VALUES (nextval('item_seq'), 1, 3.0, 'Test Item 2')
    RETURNING id INTO v_item_id2;

    -- Create a test attribute
    INSERT INTO attribute (id, value, attribute_type)
    VALUES (nextval('attribute_seq'), 10, 'STRENGTH')
    RETURNING id INTO v_attribute_id;

    -- Create a test character
    INSERT INTO character (id, action_points, hp, lvl, xp, inventory_id, location_id, name)
    VALUES (nextval('character_seq'), 10, 100.0, 1, 0.0, v_inventory_id, v_location_id, 'Test Character')
    RETURNING id INTO v_character_id;

    -- Add character to location
    INSERT INTO location_characters (characters_id, location_id)
    VALUES (v_character_id, v_location_id);

    -- Add attribute to character
    INSERT INTO character_attributes (character_id, attributes_id)
    VALUES (v_character_id, v_attribute_id);

    -- Add items to inventory
    INSERT INTO inventory_items (inventory_id, items_id)
    VALUES (v_inventory_id, v_item_id1);

    INSERT INTO inventory_items (inventory_id, items_id)
    VALUES (v_inventory_id, v_item_id2);

    -- Verify setup
    RAISE NOTICE 'Test setup complete. Character ID: %, Location ID: %, Inventory ID: %', 
                 v_character_id, v_location_id, v_inventory_id;

    -- Call the player death procedure
    PERFORM sp_handle_player_death(v_character_id);

    -- Verify that items are now on the floor at the location
    SELECT COUNT(*) INTO v_items_on_floor
    FROM location_items_on_the_floor
    WHERE location_id = v_location_id;

    IF v_items_on_floor = 2 THEN
        RAISE NOTICE 'Items successfully dropped on the floor: %', v_items_on_floor;
    ELSE
        RAISE EXCEPTION 'Expected 2 items on the floor, but found %', v_items_on_floor;
    END IF;

    -- Verify that character no longer exists
    SELECT EXISTS(SELECT 1 FROM character WHERE id = v_character_id) INTO v_character_exists;

    IF v_character_exists THEN
        RAISE EXCEPTION 'Character still exists after death procedure';
    ELSE
        RAISE NOTICE 'Character successfully deleted';
    END IF;

    -- Verify that inventory no longer exists
    IF EXISTS(SELECT 1 FROM inventory WHERE id = v_inventory_id) THEN
        RAISE EXCEPTION 'Inventory still exists after death procedure';
    ELSE
        RAISE NOTICE 'Inventory successfully deleted';
    END IF;

    -- Verify that character attributes no longer exist
    IF EXISTS(SELECT 1 FROM character_attributes WHERE character_id = v_character_id) THEN
        RAISE EXCEPTION 'Character attributes still exist after death procedure';
    ELSE
        RAISE NOTICE 'Character attributes successfully deleted';
    END IF;

    -- Verify that character is no longer in location_characters
    IF EXISTS(SELECT 1 FROM location_characters WHERE characters_id = v_character_id) THEN
        RAISE EXCEPTION 'Character still in location_characters after death procedure';
    ELSE
        RAISE NOTICE 'Character successfully removed from location_characters';
    END IF;

    -- Clean up test data
    DELETE FROM location_items_on_the_floor WHERE location_id = v_location_id;
    DELETE FROM attribute WHERE id = v_attribute_id;
    DELETE FROM item WHERE id IN (v_item_id1, v_item_id2);
    DELETE FROM location WHERE id = v_location_id;

    RAISE NOTICE 'Test completed successfully';
END $$;
