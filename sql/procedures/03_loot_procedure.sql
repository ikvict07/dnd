-- Function to handle a character looting an item from a combat area
CREATE OR REPLACE FUNCTION sp_loot_item(
    p_combat_id INTEGER,
    p_character_id INTEGER,
    p_item_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_character_location_id INTEGER;
    v_inventory_id INTEGER;
    v_constitution_value INTEGER;
    v_class_id INTEGER;
    v_base_inventory_size INTEGER;
    v_max_capacity INTEGER;
    v_current_size DOUBLE PRECISION;
    v_item_weight DOUBLE PRECISION;
    v_item_name VARCHAR(255);
    v_log_id BIGINT;
    v_location_id INTEGER;
BEGIN
    -- Check that the item is available in the combat area
    SELECT l.id INTO v_location_id
    FROM combat c
    JOIN location l ON c.location_id = l.id
    WHERE c.id = p_combat_id;

    IF v_location_id IS NULL THEN
        RAISE EXCEPTION 'Combat area not found';
    END IF;

    -- Get character's location and inventory
    SELECT location_id, inventory_id, character_class_id 
    INTO v_character_location_id, v_inventory_id, v_class_id
    FROM character
    WHERE id = p_character_id;

    -- Check if item is in the combat area location
    IF NOT EXISTS (
        SELECT 1
        FROM location_items_on_the_floor
        WHERE location_id = v_location_id AND items_on_the_floor_id = p_item_id
    ) THEN
        RAISE EXCEPTION 'Item is not in the combat area';
    END IF;

    -- Check if character is in the combat area
    IF v_character_location_id != v_location_id THEN
        RAISE EXCEPTION 'Character is not in the combat area';
    END IF;

    -- Get item weight and name
    SELECT weight, name INTO v_item_weight, v_item_name
    FROM item
    WHERE id = p_item_id;

    -- Get character's constitution
    v_constitution_value := get_attribute_value(p_character_id, 'CONSTITUTION');

    -- Get base inventory size from class
    SELECT inventory_multiplier * 10 INTO v_base_inventory_size
    FROM class
    WHERE id = v_class_id;

    v_max_capacity := v_base_inventory_size * (1 + (v_constitution_value / 100.0));

    -- Calculate current inventory size
    v_current_size := get_inventory_weight(v_inventory_id);
    -- Check if item fits in inventory
    IF v_current_size + v_item_weight > v_max_capacity THEN
        RAISE EXCEPTION 'Not enough inventory space';
    END IF;

    -- Remove item from location
    DELETE FROM location_items_on_the_floor
    WHERE location_id = v_location_id AND items_on_the_floor_id = p_item_id;

    -- Add item to inventory
    INSERT INTO inventory_items (inventory_id, items_id)
    VALUES (v_inventory_id, p_item_id);

    -- Log the looting event in the combat log
    INSERT INTO combat_log (
        id,
        action_points_spent,
        impact,
        description,
        actor_id,
        target_id
    ) VALUES (
        nextval('combat_seq'),
        0,  -- No AP spent for looting
        0,  -- No impact value for looting
        'Character looted item: ' || v_item_name,
        p_character_id,
        p_character_id  -- Target is self
    ) RETURNING id INTO v_log_id;

    -- Add the item to the combat log
    INSERT INTO combat_log_items_used (combat_log_id, items_used_id)
    VALUES (v_log_id, p_item_id);

    -- Add log to current round if in combat
    INSERT INTO round_logs (logs_id, round_id)
    SELECT v_log_id, r.id
    FROM round r
    JOIN combat_combat_rounds ccr ON r.id = ccr.combat_rounds_id
    JOIN combat c ON ccr.combat_id = c.id
    WHERE c.id = p_combat_id
    AND r.is_finished = FALSE
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION sp_loot_item(INTEGER, INTEGER, INTEGER) OWNER TO postgres;
