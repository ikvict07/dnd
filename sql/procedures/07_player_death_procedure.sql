create or replace procedure sp_handle_player_death(
    p_character_id bigint
) as $$
declare
    v_location_id bigint;
    v_inventory_id bigint;
    v_item_id bigint;
begin
    select location_id, inventory_id
    into v_location_id, v_inventory_id
    from character
    where id = p_character_id;

    if v_location_id is null or v_inventory_id is null then
        raise exception 'character not found or missing location/inventory';
    end if;

    for v_item_id in (
        select items_id
        from inventory_items
        where inventory_id = v_inventory_id
    ) loop
            insert into location_items_on_the_floor (location_id, items_on_the_floor_id)
            values (v_location_id, v_item_id);

            delete from inventory_items
            where inventory_id = v_inventory_id and items_id = v_item_id;
        end loop;

    delete from round_participants
    where participants_id = p_character_id;

    delete from character_under_effects
    where character_id = p_character_id;

    delete from character_spells
    where character_id = p_character_id;

    delete from character_attributes
    where character_id = p_character_id;

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


        raise notice 'character % is % dead', p_character_id, v_is_dead;
        return v_is_dead;
    end;
$$ language plpgsql;

alter function is_character_dead(bigint) owner to postgres;