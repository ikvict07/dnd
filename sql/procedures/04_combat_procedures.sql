-- Function to register a character into an ongoing combat session
create or replace function sp_enter_combat(
    p_combat_id integer,
    p_character_id integer
) returns void as $$
declare
    v_combat_location_id integer;
    v_character_location_id integer;
    v_active_round_id integer;
    v_intelligence_value integer;
    v_base_ap integer;
    v_new_ap integer;
    v_character_class_id integer;
    v_log_id bigint;
begin
    -- Check if the combat exists
    select location_id into v_combat_location_id
    from combat
    where id = p_combat_id;

    if v_combat_location_id is null then
        raise exception 'Combat session not found';
    end if;

    -- Get character's location and class
    select location_id, character_class_id into v_character_location_id, v_character_class_id
    from character
    where id = p_character_id;

    -- Check if character is in the same location as the combat
    if v_character_location_id != v_combat_location_id then
        raise exception 'Character is not in the combat location';
    end if;

    -- Get the current active round for this combat
    select r.id into v_active_round_id
    from round r
             join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
    where ccr.combat_id = p_combat_id and r.is_finished = false
    limit 1;

    if v_active_round_id is null then
        raise exception 'No active round found for this combat';
    end if;

    -- Calculate AP for the character based on intelligence and class
    -- Get character's intelligence
    v_intelligence_value := get_attribute_value(p_character_id, 'INTELLIGENCE');

    -- Get base AP from class
    select action_points_multiplier * 10 into v_base_ap
    from class
    where id = v_character_class_id;

    -- Calculate new AP
    v_new_ap := v_base_ap * (1 + (v_intelligence_value / 100.0));

    -- Update character's AP
    update character
    set action_points = v_new_ap
    where id = p_character_id;

    -- Add character to the round participants
    insert into round_participants (participants_id, round_id)
    values (p_character_id, v_active_round_id)
    on conflict do nothing; -- In case the character is already in the round

    -- Log the character's entry into combat
    insert into combat_log (
        id,
        action_points_spent,
        impact,
        description,
        actor_id,
        target_id
    ) values (
                 nextval('combat_seq'),
                 0, -- No AP spent for entering combat
                 0, -- No impact for entering combat
                 'Character entered combat',
                 p_character_id,
                 p_character_id -- Target is self
             ) returning id into v_log_id;

    -- Add log to current round
    insert into round_logs (logs_id, round_id)
    values (v_log_id, v_active_round_id);
end;
$$ language plpgsql;

alter function sp_enter_combat(integer, integer) owner to postgres;

-- Function to reset the combat state at the beginning of a new round
create or replace function sp_reset_round(
    p_combat_id integer
) returns void as $$
declare
    v_combat_location_id integer;
    v_current_round_id integer;
    v_current_round_number integer;
    v_new_round_id integer;
    v_character_record record;
    v_intelligence_value integer;
    v_base_ap integer;
    v_new_ap integer;
    v_log_id bigint;
begin
    -- Get the combat location
    select location_id into v_combat_location_id
    from combat
    where id = p_combat_id;

    if v_combat_location_id is null then
        raise exception 'Combat session not found';
    end if;

    -- Get the current active round for this combat
    select r.id, r.index into v_current_round_id, v_current_round_number
    from round r
             join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
    where ccr.combat_id = p_combat_id and r.is_finished = false
    limit 1;

    if v_current_round_id is null then
        raise exception 'No active round found for this combat';
    end if;

    -- Mark the current round as finished
    update round
    set is_finished = true
    where id = v_current_round_id;

    -- Create a new round with incremented round number
    insert into round (id, index, is_finished)
    values (nextval('combat_seq'), v_current_round_number + 1, false)
    returning id into v_new_round_id;

    -- Link the new round to the combat
    insert into combat_combat_rounds (combat_id, combat_rounds_id)
    values (p_combat_id, v_new_round_id);

    -- Loop through all characters in the combat session
    for v_character_record in (
        select c.id, c.character_class_id
        from character c
                 join round_participants rp on c.id = rp.participants_id
        where rp.round_id = v_current_round_id
    ) loop
            -- Get character's intelligence
            v_intelligence_value := get_attribute_value(v_character_record.id, 'INTELLIGENCE');

            -- Get base AP from class
            select action_points_multiplier * 10 into v_base_ap
            from class
            where id = v_character_record.character_class_id;

            -- Calculate new AP
            v_new_ap := v_base_ap * (1 + (v_intelligence_value / 100.0));

            -- Update character's AP
            update character
            set action_points = v_new_ap
            where id = v_character_record.id;

            -- Add character to the new round participants
            insert into round_participants (participants_id, round_id)
            values (v_character_record.id, v_new_round_id);
        end loop;

    -- Decrement effect rounds and remove expired effects
    call sp_decrement_effect_rounds();

    -- Log the round reset event
    insert into combat_log (
        id,
        action_points_spent,
        impact,
        description,
        actor_id,
        target_id
    ) values (
                 nextval('combat_seq'),
                 0,
                 0,
                 'Round reset: Round ' || v_current_round_number || ' ended, Round ' || (v_current_round_number + 1) || ' started',
                 null,
                 null
             ) returning id into v_log_id;

    -- Add log to new round
    insert into round_logs (logs_id, round_id)
    values (v_log_id, v_new_round_id);
end;
$$ language plpgsql;

alter function sp_reset_round(integer) owner to postgres;