-- DnD Combat System Database Schema - Combat Views

-- View: Combat Activity Summary
create or replace view combat_activity_summary as
select
    cl.actor_id,
    c.name as actor_name,
    count(*) as total_actions,
    sum(cl.action_points_spent) as total_ap_spent,
    sum(cl.impact) as total_impact,
    count(case when cl.impact > 0 then 1 end) as successful_hits,
    round(count(case when cl.impact > 0 then 1 end)::numeric / count(*)::numeric * 100, 2) as hit_percentage,
    avg(cl.impact) filter (where cl.impact > 0) as avg_impact_per_hit,
    max(cl.impact) as max_impact
from
    combat_log cl
        join character c on cl.actor_id = c.id
group by
    cl.actor_id, c.name;

-- View: Damage Received Summary
create or replace view damage_received_summary as
select
    cl.target_id,
    c.name as target_name,
    count(*) as times_targeted,
    sum(cl.impact) filter (where s.spell_impact_type = 'DAMAGE') as total_damage_received,
    sum(cl.impact) filter (where s.spell_impact_type = 'HEALING') as total_healing_received,
    avg(cl.impact) filter (where s.spell_impact_type = 'DAMAGE') as avg_damage_per_hit,
    max(cl.impact) filter (where s.spell_impact_type = 'HEALING') as max_damage_received
from
    combat_log cl
        join character c on cl.target_id = c.id
        left join spell s on cl.action_id = s.id
group by
    cl.target_id, c.name;

-- View: Current Combat State
create or replace view current_combat_state as
select
    l.id as location_id,
    l.name as location_name,
    r.id as round_id,
    r.index,
    count(distinct rp.participants_id) as active_participants,
    count(distinct cl.id) as actions_this_round
from
    location l
        join combat c on l.id = c.location_id
        join combat_combat_rounds cr on c.id = cr.combat_id
        join round r on cr.combat_rounds_id = r.id and r.is_finished = false
        left join round_participants rp on r.id = rp.round_id
        left join round_logs rl on r.id = rl.round_id
        left join combat_log cl on rl.logs_id = cl.id
group by
    l.id, l.name, r.id, r.index;

-- View: Combat Round Summary
create or replace view combat_round_summary as
select
    r.id as round_id,
    r.index,
    l.id as location_id,
    l.name as location_name,
    count(distinct cl.actor_id) as active_characters,
    count(cl.id) as total_actions,
    sum(cl.impact) filter (where s.spell_impact_type = 'DAMAGE') as total_damage_dealt,
    sum(cl.impact) filter (where s.spell_impact_type = 'HEALING') as total_healing_done,
    sum(cl.action_points_spent) as total_ap_spent
from
    round r
        join combat_combat_rounds cr on r.id = cr.combat_rounds_id
        join combat c on cr.combat_id = c.id
        join location l on c.location_id = l.id
        left join round_logs rl on r.id = rl.round_id
        left join combat_log cl on rl.logs_id = cl.id
        left join spell s on cl.action_id = s.id
group by
    r.id, r.index, l.id, l.name;