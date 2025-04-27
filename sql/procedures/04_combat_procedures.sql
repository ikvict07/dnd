create or replace procedure sp_enter_combat(
    p_combat_id integer,
    p_character_id integer
) as
$$
declare
    v_combat_location_id    integer;
    v_character_location_id integer;
    v_active_round_id       integer;
    v_intelligence_value    integer;
    v_base_ap               integer;
    v_new_ap                integer;
    v_character_class_id    integer;
    v_log_id                bigint;
begin
    select location_id
    into v_combat_location_id
    from combat
    where id = p_combat_id;

    if v_combat_location_id is null then
        raise exception 'Combat session not found';
    end if;

    select location_id, character_class_id
    into v_character_location_id, v_character_class_id
    from character
    where id = p_character_id;

    if v_character_location_id != v_combat_location_id then
        raise exception 'Character is not in the combat location';
    end if;

    select r.id
    into v_active_round_id
    from round r
             join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
    where ccr.combat_id = p_combat_id
      and r.is_finished = false
    limit 1;

    if v_active_round_id is null then
        raise exception 'No active round found for this combat';
    end if;

    v_intelligence_value := get_attribute_value(p_character_id, 'INTELLIGENCE');

    select action_points_multiplier * 10
    into v_base_ap
    from class
    where id = v_character_class_id;

    v_new_ap := v_base_ap * (1 + (v_intelligence_value / 100.0));

    update character
    set action_points = v_new_ap
    where id = p_character_id;

    insert into round_participants (participants_id, round_id)
    values (p_character_id, v_active_round_id)
    on conflict do nothing;
    insert into combat_log (action_points_spent,
                            impact,
                            description,
                            actor_id,
                            target_id)
    values (0,
            0,
            'Character entered combat',
            p_character_id,
            p_character_id
           )
    returning id into v_log_id;

    insert into round_logs (logs_id, round_id)
    values (v_log_id, v_active_round_id);
end;
$$ language plpgsql;

alter procedure sp_enter_combat(integer, integer) owner to postgres;

create or replace procedure sp_reset_round(
    p_combat_id integer
)  as
$$
declare
    v_combat_location_id   integer;
    v_current_round_id     integer;
    v_current_round_number integer;
    v_new_round_id         integer;
    v_character_record     record;
    v_intelligence_value   integer;
    v_base_ap              integer;
    v_new_ap               integer;
    v_log_id               bigint;
begin
    select location_id
    into v_combat_location_id
    from combat
    where id = p_combat_id;

    if v_combat_location_id is null then
        raise exception 'Combat session not found';
    end if;

    select r.id, r.index
    into v_current_round_id, v_current_round_number
    from round r
             join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
    where ccr.combat_id = p_combat_id
      and r.is_finished = false
    limit 1;

    if v_current_round_id is null then
        raise exception 'No active round found for this combat';
    end if;

    update round
    set is_finished = true
    where id = v_current_round_id;


    insert into round (index, is_finished)
    values (v_current_round_number + 1, false)
    returning id into v_new_round_id;

    insert into combat_combat_rounds (combat_id, combat_rounds_id)
    values (p_combat_id, v_new_round_id);

    for v_character_record in (select c.id, c.character_class_id
                               from character c
                                        join round_participants rp on c.id = rp.participants_id
                               where rp.round_id = v_current_round_id)
        loop
            v_intelligence_value := get_attribute_value(v_character_record.id::integer, 'INTELLIGENCE'::attribute_type);

            select action_points_multiplier * 10
            into v_base_ap
            from class
            where id = v_character_record.character_class_id;

            v_new_ap := v_base_ap * (1 + (v_intelligence_value / 100.0));

            update character
            set action_points = v_new_ap
            where id = v_character_record.id;

            insert into round_participants (participants_id, round_id)
            values (v_character_record.id, v_new_round_id);
        end loop;

    call sp_decrement_effect_rounds();

    insert into combat_log (action_points_spent,
                            impact,
                            description,
                            actor_id,
                            target_id)
    values (0,
            0,
            'Round reset: Round ' || v_current_round_number || ' ended, Round ' || (v_current_round_number + 1) ||
            ' started',
            null,
            null)
    returning id into v_log_id;

    -- Add log to new round
    insert into round_logs (logs_id, round_id)
    values (v_log_id, v_new_round_id);
end;
$$ language plpgsql;

alter procedure sp_reset_round(integer) owner to postgres;