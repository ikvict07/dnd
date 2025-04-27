create or replace function sp_apply_effect_from_template(
    p_effect_template_id integer,
    p_character_id integer
) returns integer as
$$
declare
    v_effect_id               integer;
    v_duration_rounds         integer;
    v_effect_type             varchar(255);
    v_affected_attribute_type varchar(255);
    v_effect_value            integer;
    v_attribute_id            integer;
    v_current_value           integer;
begin
    select duration_rounds,
           effect,
           affected_attribute_type,
           value
    into
        v_duration_rounds,
        v_effect_type,
        v_affected_attribute_type,
        v_effect_value
    from effect_template
    where id = p_effect_template_id;
    insert into effect (effect_template_id,
                        rounds_left)
    values (p_effect_template_id,
            v_duration_rounds)
    returning id into v_effect_id;

    insert into character_under_effects (character_id,
                                         under_effects_id)
    values (p_character_id,
            v_effect_id);

    select a.id, a.value
    into v_attribute_id, v_current_value
    from attribute a
             join character_attributes ca on a.id = ca.attributes_id
    where ca.character_id = p_character_id
      and a.attribute_type = v_affected_attribute_type;

    if v_effect_type = 'buff' then
        update attribute
        set value = value + v_effect_value
        where id = v_attribute_id;
    elsif v_effect_type = 'de_buff' then
        update attribute
        set value = value - v_effect_value
        where id = v_attribute_id;
    end if;

    return v_effect_id;
end;
$$ language plpgsql;

create or replace procedure sp_cancel_effect(
    p_effect_id integer
) as
$$
declare
    v_character_id            integer;
    v_effect_template_id      integer;
    v_effect_type             varchar(255);
    v_affected_attribute_type varchar(255);
    v_effect_value            integer;
    v_attribute_id            integer;
begin
    select character_id
    into v_character_id
    from character_under_effects
    where under_effects_id = p_effect_id;

    select e.effect_template_id,
           et.effect,
           et.affected_attribute_type,
           et.value
    into
        v_effect_template_id,
        v_effect_type,
        v_affected_attribute_type,
        v_effect_value
    from effect e
             join effect_template et on e.effect_template_id = et.id
    where e.id = p_effect_id;

    select a.id
    into v_attribute_id
    from attribute a
             join character_attributes ca on a.id = ca.attributes_id
    where ca.character_id = v_character_id
      and a.attribute_type = v_affected_attribute_type;

    if v_effect_type = 'buff' then
        update attribute
        set value = value - v_effect_value
        where id = v_attribute_id;
    elsif v_effect_type = 'de_buff' then
        update attribute
        set value = value + v_effect_value
        where id = v_attribute_id;
    end if;

    delete
    from character_under_effects
    where under_effects_id = p_effect_id;

    delete
    from effect
    where id = p_effect_id;
end;
$$ language plpgsql;

create or replace procedure sp_decrement_effect_rounds() as
$$
declare
    v_effect_record record;
begin
    update effect
    set rounds_left = rounds_left - 1
    where rounds_left > 0;

    for v_effect_record in
        select e.id
        from effect e
        where e.rounds_left <= 0
        loop
            call sp_cancel_effect(v_effect_record.id);
        end loop;
end;
$$ language plpgsql;