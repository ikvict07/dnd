create or replace procedure sp_use_item(
    p_character_id integer,
    p_item_id integer
) as
$$
declare
    v_inventory_id       integer;
    v_item_name          varchar(255);
    v_item_type          item_type;
    v_potion_id          integer;
    v_effect_template_id integer;
    v_effect_id          integer;
    v_log_id             bigint;
    v_combat_id          integer;
    v_active_round_id    integer;
begin
    select inventory_id
    into v_inventory_id
    from character
    where id = p_character_id;

    if v_inventory_id is null then
        raise exception 'character not found';
    end if;

    if not exists (select 1
                   from inventory_items
                   where inventory_id = v_inventory_id
                     and items_id = p_item_id) then
        raise exception 'item is not in the character''s inventory';
    end if;

    select i.name, i.type
    into v_item_name, v_item_type
    from item i
    where i.id = p_item_id;

    if v_item_type = 'potion'::item_type then
        select p.id, p.cause_effect_id
        into v_potion_id, v_effect_template_id
        from potion p
        where p.item_id = p_item_id;

        if v_effect_template_id is null then
            raise exception 'potion has no effect template';
        end if;

        v_effect_id := sp_apply_effect_from_template(v_effect_template_id, p_character_id);
    end if;

    delete
    from inventory_items
    where inventory_id = v_inventory_id
      and items_id = p_item_id;

    select c.id
    into v_combat_id
    from combat c
             join character ch on c.location_id = ch.location_id
             join round_participants rp on ch.id = rp.participants_id
             join round r on rp.round_id = r.id
    where ch.id = p_character_id
      and r.is_finished = false
    limit 1;

    if v_combat_id is not null then
        select r.id
        into v_active_round_id
        from round r
                 join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
        where ccr.combat_id = v_combat_id
          and r.is_finished = false
        limit 1;

        -- create a log entry
        insert into combat_log (action_points_spent,
                                impact,
                                description,
                                actor_id,
                                target_id)
        values (0,
                0,
                'character used item: ' || v_item_name,
                p_character_id,
                p_character_id
               )
        returning id into v_log_id;

        insert into combat_log_items_used (combat_log_id, items_used_id)
        values (v_log_id, p_item_id);

        insert into round_logs (logs_id, round_id)
        values (v_log_id, v_active_round_id);
    end if;
end;
$$ language plpgsql;

alter procedure sp_use_item(integer, integer) owner to postgres;