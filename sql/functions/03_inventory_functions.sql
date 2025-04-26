CREATE OR REPLACE FUNCTION dnd.get_inventory_weight(p_inventory_id INTEGER)
    RETURNS NUMERIC AS $$
BEGIN
    RETURN (SELECT COALESCE(SUM(i.weight), 0)
            FROM inventory_items ii
                     JOIN item i ON ii.items_id = i.id
            WHERE ii.inventory_id = p_inventory_id::bigint);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_item_to_inventory(
    p_inventory_id BIGINT,
    p_item_id BIGINT
) RETURNS VOID AS $$
BEGIN
    -- Check if inventory has enough capacity
    DECLARE
        current_weight NUMERIC;
        item_weight NUMERIC;
        inventory_capacity NUMERIC;
    BEGIN
        SELECT capacity INTO inventory_capacity
        FROM inventory
        WHERE id = p_inventory_id;

        SELECT COALESCE(SUM(i.weight), 0) INTO current_weight
        FROM inventory_items ii
                 JOIN item i ON ii.items_id = i.id
        WHERE ii.inventory_id = p_inventory_id;

        SELECT weight INTO item_weight
        FROM item
        WHERE id = p_item_id;

        IF current_weight + item_weight <= inventory_capacity THEN
            INSERT INTO inventory_items (inventory_id, items_id)
            VALUES (p_inventory_id, p_item_id);
        ELSE
            RAISE EXCEPTION 'Inventory capacity exceeded';
        END IF;
    END;
END;
$$ LANGUAGE plpgsql;