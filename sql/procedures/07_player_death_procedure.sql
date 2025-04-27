-- Procedure to handle a character's death
create or replace procedure sp_handle_player_death(
    p_character_id bigint
) as $$
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

end;
$$ language plpgsql;

alter procedure sp_handle_player_death(bigint) owner to postgres;


create or replace function is_character_dead(
    p_character_id bigint
) returns boolean as $$
    declare
        v_is_dead boolean;
        v_character_id integer;
    begin
        select c.id
            from character c
            where id = p_character_id
        into v_character_id;

        if v_character_id is null then
            return true;
        end if;

        select c.hp <= 0 into v_is_dead
            from character c
            where id = p_character_id;


        raise notice 'Character % is % dead', p_character_id, v_is_dead;
        return v_is_dead;
    end;
$$ language plpgsql;

alter function is_character_dead(bigint) owner to postgres;