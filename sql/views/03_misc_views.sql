-- DnD Combat System Database Schema - Miscellaneous Views

-- View: Spell Usage Statistics
create view spell_usage_statistics as
select
    s.id as spell_id,
    s.name as spell_name,
    s.spell_category,
    s.spell_element,
    s.spell_impact_type,
    count(*) as times_used,
    sum(cl.impact) as total_impact,
    avg(cl.impact) as avg_impact,
    count(distinct cl.actor_id) as unique_users
from
    spell s
        join combat_log cl on s.id = cl.action_id
group by
    s.id, s.name, s.spell_category, s.spell_element, s.spell_impact_type;

-- View: Location Item Summary
create view location_item_summary as
select
    l.id as location_id,
    l.name as location_name,
    count(it.id) as items_on_floor,
    sum(case when it.type = 'ARMOR' then 1 else 0 end) as armor_count,
    sum(case when it.type = 'WEAPON' then 1 else 0 end) as weapon_count,
    sum(case when it.type = 'POTION' then 1 else 0 end) as potion_count,
    sum(case when it.type = 'TROPHY' then 1 else 0 end) as trophy_count,
    sum(it.weight) as total_weight
from
    location l
        left join location_items_on_the_floor lif on l.id = lif.location_id
        left join item it on lif.items_on_the_floor_id = it.id
group by
    l.id, l.name;

-- View: Effect Analysis
create view effect_analysis as
select
    et.id as effect_template_id,
    et.effect_name,
    et.effect as effect_type,
    et.affected_attribute_type,
    et.value as modifier_value,
    et.duration_rounds,
    count(e.id) as active_instances,
    count(distinct cue.character_id) as affected_characters,
    avg(e.rounds_left) as avg_remaining_rounds
from
    effect_template et
        left join effect e on et.id = e.effect_template_id
        left join character_under_effects cue on e.id = cue.under_effects_id
group by
    et.id, et.effect_name, et.effect, et.affected_attribute_type, et.value, et.duration_rounds;