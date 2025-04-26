-- Function to calculate spell impact
create or replace function calculate_spell_impact(p_spell_id integer, p_actor_id integer, p_target_id integer) returns integer
    language plpgsql
as
$$
DECLARE
    v_base_value DOUBLE PRECISION;
    v_spell_element element;
    v_spell_impact_type spell_impact_type;
    v_scales_from VARCHAR;
    v_primary_attribute attribute_type;
    v_primary_attribute_value INTEGER;
    v_weapon_damage DOUBLE PRECISION := 0;
    v_target_resistant_element element;
    v_impact DOUBLE PRECISION;
    v_resistance DOUBLE PRECISION := 1;
    v_armor_id int;
BEGIN
    SELECT value, spell_element, spell_impact_type, scales_from
    INTO v_base_value, v_spell_element, v_spell_impact_type, v_scales_from
    FROM spell
    WHERE id = p_spell_id;

    -- Get primary attribute (first in scales_from list)
    v_primary_attribute := (string_to_array(v_scales_from, ','))[1]::attribute_type;

    -- Get primary attribute value
    v_primary_attribute_value := get_attribute_value(p_actor_id, v_primary_attribute);

    -- Get weapon damage if applicable
    IF v_spell_impact_type = 'DAMAGE' THEN
        SELECT COALESCE(w.damage_multiplier, 0) INTO v_weapon_damage
        FROM character c
                 LEFT JOIN weapon w ON c.weapon_id = w.id
        WHERE c.id = p_actor_id;
    END IF;

    -- Calculate impact
    v_impact := v_base_value * (1 + (v_primary_attribute_value / 50.0)) + (v_weapon_damage * 0.5);

    -- Check for resistance
    SELECT a.protects_from INTO v_target_resistant_element
    FROM character c
             JOIN armor_set a ON c.armor_set_id = a.id
    WHERE c.id = p_target_id;


    IF v_target_resistant_element IS NOT NULL AND v_spell_element = v_target_resistant_element THEN
        v_armor_id := (SELECT a.id
                        FROM character c
                                 JOIN armor_set a ON c.armor_set_id = a.id
                        WHERE c.id = p_target_id);
        SELECT r.damage_reduction INTO v_resistance from armor_set r where r.id = v_armor_id;
        v_impact := v_impact / v_resistance;
    END IF;

    RETURN ROUND(v_impact);
END;
$$;

alter function calculate_spell_impact(integer, integer, integer) owner to postgres;



create or replace function calculate_attribute_bonus(p_character_id integer, p_attribute attribute_type) returns integer
    language plpgsql
as
$$
DECLARE
    v_attribute_bonus INTEGER;
BEGIN
    -- Get attribute bonus
    v_attribute_bonus := get_attribute_value(p_character_id, p_attribute) / 5;

    RETURN v_attribute_bonus;
END;
$$;

alter function calculate_attribute_bonus(integer, attribute_type) owner to postgres;

create or replace function calculate_hit_roll(p_character_id integer, p_attribute attribute_type) returns integer
    language plpgsql
as
$$
DECLARE
    v_d20_roll INTEGER;
    v_attribute_bonus INTEGER;
    v_hit_roll INTEGER;
BEGIN
    v_attribute_bonus := calculate_attribute_bonus(p_character_id, p_attribute);

    -- Perform a d20 roll and add the relevant attribute bonus
    v_d20_roll := 1 + floor(random() * 20)::INTEGER;
    v_hit_roll := v_d20_roll + v_attribute_bonus;

    RETURN v_hit_roll;
END;
$$;

alter function calculate_hit_roll(integer, attribute_type) owner to postgres;

create or replace function get_armor_class_value(p_character_id integer) returns integer
    language plpgsql
as
$$
DECLARE
    v_target_armor_class armor_class;
    v_armor_class_value INTEGER;
BEGIN
    SELECT a.armor_class INTO v_target_armor_class
    FROM character c
             LEFT JOIN armor_set a ON c.armor_set_id = a.id
    WHERE c.id = p_character_id;

    CASE v_target_armor_class
        WHEN 'CLOTH' THEN v_armor_class_value := 10;
        WHEN 'LEATHER' THEN v_armor_class_value := 13;
        WHEN 'HEAVY' THEN v_armor_class_value := 16;
        ELSE v_armor_class_value := 5; -- Default if no armor
        END CASE;

    RETURN v_armor_class_value;
END;
$$;

alter function get_armor_class_value(integer) owner to postgres;

create or replace function calculate_max_hp(p_character_id integer) returns integer
    language plpgsql
as
$$
DECLARE
    v_max_hp INTEGER;
BEGIN
    v_max_hp := 100 + get_attribute_value(p_character_id, 'HEALTH') * 5;

    RETURN v_max_hp;
END;
$$;

alter function calculate_max_hp(integer) owner to postgres;

create or replace function apply_spell_effect(
    p_caster_id integer,
    p_target_id integer,
    p_spell_id integer,
    p_hit_roll integer
) returns integer
    language plpgsql
as
$$
DECLARE
    v_spell_impact INTEGER;
    v_armor_class_value INTEGER;
    v_spell_impact_type spell_impact_type;
    v_max_hp INTEGER;
    v_effect_template_id BIGINT;
    v_effect_id BIGINT;
    v_duration_rounds INTEGER;
BEGIN
    SELECT spell_impact_type, cause_effect_id INTO v_spell_impact_type, v_effect_template_id
    FROM spell
    WHERE id = p_spell_id;

    v_spell_impact := calculate_spell_impact(p_spell_id, p_caster_id, p_target_id);

    v_armor_class_value := get_armor_class_value(p_target_id);

    v_max_hp := calculate_max_hp(p_target_id);

    IF v_spell_impact_type = 'HEALING' THEN
        UPDATE character
        SET hp = LEAST(v_max_hp, hp + v_spell_impact)
        WHERE id = p_target_id;
    ELSE
        IF p_hit_roll >= v_armor_class_value THEN
            UPDATE character
            SET hp = GREATEST(0, hp - v_spell_impact)
            WHERE id = p_target_id;
        ELSE
            v_spell_impact := 0;
        END IF;
    END IF;

    -- Check if the spell has an effect template
    IF v_effect_template_id IS NOT NULL AND (p_hit_roll >= v_armor_class_value OR v_spell_impact_type = 'HEALING') THEN
        -- Get the duration from the effect template
        SELECT duration_rounds INTO v_duration_rounds
        FROM effect_template
        WHERE id = v_effect_template_id;

        -- Create a new effect based on the template
        INSERT INTO effect (id, effect_template_id, rounds_left)
        VALUES (nextval('effect_seq'), v_effect_template_id, v_duration_rounds)
        RETURNING id INTO v_effect_id;

        -- Apply the effect to the target character
        INSERT INTO character_under_effects (character_id, under_effects_id)
        VALUES (p_target_id, v_effect_id);
    END IF;

    RETURN v_spell_impact;
END;
$$;

alter function apply_spell_effect(integer, integer, integer, integer) owner to postgres;

create or replace function calculate_and_apply_spell_impact(
    p_caster_id integer,
    p_target_id integer,
    p_spell_id integer
) returns integer
    language plpgsql
as
$$
DECLARE
    v_spell_scales_from VARCHAR;
    v_primary_attribute attribute_type;
    v_hit_roll INTEGER;
    v_spell_impact INTEGER;
BEGIN
    -- Get the spell's scaling attribute
    SELECT scales_from INTO v_spell_scales_from
    FROM spell
    WHERE id = p_spell_id;

    -- Get the primary attribute for the spell
    v_primary_attribute := (string_to_array(v_spell_scales_from, ','))[1]::attribute_type;

    -- Calculate the hit roll based on the primary attribute
    v_hit_roll := calculate_hit_roll(p_caster_id, v_primary_attribute);

    -- Apply the spell effect and get the impact value
    -- This will also create and apply any effect templates associated with the spell
    v_spell_impact := apply_spell_effect(p_caster_id, p_target_id, p_spell_id, v_hit_roll);

    RETURN v_spell_impact;
END;
$$;

alter function calculate_and_apply_spell_impact(integer, integer, integer) owner to postgres;


create or replace function calculate_required_ap(p_spell_id integer, p_character_id integer) returns integer
    language plpgsql
as
$$
DECLARE
    v_base_cost INTEGER;
    v_scales_from VARCHAR;
    v_attribute_types TEXT[];
    v_attribute_value INTEGER;
    v_attribute_factor DOUBLE PRECISION := 0;
    v_final_cost INTEGER;
BEGIN
    -- Get spell base cost and scales_from
    SELECT base_cost, scales_from INTO v_base_cost, v_scales_from
    FROM spell
    WHERE id = p_spell_id;

    -- Parse scales_from into array
    v_attribute_types := string_to_array(v_scales_from, ',');

    -- Calculate attribute factor
    FOR i IN 1..array_length(v_attribute_types, 1) LOOP
            v_attribute_value := get_attribute_value(p_character_id, v_attribute_types[i]::attribute_type);
            v_attribute_factor := v_attribute_factor + (v_attribute_value / (100 * array_length(v_attribute_types, 1)));
        END LOOP;

    v_final_cost := v_base_cost * (1 - v_attribute_factor);

    RETURN GREATEST(1, v_final_cost);
END;
$$;

alter function calculate_required_ap(integer, integer) owner to postgres;