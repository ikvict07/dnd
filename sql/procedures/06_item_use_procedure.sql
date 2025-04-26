-- Item use procedure for D&D game

-- Function to use an item (like a potion) and apply its effect to a character
CREATE OR REPLACE FUNCTION sp_use_item(
    p_character_id INTEGER,
    p_item_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_inventory_id INTEGER;
    v_item_name VARCHAR(255);
    v_item_type INTEGER;
    v_potion_id INTEGER;
    v_effect_template_id INTEGER;
    v_effect_id INTEGER;
    v_log_id BIGINT;
    v_combat_id INTEGER;
    v_active_round_id INTEGER;
BEGIN
    -- Get character's inventory
    SELECT inventory_id INTO v_inventory_id
    FROM character
    WHERE id = p_character_id;

    IF v_inventory_id IS NULL THEN
        RAISE EXCEPTION 'Character not found';
    END IF;

    -- Check if the item is in the character's inventory
    IF NOT EXISTS (
        SELECT 1
        FROM inventory_items
        WHERE inventory_id = v_inventory_id AND items_id = p_item_id
    ) THEN
        RAISE EXCEPTION 'Item is not in the character''s inventory';
    END IF;

    -- Get item details
    SELECT i.name, i.type INTO v_item_name, v_item_type
    FROM item i
    WHERE i.id = p_item_id;

    -- If the item is a potion (type 2), apply its effect
    IF v_item_type = 2 THEN
        -- Get the potion and its effect template
        SELECT p.id, p.cause_effect_id INTO v_potion_id, v_effect_template_id
        FROM potion p
        WHERE p.item_id = p_item_id;

        IF v_effect_template_id IS NULL THEN
            RAISE EXCEPTION 'Potion has no effect template';
        END IF;

        -- Apply the effect from the template to the character
        v_effect_id := sp_apply_effect_from_template(v_effect_template_id, p_character_id);
    END IF;

    -- Remove the item from the inventory
    DELETE FROM inventory_items
    WHERE inventory_id = v_inventory_id AND items_id = p_item_id;

    -- Check if the character is in combat
    SELECT c.id INTO v_combat_id
    FROM combat c
    JOIN character ch ON c.location_id = ch.location_id
    JOIN round_participants rp ON ch.id = rp.participants_id
    JOIN round r ON rp.round_id = r.id
    WHERE ch.id = p_character_id AND r.is_finished = FALSE
    LIMIT 1;

    -- If the character is in combat, add a log entry
    IF v_combat_id IS NOT NULL THEN
        -- Get the current active round for this combat
        SELECT r.id INTO v_active_round_id
        FROM round r
        JOIN combat_combat_rounds ccr ON r.id = ccr.combat_rounds_id
        WHERE ccr.combat_id = v_combat_id AND r.is_finished = FALSE
        LIMIT 1;

        -- Create a log entry
        INSERT INTO combat_log (
            id,
            action_points_spent,
            impact,
            description,
            actor_id,
            target_id
        ) VALUES (
            nextval('combat_seq'),
            0,  -- No AP spent for using an item
            0,  -- No direct impact value for using an item
            'Character used item: ' || v_item_name,
            p_character_id,
            p_character_id  -- Target is self
        ) RETURNING id INTO v_log_id;

        -- Add the item to the combat log
        INSERT INTO combat_log_items_used (combat_log_id, items_used_id)
        VALUES (v_log_id, p_item_id);

        -- Add log to current round
        INSERT INTO round_logs (logs_id, round_id)
        VALUES (v_log_id, v_active_round_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION sp_use_item(INTEGER, INTEGER) OWNER TO postgres;
