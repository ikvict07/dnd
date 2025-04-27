-- view: character stats summary
create or replace view character_stats_summary as
select
    c.id as character_id,
    c.name as character_name,
    c.hp,
    c.lvl,
    c.xp,
    cl.name as class_name,
    cl.main_attribute,
    l.name as location_name,
    l.is_pvp as in_pvp_zone,
    (select count(*) from character_spells where character_id = c.id) as spell_count,
    (select count(*) from character_under_effects where character_id = c.id) as active_effects_count,
    w.name as weapon_name,
    a.name as armor_name,
    a.protects_from as armor_resistance
from
    character c
        left join class cl on c.character_class_id = cl.id
        left join location l on c.location_id = l.id
        left join weapon w on c.weapon_id = w.id
        left join armor_set a on c.armor_set_id = a.id;

-- view: character attributes
create or replace view character_attributes_view as
select
    c.id as character_id,
    c.name as character_name,
    a.attribute_type,
    a.value
from
    character c
        join character_attributes ca on c.id = ca.character_id
        join attribute a on ca.attributes_id = a.id;

-- view: character inventory summary
create or replace view character_inventory_summary as
select
    c.id as character_id,
    c.name as character_name,
    i.capacity as max_capacity,
    get_inventory_weight(i.id::integer) as current_used,
    (i.capacity - get_inventory_weight(i.id::integer)) as available_space,
    count(it.id) as item_count,
    sum(case when it.type = 'armor'::item_type then 1 else 0 end) as armor_count,
    sum(case when it.type = 'weapon'::item_type then 1 else 0 end) as weapon_count,
    sum(case when it.type = 'potion'::item_type then 1 else 0 end) as potion_count,
    sum(case when it.type = 'trophy'::item_type then 1 else 0 end) as trophy_count
from
    character c
        join inventory i on c.inventory_id = i.id
        left join inventory_items ii on i.id = ii.inventory_id
        left join item it on ii.items_id = it.id
group by
    c.id, c.name, i.capacity, get_inventory_weight(i.id::integer);