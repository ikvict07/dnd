create or replace function sp_apply_effect_from_template(
    p_effect_template_id integer,
    p_character_id integer
) returns integer as $$
declare
    v_effect_id integer;
    v_duration_rounds integer;
    v_effect_type varchar(255);
    v_affected_attribute_type varchar(255);
    v_effect_value integer;
    v_attribute_id integer;
    v_current_value integer;
begin
    -- Get the effect template details
    select
        duration_rounds,
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

    -- Create a new effect based on the template
    insert into effect (
        id,
        effect_template_id,
        rounds_left
    ) values (
                 nextval('effect_seq'),
                 p_effect_template_id,
                 v_duration_rounds
             ) returning id into v_effect_id;

    -- Associate the effect with the character
    insert into character_under_effects (
        character_id,
        under_effects_id
    ) values (
                 p_character_id,
                 v_effect_id
             );

    -- Get the attribute ID and current value
    select a.id, a.value into v_attribute_id, v_current_value
    from attribute a
             join character_attributes ca on a.id = ca.attributes_id
    where ca.character_id = p_character_id and a.attribute_type = v_affected_attribute_type;

    -- Apply the effect to the attribute
    if v_effect_type = 'BUFF' then
        update attribute
        set value = value + v_effect_value
        where id = v_attribute_id;
    elsif v_effect_type = 'DE_BUFF' then
        update attribute
        set value = value - v_effect_value
        where id = v_attribute_id;
    end if;

    return v_effect_id;
end;
$$ language plpgsql;

-- Procedure to cancel/remove an effect from a character
create or replace function sp_cancel_effect(
    p_effect_id integer
) returns void as $$
declare
    v_character_id integer;
    v_effect_template_id integer;
    v_effect_type varchar(255);
    v_affected_attribute_type varchar(255);
    v_effect_value integer;
    v_attribute_id integer;
begin
    -- Get the character associated with this effect
    select character_id into v_character_id
    from character_under_effects
    where under_effects_id = p_effect_id;

    -- Get the effect template details
    select
        e.effect_template_id,
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

    -- Get the attribute ID
    select a.id into v_attribute_id
    from attribute a
             join character_attributes ca on a.id = ca.attributes_id
    where ca.character_id = v_character_id and a.attribute_type = v_affected_attribute_type;

    -- Reverse the effect on the attribute
    if v_effect_type = 'BUFF' then
        update attribute
        set value = value - v_effect_value
        where id = v_attribute_id;
    elsif v_effect_type = 'DE_BUFF' then
        update attribute
        set value = value + v_effect_value
        where id = v_attribute_id;
    end if;

    -- Remove the association between character and effect
    delete from character_under_effects
    where under_effects_id = p_effect_id;

    -- Delete the effect itself
    delete from effect
    where id = p_effect_id;
end;
$$ language plpgsql;

-- Procedure to decrement effect rounds and remove expired effects
create or replace procedure sp_decrement_effect_rounds() as $$
declare
    v_effect_record record;
begin
    -- Update the rounds_left for all active effects
    update effect
    set rounds_left = rounds_left - 1
    where rounds_left > 0;

    -- Find all effects that have expired (rounds_left <= 0)
    for v_effect_record in
        select e.id
        from effect e
        where e.rounds_left <= 0
        loop
            -- Cancel each expired effect
            perform sp_cancel_effect(v_effect_record.id);
        end loop;
end;
$$ language plpgsql;