-- Procedure to handle a character's death
create or replace function sp_handle_player_death(
    p_character_id bigint
) returns void as $$
declare
    v_location_id bigint;
    v_inventory_id bigint;
    v_item_id bigint;
begin
    -- Get character's location and inventory
    select location_id, inventory_id
    into v_location_id, v_inventory_id
    from character
    where id = p_character_id;

    if v_location_id is null or v_inventory_id is null then
        raise exception 'Character not found or missing location/inventory';
    end if;

    -- Drop all items from character's inventory to their current location
    for v_item_id in (
        select items_id
        from inventory_items
        where inventory_id = v_inventory_id
    ) loop
            -- Add item to location floor
            insert into location_items_on_the_floor (location_id, items_on_the_floor_id)
            values (v_location_id, v_item_id);

            -- Remove item from inventory
            delete from inventory_items
            where inventory_id = v_inventory_id and items_id = v_item_id;
        end loop;

    -- Delete character's records in the correct order to avoid foreign key constraint violations

    -- Remove character from combat logs
    delete from combat_log_items_used
    where combat_log_id in (
        select id from combat_log where actor_id = p_character_id or target_id = p_character_id
    );

    delete from round_logs
    where logs_id in (
        select id from combat_log where actor_id = p_character_id or target_id = p_character_id
    );

    delete from combat_log
    where actor_id = p_character_id or target_id = p_character_id;

    -- Remove character from rounds
    delete from round_participants
    where participants_id = p_character_id;

    -- Remove character's effects
    delete from character_under_effects
    where character_id = p_character_id;

    -- Remove character's spells
    delete from character_spells
    where character_id = p_character_id;

    -- Remove character's attributes
    delete from character_attributes
    where character_id = p_character_id;

    -- Remove character from location
    delete from location_characters
    where characters_id = p_character_id;

    -- Finally, delete the character record
    delete from character
    where id = p_character_id;

    -- Delete the character's inventory
    delete from inventory
    where id = v_inventory_id;
end;
$$ language plpgsql;

alter function sp_handle_player_death(bigint) owner to postgres;