create or replace procedure sp_rest_character(
    p_character_id integer
)  as $$
declare
    v_is_pvp boolean;
    v_healing_spell_id integer;
    v_current_ap integer;
    v_class_id bigint;
    v_action_points_multiplier double precision;
begin
    select l.is_pvp into v_is_pvp
    from character c
             join location l on c.location_id = l.id
    where c.id = p_character_id;

    if v_is_pvp then
        raise exception 'cannot rest in a pvp location';
    end if;

    select id into v_healing_spell_id
    from spell
    where name = 'rest' and is_pvp = false
    limit 1;

    if v_healing_spell_id is null then
        raise exception 'rest not found';
    end if;

    select action_points into v_current_ap
    from character
    where id = p_character_id;

    call sp_cast_spell(p_character_id, p_character_id, v_healing_spell_id);

    select c.character_class_id, cl.action_points_multiplier
    into v_class_id, v_action_points_multiplier
    from character c
             join class cl on c.character_class_id = cl.id
    where c.id = p_character_id;
end;
$$ language plpgsql;

alter procedure sp_rest_character(integer) owner to postgres;