create or replace function calculate_spell_impact(p_spell_id integer, p_actor_id integer, p_target_id integer) returns integer
    language plpgsql
as
$$
declare
    v_base_value double precision;
    v_spell_element element;
    v_spell_impact_type spell_impact_type;
    v_scales_from attribute_type[];
    v_primary_attribute attribute_type;
    v_primary_attribute_value integer;
    v_weapon_damage double precision := 0;
    v_target_resistant_element element;
    v_impact double precision;
    v_resistance double precision := 1;
    v_armor_id int;
begin
    select value, spell_element, spell_impact_type, scales_from
    into v_base_value, v_spell_element, v_spell_impact_type, v_scales_from
    from spell
    where id = p_spell_id;

    v_primary_attribute := v_scales_from[1]::attribute_type;

    v_primary_attribute_value := get_attribute_value(p_actor_id, v_primary_attribute);

    if v_spell_impact_type = 'damage'::spell_impact_type then
        select coalesce(w.damage_multiplier, 0) into v_weapon_damage
        from character c
                 left join weapon w on c.weapon_id = w.id
        where c.id = p_actor_id;
    end if;

    v_impact := v_base_value * (1 + (v_primary_attribute_value / 50.0)) + (v_weapon_damage * 0.5);

    select a.protects_from into v_target_resistant_element
    from character c
             join armor_set a on c.armor_set_id = a.id
    where c.id = p_target_id;


    if v_target_resistant_element is not null and v_spell_element = v_target_resistant_element then
        v_armor_id := (select a.id
                       from character c
                                join armor_set a on c.armor_set_id = a.id
                       where c.id = p_target_id);
        select r.damage_reduction into v_resistance from armor_set r where r.id = v_armor_id;
        v_impact := v_impact / v_resistance;
    end if;

    return round(v_impact);
end;
$$;

alter function calculate_spell_impact(integer, integer, integer) owner to postgres;



create or replace function calculate_attribute_bonus(p_character_id integer, p_attribute attribute_type) returns integer
    language plpgsql
as
$$
declare
    v_attribute_bonus integer;
begin
    v_attribute_bonus := get_attribute_value(p_character_id, p_attribute) / 5;

    return v_attribute_bonus;
end;
$$;

alter function calculate_attribute_bonus(integer, attribute_type) owner to postgres;

create or replace function calculate_hit_roll(p_character_id integer, p_attribute attribute_type) returns integer
    language plpgsql
as
$$
declare
    v_d20_roll integer;
    v_attribute_bonus integer;
    v_hit_roll integer;
begin
    v_attribute_bonus := calculate_attribute_bonus(p_character_id, p_attribute);

    -- perform a d20 roll and add the relevant attribute bonus
    v_d20_roll := 1 + floor(random() * 20)::integer;
    v_hit_roll := v_d20_roll + v_attribute_bonus;

    return v_hit_roll;
end;
$$;

alter function calculate_hit_roll(integer, attribute_type) owner to postgres;

create or replace function get_armor_class_value(p_character_id integer) returns integer
    language plpgsql
as
$$
declare
    v_target_armor_class armor_class;
    v_armor_class_value integer;
begin
    select a.armor_class into v_target_armor_class
    from character c
             left join armor_set a on c.armor_set_id = a.id
    where c.id = p_character_id;

    case v_target_armor_class
        when 'cloth' then v_armor_class_value := 10;
        when 'leather' then v_armor_class_value := 13;
        when 'heavy' then v_armor_class_value := 16;
        else v_armor_class_value := 5; -- default if no armor
        end case;

    return v_armor_class_value;
end;
$$;

alter function get_armor_class_value(integer) owner to postgres;

create or replace function calculate_max_hp(p_character_id integer) returns integer
    language plpgsql
as
$$
declare
    v_max_hp integer;
begin
    v_max_hp := 100 + get_attribute_value(p_character_id, 'health') * 5;

    return v_max_hp;
end;
$$;

alter function calculate_max_hp(integer) owner to postgres;

create or replace function apply_spell_effect(p_caster_id integer, p_target_id integer, p_spell_id integer, p_hit_roll integer) returns integer
    language plpgsql
as
$$
declare
    v_spell_impact integer;
    v_armor_class_value integer;
    v_spell_impact_type spell_impact_type;
    v_max_hp integer;
    v_effect_template_id bigint;
    v_effect_id bigint;
    v_duration_rounds integer;
begin
    select spell_impact_type, cause_effect_id into v_spell_impact_type, v_effect_template_id
    from spell
    where id = p_spell_id;

    v_spell_impact := calculate_spell_impact(p_spell_id, p_caster_id, p_target_id);

    v_armor_class_value := get_armor_class_value(p_target_id);

    v_max_hp := calculate_max_hp(p_target_id);

    if v_spell_impact_type = 'healing' then
        update character
        set hp = least(v_max_hp, hp + v_spell_impact)
        where id = p_target_id;
    else
        if p_hit_roll >= v_armor_class_value then
            update character
            set hp = greatest(0, hp - v_spell_impact)
            where id = p_target_id;
        else
            v_spell_impact := 0;
        end if;
    end if;

    if v_effect_template_id is not null and (p_hit_roll >= v_armor_class_value or v_spell_impact_type = 'healing') then
        select duration_rounds into v_duration_rounds
        from effect_template
        where id = v_effect_template_id;

        insert into effect ( effect_template_id, rounds_left)
        values (v_effect_template_id, v_duration_rounds)
        returning id into v_effect_id;

        insert into character_under_effects (character_id, under_effects_id)
        values (p_target_id, v_effect_id);
    end if;

    return v_spell_impact;
end;
$$;

alter function apply_spell_effect(integer, integer, integer, integer) owner to postgres;



alter function apply_spell_effect(integer, integer, integer, integer) owner to postgres;



create or replace function calculate_and_apply_spell_impact(
    p_caster_id integer,
    p_target_id integer,
    p_spell_id integer
) returns integer
    language plpgsql
as
$$
declare
    v_spell_scales_from attribute_type[];
    v_primary_attribute attribute_type;
    v_hit_roll integer;
    v_spell_impact integer;
begin
    select scales_from into v_spell_scales_from
    from spell
    where id = p_spell_id;

    v_primary_attribute := v_spell_scales_from[1]::attribute_type;

    v_hit_roll := calculate_hit_roll(p_caster_id, v_primary_attribute);

    v_spell_impact := apply_spell_effect(p_caster_id, p_target_id, p_spell_id, v_hit_roll);

    return v_spell_impact;
end;
$$;

alter function calculate_and_apply_spell_impact(integer, integer, integer) owner to postgres;


create or replace function calculate_required_ap(p_spell_id integer, p_character_id integer) returns integer
    language plpgsql
as
$$
declare
    v_base_cost integer;
    v_scales_from attribute_type[];
    v_attribute_types text[];
    v_attribute_value integer;
    v_attribute_factor double precision := 0;
    v_final_cost integer;
begin
    select base_cost, scales_from into v_base_cost, v_scales_from
    from spell
    where id = p_spell_id;

    raise notice 'v_scales_from: %', v_scales_from::text;
    v_attribute_types := v_scales_from;

    for i in 1..array_length(v_attribute_types, 1) loop
            v_attribute_value := get_attribute_value(p_character_id, trim(v_attribute_types[i])::attribute_type);
            v_attribute_factor := v_attribute_factor + (v_attribute_value / (100 * array_length(v_attribute_types, 1)));
        end loop;

    v_final_cost := v_base_cost * (1 - v_attribute_factor);

    return greatest(1, v_final_cost);
end;
$$;

alter function calculate_required_ap(integer, integer) owner to postgres;