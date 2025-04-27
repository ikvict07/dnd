create or replace function get_attribute_value(p_character_id integer, p_attribute_type attribute_type) returns integer
as
$$
declare
    v_value integer;
begin
    select value
    into v_value
    from attribute
             join character_attributes on attribute.id = character_attributes.attributes_id
    where character_id = p_character_id
      and attribute_type::text = p_attribute_type::text;

    return coalesce(v_value, 0);
end;
$$ language plpgsql;

alter function get_attribute_value(integer, attribute_type) owner to postgres;