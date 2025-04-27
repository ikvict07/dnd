create or replace function get_attribute_value(p_character_id integer, p_attribute_type attribute_type) returns integer
as
$$
DECLARE
    v_value INTEGER;
BEGIN
    SELECT value
    INTO v_value
    FROM attribute
             join character_attributes on attribute.id = character_attributes.attributes_id
    WHERE character_id = p_character_id
      AND attribute_type::text = p_attribute_type::text;

    RETURN coalesce(v_value, 0);
END;
$$ language plpgsql;

alter function get_attribute_value(integer, attribute_type) owner to postgres;