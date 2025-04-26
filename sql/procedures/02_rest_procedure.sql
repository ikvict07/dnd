-- Function to allow a character to rest outside combat
CREATE OR REPLACE FUNCTION sp_rest_character(
    p_character_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_is_pvp BOOLEAN;
    v_healing_spell_id INTEGER;
    v_current_ap INTEGER;
    v_class_id BIGINT;
    v_action_points_multiplier DOUBLE PRECISION;
BEGIN
    -- Check if the character is in a non-PvP location
    SELECT l.is_pvp INTO v_is_pvp
    FROM character c
    JOIN location l ON c.location_id = l.id
    WHERE c.id = p_character_id;

    IF v_is_pvp THEN
        RAISE EXCEPTION 'Cannot rest in a PvP location';
    END IF;

    SELECT id INTO v_healing_spell_id
    FROM spell
    WHERE name = 'Rest' AND is_pvp = FALSE
    LIMIT 1;

    IF v_healing_spell_id IS NULL THEN
        RAISE EXCEPTION 'Rest not found';
    END IF;

    SELECT action_points INTO v_current_ap
    FROM character
    WHERE id = p_character_id;

    PERFORM sp_cast_spell(p_character_id, p_character_id, v_healing_spell_id);

    SELECT c.character_class_id, cl.action_points_multiplier
    INTO v_class_id, v_action_points_multiplier
    FROM character c
    JOIN class cl ON c.character_class_id = cl.id
    WHERE c.id = p_character_id;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION sp_rest_character(INTEGER) OWNER TO postgres;
