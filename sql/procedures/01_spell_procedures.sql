CREATE OR REPLACE FUNCTION sp_cast_spell(
    p_caster_id INTEGER,
    p_target_id INTEGER,
    p_spell_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_required_ap INTEGER;
    v_caster_ap INTEGER;
    v_spell_impact INTEGER;
    v_spell_name VARCHAR(255);
    v_log_id BIGINT;
    v_effect_template_id INTEGER;
    v_effect_id INTEGER;
BEGIN
    -- Validate that the caster has sufficient AP
    SELECT action_points INTO v_caster_ap
    FROM character
    WHERE id = p_caster_id;

    -- Calculate the effective spell cost based on character attributes
    v_required_ap := calculate_required_ap(p_spell_id, p_caster_id);

    -- Get the spell name
    SELECT name INTO v_spell_name
    FROM spell
    WHERE id = p_spell_id;

    -- Check if caster has enough AP
    IF v_caster_ap < v_required_ap THEN
        RAISE EXCEPTION 'Insufficient action points to cast this spell';
    END IF;

    -- Deduct the appropriate AP from the caster
    UPDATE character
    SET action_points = action_points - v_required_ap
    WHERE id = p_caster_id;

    -- Calculate and apply spell impact
    v_spell_impact := calculate_and_apply_spell_impact(p_caster_id, p_target_id, p_spell_id);

    -- Get effect template associated with the spell (if any)
    SELECT cause_effect_id INTO v_effect_template_id
    FROM spell
    WHERE id = p_spell_id;

    -- If spell has an effect template, create and apply effect to target
    IF v_effect_template_id IS NOT NULL THEN
        -- Use the existing function to apply effect from template to character
        v_effect_id := sp_apply_effect_from_template(v_effect_template_id, p_target_id);
    END IF;

    -- Log the spell casting event in the combat log
    INSERT INTO combat_log (
        id,
        action_points_spent,
        impact,
        description,
        action_id,
        actor_id,
        target_id
    ) VALUES (
                 nextval('combat_seq'),
                 v_required_ap,
                 v_spell_impact,
                 CASE
                     WHEN v_spell_impact > 0 THEN 'Cast spell: ' || v_spell_name || ' - Hit for ' || v_spell_impact || ' damage'
                     WHEN v_spell_impact = 0 THEN 'Cast spell: ' || v_spell_name || ' - Missed'
                     ELSE 'Cast spell: ' || v_spell_name || ' - Healed for ' || ABS(v_spell_impact)
                     END ||
                 CASE
                     WHEN v_effect_template_id IS NOT NULL THEN ' (with effect)'
                     ELSE ''
                     END,
                 p_spell_id,
                 p_caster_id,
                 p_target_id
             ) RETURNING id INTO v_log_id;

    -- Add log to current round if in combat
    INSERT INTO round_logs (logs_id, round_id)
    SELECT v_log_id, r.id
    FROM round r
             JOIN combat_combat_rounds ccr ON r.id = ccr.combat_rounds_id
             JOIN combat c ON ccr.combat_id = c.id
    WHERE r.is_finished = FALSE
      AND EXISTS (
        SELECT 1 FROM round_participants rp
        WHERE rp.round_id = r.id
          AND rp.participants_id IN (p_caster_id, p_target_id)
    )
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;