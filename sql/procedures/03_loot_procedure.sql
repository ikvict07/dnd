-- Function to handle a character looting an item from a combat area
create or replace procedure sp_loot_item(
    p_combat_id integer,
    p_character_id integer,
    p_item_id integer
) as $$
declare
    v_character_location_id integer;
    v_inventory_id integer;
    v_constitution_value integer;
    v_class_id integer;
    v_base_inventory_size integer;
    v_max_capacity integer;
    v_current_size double precision;
    v_item_weight double precision;
    v_item_name varchar(255);
    v_log_id bigint;
    v_location_id integer;
begin
    -- Check that the item is available in the combat area
    select l.id into v_location_id
    from combat c
             join location l on c.location_id = l.id
    where c.id = p_combat_id;

    if v_location_id is null then
        raise exception 'Combat area not found';
    end if;

    -- Get character's location and inventory
    select location_id, inventory_id, character_class_id
    into v_character_location_id, v_inventory_id, v_class_id
    from character
    where id = p_character_id;

    -- Check if item is in the combat area location
    if not exists (
        select 1
        from location_items_on_the_floor
        where location_id = v_location_id and items_on_the_floor_id = p_item_id
    ) then
        raise exception 'Item is not in the combat area';
    end if;

    -- Check if character is in the combat area
    if v_character_location_id != v_location_id then
        raise exception 'Character is not in the combat area';
    end if;

    -- Get item weight and name
    select weight, name into v_item_weight, v_item_name
    from item
    where id = p_item_id;

    -- Get character's constitution
    v_constitution_value := get_attribute_value(p_character_id, 'CONSTITUTION');

    -- Get base inventory size from class
    select inventory_multiplier * 10 into v_base_inventory_size
    from class
    where id = v_class_id;

    v_max_capacity := v_base_inventory_size * (1 + (v_constitution_value / 100.0));

    -- Calculate current inventory size
    v_current_size := get_inventory_weight(v_inventory_id);
    -- Check if item fits in inventory
    if v_current_size + v_item_weight > v_max_capacity then
        raise exception 'Not enough inventory space';
    end if;

    -- Remove item from location
    delete from location_items_on_the_floor
    where location_id = v_location_id and items_on_the_floor_id = p_item_id;

    -- Add item to inventory
    insert into inventory_items (inventory_id, items_id)
    values (v_inventory_id, p_item_id);

    -- Log the looting event in the combat log
    insert into combat_log (
        id,
        action_points_spent,
        impact,
        description,
        actor_id,
        target_id
    ) values (
                 nextval('combat_seq'),
                 0,  -- No AP spent for looting
                 0,  -- No impact value for looting
                 'Character looted item: ' || v_item_name,
                 p_character_id,
                 p_character_id  -- Target is self
             ) returning id into v_log_id;

    -- Add the item to the combat log
    insert into combat_log_items_used (combat_log_id, items_used_id)
    values (v_log_id, p_item_id);

    -- Add log to current round if in combat
    insert into round_logs (logs_id, round_id)
    select v_log_id, r.id
    from round r
             join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
             join combat c on ccr.combat_id = c.id
    where c.id = p_combat_id
      and r.is_finished = false
    limit 1;
end;
$$ language plpgsql;

alter procedure sp_loot_item(integer, integer, integer) owner to postgres;