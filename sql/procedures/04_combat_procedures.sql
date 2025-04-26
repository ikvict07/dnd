-- Function to register a character into an ongoing combat session
CREATE OR REPLACE FUNCTION sp_enter_combat(
    p_combat_id INTEGER,
    p_character_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_combat_location_id INTEGER;
    v_character_location_id INTEGER;
    v_active_round_id INTEGER;
    v_intelligence_value INTEGER;
    v_base_ap INTEGER;
    v_new_ap INTEGER;
    v_character_class_id INTEGER;
    v_log_id BIGINT;
BEGIN
    -- Check if the combat exists
    SELECT location_id INTO v_combat_location_id
    FROM combat
    WHERE id = p_combat_id;

    IF v_combat_location_id IS NULL THEN
        RAISE EXCEPTION 'Combat session not found';
    END IF;

    -- Get character's location and class
    SELECT location_id, character_class_id INTO v_character_location_id, v_character_class_id
    FROM character
    WHERE id = p_character_id;

    -- Check if character is in the same location as the combat
    IF v_character_location_id != v_combat_location_id THEN
        RAISE EXCEPTION 'Character is not in the combat location';
    END IF;

    -- Get the current active round for this combat
    SELECT r.id INTO v_active_round_id
    FROM round r
    JOIN combat_combat_rounds ccr ON r.id = ccr.combat_rounds_id
    WHERE ccr.combat_id = p_combat_id AND r.is_finished = FALSE
    LIMIT 1;

    IF v_active_round_id IS NULL THEN
        RAISE EXCEPTION 'No active round found for this combat';
    END IF;

    -- Calculate AP for the character based on intelligence and class
    -- Get character's intelligence
    v_intelligence_value := get_attribute_value(p_character_id, 'INTELLIGENCE');

    -- Get base AP from class
    SELECT action_points_multiplier * 10 INTO v_base_ap
    FROM class
    WHERE id = v_character_class_id;

    -- Calculate new AP
    v_new_ap := v_base_ap * (1 + (v_intelligence_value / 100.0));

    -- Update character's AP
    UPDATE character
    SET action_points = v_new_ap
    WHERE id = p_character_id;

    -- Add character to the round participants
    INSERT INTO round_participants (participants_id, round_id)
    VALUES (p_character_id, v_active_round_id)
    ON CONFLICT DO NOTHING; -- In case the character is already in the round

    -- Log the character's entry into combat
    INSERT INTO combat_log (
        id,
        action_points_spent,
        impact,
        description,
        actor_id,
        target_id
    ) VALUES (
        nextval('combat_seq'),
        0, -- No AP spent for entering combat
        0, -- No impact for entering combat
        'Character entered combat',
        p_character_id,
        p_character_id -- Target is self
    ) RETURNING id INTO v_log_id;

    -- Add log to current round
    INSERT INTO round_logs (logs_id, round_id)
    VALUES (v_log_id, v_active_round_id);
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION sp_enter_combat(INTEGER, INTEGER) OWNER TO postgres;

-- Function to reset the combat state at the beginning of a new round
CREATE OR REPLACE FUNCTION sp_reset_round(
    p_combat_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_combat_location_id INTEGER;
    v_current_round_id INTEGER;
    v_current_round_number INTEGER;
    v_new_round_id INTEGER;
    v_character_record RECORD;
    v_intelligence_value INTEGER;
    v_base_ap INTEGER;
    v_new_ap INTEGER;
    v_log_id BIGINT;
BEGIN
    -- Get the combat location
    SELECT location_id INTO v_combat_location_id
    FROM combat
    WHERE id = p_combat_id;

    IF v_combat_location_id IS NULL THEN
        RAISE EXCEPTION 'Combat session not found';
    END IF;

    -- Get the current active round for this combat
    SELECT r.id, r.index INTO v_current_round_id, v_current_round_number
    FROM round r
    JOIN combat_combat_rounds ccr ON r.id = ccr.combat_rounds_id
    WHERE ccr.combat_id = p_combat_id AND r.is_finished = FALSE
    LIMIT 1;

    IF v_current_round_id IS NULL THEN
        RAISE EXCEPTION 'No active round found for this combat';
    END IF;

    -- Mark the current round as finished
    UPDATE round
    SET is_finished = TRUE
    WHERE id = v_current_round_id;

    -- Create a new round with incremented round number
    INSERT INTO round (id, index, is_finished)
    VALUES (nextval('combat_seq'), v_current_round_number + 1, FALSE)
    RETURNING id INTO v_new_round_id;

    -- Link the new round to the combat
    INSERT INTO combat_combat_rounds (combat_id, combat_rounds_id)
    VALUES (p_combat_id, v_new_round_id);

    -- Loop through all characters in the combat session
    FOR v_character_record IN (
        SELECT c.id, c.character_class_id
        FROM character c
        JOIN round_participants rp ON c.id = rp.participants_id
        WHERE rp.round_id = v_current_round_id
    ) LOOP
        -- Get character's intelligence
        v_intelligence_value := get_attribute_value(v_character_record.id, 'INTELLIGENCE');

        -- Get base AP from class
        SELECT action_points_multiplier * 10 INTO v_base_ap
        FROM class
        WHERE id = v_character_record.character_class_id;

        -- Calculate new AP
        v_new_ap := v_base_ap * (1 + (v_intelligence_value / 100.0));

        -- Update character's AP
        UPDATE character
        SET action_points = v_new_ap
        WHERE id = v_character_record.id;

        -- Add character to the new round participants
        INSERT INTO round_participants (participants_id, round_id)
        VALUES (v_character_record.id, v_new_round_id);
    END LOOP;

    -- Decrement effect rounds and remove expired effects
    CALL sp_decrement_effect_rounds();

    -- Log the round reset event
    INSERT INTO combat_log (
        id,
        action_points_spent,
        impact,
        description,
        actor_id,
        target_id
    ) VALUES (
        nextval('combat_seq'),
        0,
        0,
        'Round reset: Round ' || v_current_round_number || ' ended, Round ' || (v_current_round_number + 1) || ' started',
        NULL,
        NULL
    ) RETURNING id INTO v_log_id;

    -- Add log to new round
    INSERT INTO round_logs (logs_id, round_id)
    VALUES (v_log_id, v_new_round_id);
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION sp_reset_round(INTEGER) OWNER TO postgres;
