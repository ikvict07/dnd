create or replace function sp_use_item(
    p_character_id integer,
    p_item_id integer
) returns void as
$$
declare
    v_inventory_id       integer;
    v_item_name          varchar(255);
    v_item_type          integer;
    v_potion_id          integer;
    v_effect_template_id integer;
    v_effect_id          integer;
    v_log_id             bigint;
    v_combat_id          integer;
    v_active_round_id    integer;
begin
    -- Get character's inventory
    select inventory_id
    into v_inventory_id
    from character
    where id = p_character_id;

    if v_inventory_id is null then
        raise exception 'Character not found';
    end if;

    -- Check if the item is in the character's inventory
    if not exists (select 1
                   from inventory_items
                   where inventory_id = v_inventory_id
                     and items_id = p_item_id) then
        raise exception 'Item is not in the character''s inventory';
    end if;

    -- Get item details
    select i.name, i.type
    into v_item_name, v_item_type
    from item i
    where i.id = p_item_id;

    -- If the item is a potion (type 2), apply its effect
    if v_item_type = 2 then
        -- Get the potion and its effect template
        select p.id, p.cause_effect_id
        into v_potion_id, v_effect_template_id
        from potion p
        where p.item_id = p_item_id;

        if v_effect_template_id is null then
            raise exception 'Potion has no effect template';
        end if;

        -- Apply the effect from the template to the character
        v_effect_id := sp_apply_effect_from_template(v_effect_template_id, p_character_id);
    end if;

    -- Remove the item from the inventory
    delete
    from inventory_items
    where inventory_id = v_inventory_id
      and items_id = p_item_id;

    -- Check if the character is in combat
    select c.id
    into v_combat_id
    from combat c
             join character ch on c.location_id = ch.location_id
             join round_participants rp on ch.id = rp.participants_id
             join round r on rp.round_id = r.id
    where ch.id = p_character_id
      and r.is_finished = false
    limit 1;

    -- If the character is in combat, add a log entry
    if v_combat_id is not null then
        -- Get the current active round for this combat
        select r.id
        into v_active_round_id
        from round r
                 join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
        where ccr.combat_id = v_combat_id
          and r.is_finished = false
        limit 1;

        -- Create a log entry
        insert into combat_log (id,
                                action_points_spent,
                                impact,
                                description,
                                actor_id,
                                target_id)
        values (nextval('combat_seq'),
                0, -- No AP spent for using an item
                0, -- No direct impact value for using an item
                'Character used item: ' || v_item_name,
                p_character_id,
                p_character_id -- Target is self
               )
        returning id into v_log_id;

        -- Add the item to the combat log
        insert into combat_log_items_used (combat_log_id, items_used_id)
        values (v_log_id, p_item_id);

        -- Add log to current round
        insert into round_logs (logs_id, round_id)
        values (v_log_id, v_active_round_id);
    end if;
end;
$$ language plpgsql;

alter function sp_use_item(integer, integer) owner to postgres;