create or replace function get_inventory_weight(p_inventory_id integer) returns numeric
as
$$
DECLARE
    total_weight numeric;
BEGIN
    select sum(i.weight)
    into total_weight
    from inventory_items ii
             join item i on ii.items_id = i.id
    where ii.inventory_id = p_inventory_id;

    return total_weight;
END;
$$ language plpgsql;