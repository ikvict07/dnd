create or replace function sp_cast_spell(
    p_caster_id integer,
    p_target_id integer,
    p_spell_id integer
) returns void as $$
declare
    v_required_ap integer;
    v_caster_ap integer;
    v_spell_impact integer;
    v_spell_name varchar(255);
    v_log_id bigint;
    v_effect_template_id integer;
    v_effect_id integer;
begin
    -- Validate that the caster has sufficient AP
    select action_points into v_caster_ap
    from character
    where id = p_caster_id;

    -- Calculate the effective spell cost based on character attributes
    v_required_ap := calculate_required_ap(p_spell_id, p_caster_id);

    -- Get the spell name
    select name into v_spell_name
    from spell
    where id = p_spell_id;

    -- Check if caster has enough AP
    if v_caster_ap < v_required_ap then
        raise exception 'Insufficient action points to cast this spell';
    end if;

    -- Deduct the appropriate AP from the caster
    update character
    set action_points = action_points - v_required_ap
    where id = p_caster_id;

    -- Calculate and apply spell impact
    v_spell_impact := calculate_and_apply_spell_impact(p_caster_id, p_target_id, p_spell_id);

    -- Get effect template associated with the spell (if any)
    select cause_effect_id into v_effect_template_id
    from spell
    where id = p_spell_id;

    -- If spell has an effect template, create and apply effect to target
    if v_effect_template_id is not null then
        -- Use the existing function to apply effect from template to character
        v_effect_id := sp_apply_effect_from_template(v_effect_template_id, p_target_id);
    end if;

    -- Log the spell casting event in the combat log
    insert into combat_log (
        id,
        action_points_spent,
        impact,
        description,
        action_id,
        actor_id,
        target_id
    ) values (
                 nextval('combat_seq'),
                 v_required_ap,
                 v_spell_impact,
                 case
                     when v_spell_impact > 0 then 'Cast spell: ' || v_spell_name || ' - Hit for ' || v_spell_impact || ' damage'
                     when v_spell_impact = 0 then 'Cast spell: ' || v_spell_name || ' - Missed'
                     else 'Cast spell: ' || v_spell_name || ' - Healed for ' || abs(v_spell_impact)
                     end ||
                 case
                     when v_effect_template_id is not null then ' (with effect)'
                     else ''
                     end,
                 p_spell_id,
                 p_caster_id,
                 p_target_id
             ) returning id into v_log_id;

    -- Add log to current round if in combat
    insert into round_logs (logs_id, round_id)
    select v_log_id, r.id
    from round r
             join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
             join combat c on ccr.combat_id = c.id
    where r.is_finished = false
      and exists (
        select 1 from round_participants rp
        where rp.round_id = r.id
          and rp.participants_id in (p_caster_id, p_target_id)
    )
    limit 1;
end;
$$ language plpgsql;