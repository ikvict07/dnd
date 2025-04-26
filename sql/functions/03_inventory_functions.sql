create or replace function dnd.get_inventory_weight(p_inventory_id integer)
    returns numeric as $$
begin
    return (select coalesce(sum(i.weight), 0)
            from inventory_items ii
                     join item i on ii.items_id = i.id
            where ii.inventory_id = p_inventory_id::bigint);
end;
$$ language plpgsql;


create or replace function add_item_to_inventory(
    p_inventory_id bigint,
    p_item_id bigint
) returns void as $$
begin
    -- Check if inventory has enough capacity
    declare
        current_weight numeric;
        item_weight numeric;
        inventory_capacity numeric;
    begin
        select capacity into inventory_capacity
        from inventory
        where id = p_inventory_id;

        select coalesce(sum(i.weight), 0) into current_weight
        from inventory_items ii
                 join item i on ii.items_id = i.id
        where ii.inventory_id = p_inventory_id;

        select weight into item_weight
        from item
        where id = p_item_id;

        if current_weight + item_weight <= inventory_capacity then
            insert into inventory_items (inventory_id, items_id)
            values (p_inventory_id, p_item_id);
        else
            raise exception 'Inventory capacity exceeded';
        end if;
    end;
end;
$$ language plpgsql;