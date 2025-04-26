-- Effect-related procedures for D&D game

-- Procedure to apply an effect from a template to a character
CREATE OR REPLACE FUNCTION sp_apply_effect_from_template(
    p_effect_template_id INTEGER,
    p_character_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_effect_id INTEGER;
    v_duration_rounds INTEGER;
    v_effect_type VARCHAR(255);
    v_affected_attribute_type VARCHAR(255);
    v_effect_value INTEGER;
    v_attribute_id INTEGER;
    v_current_value INTEGER;
BEGIN
    -- Get the effect template details
    SELECT
        duration_rounds,
        effect,
        affected_attribute_type,
        value
    INTO
        v_duration_rounds,
        v_effect_type,
        v_affected_attribute_type,
        v_effect_value
    FROM effect_template
    WHERE id = p_effect_template_id;

    -- Create a new effect based on the template
    INSERT INTO effect (
        id,
        effect_template_id,
        rounds_left
    ) VALUES (
                 nextval('effect_seq'),
                 p_effect_template_id,
                 v_duration_rounds
             ) RETURNING id INTO v_effect_id;

    -- Associate the effect with the character
    INSERT INTO character_under_effects (
        character_id,
        under_effects_id
    ) VALUES (
                 p_character_id,
                 v_effect_id
             );

    -- Get the attribute ID and current value
    SELECT a.id, a.value INTO v_attribute_id, v_current_value
    FROM attribute a
             JOIN character_attributes ca ON a.id = ca.attributes_id
    WHERE ca.character_id = p_character_id AND a.attribute_type = v_affected_attribute_type;

    -- Apply the effect to the attribute
    IF v_effect_type = 'BUFF' THEN
        UPDATE attribute
        SET value = value + v_effect_value
        WHERE id = v_attribute_id;
    ELSIF v_effect_type = 'DE_BUFF' THEN
        UPDATE attribute
        SET value = value - v_effect_value
        WHERE id = v_attribute_id;
    END IF;

    RETURN v_effect_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to cancel/remove an effect from a character
CREATE OR REPLACE FUNCTION sp_cancel_effect(
    p_effect_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_character_id INTEGER;
    v_effect_template_id INTEGER;
    v_effect_type VARCHAR(255);
    v_affected_attribute_type VARCHAR(255);
    v_effect_value INTEGER;
    v_attribute_id INTEGER;
BEGIN
    -- Get the character associated with this effect
    SELECT character_id INTO v_character_id
    FROM character_under_effects
    WHERE under_effects_id = p_effect_id;

    -- Get the effect template details
    SELECT
        e.effect_template_id,
        et.effect,
        et.affected_attribute_type,
        et.value
    INTO
        v_effect_template_id,
        v_effect_type,
        v_affected_attribute_type,
        v_effect_value
    FROM effect e
             JOIN effect_template et ON e.effect_template_id = et.id
    WHERE e.id = p_effect_id;

    -- Get the attribute ID
    SELECT a.id INTO v_attribute_id
    FROM attribute a
             JOIN character_attributes ca ON a.id = ca.attributes_id
    WHERE ca.character_id = v_character_id AND a.attribute_type = v_affected_attribute_type;

    -- Reverse the effect on the attribute
    IF v_effect_type = 'BUFF' THEN
        UPDATE attribute
        SET value = value - v_effect_value
        WHERE id = v_attribute_id;
    ELSIF v_effect_type = 'DE_BUFF' THEN
        UPDATE attribute
        SET value = value + v_effect_value
        WHERE id = v_attribute_id;
    END IF;

    -- Remove the association between character and effect
    DELETE FROM character_under_effects
    WHERE under_effects_id = p_effect_id;

    -- Delete the effect itself
    DELETE FROM effect
    WHERE id = p_effect_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to decrement effect rounds and remove expired effects
CREATE OR REPLACE PROCEDURE sp_decrement_effect_rounds() AS $$
DECLARE
    v_effect_record RECORD;
BEGIN
    -- Update the rounds_left for all active effects
    UPDATE effect
    SET rounds_left = rounds_left - 1
    WHERE rounds_left > 0;

    -- Find all effects that have expired (rounds_left <= 0)
    FOR v_effect_record IN
        SELECT e.id
        FROM effect e
        WHERE e.rounds_left <= 0
        LOOP
            -- Cancel each expired effect
            PERFORM sp_cancel_effect(v_effect_record.id);
        END LOOP;
END;
$$ LANGUAGE plpgsql;
