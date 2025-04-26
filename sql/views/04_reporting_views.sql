-- DnD Combat System Database Schema - Reporting Views

-- View: Combat State
-- Displays the current round, list of active characters, and their remaining AP.
create view v_combat_state as
select r.id            as round_id,
       r.index         as round_number,
       r.is_finished,
       c.id            as character_id,
       c.name          as character_name,
       c.action_points as remaining_ap,
       c.hp            as remaining_hp,
       cl.name         as class_name,
       ccr.combat_id          as combat_id
from round r
         join round_participants rp on r.id = rp.round_id
         join character c on rp.participants_id = c.id
         left join class cl on c.character_class_id = cl.id
         join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id

where r.is_finished = false
order by r.id, c.action_points desc;

-- View: Most Damage
-- Ranks characters by total damage dealt across all combats.
create view v_most_damage as
select c.id                                                          as character_id,
       c.name                                                        as character_name,
       c.lvl                                                         as character_level,
       cl.name                                                       as class_name,
       sum(cl2.impact)                                               as total_damage_dealt,
       count(cl2.id)                                                 as total_attacks,
       round(sum(cl2.impact)::numeric / nullif(count(cl2.id), 0), 2) as avg_damage_per_attack,
       max(cl2.impact)                                               as max_damage_dealt
from character c
         left join class cl on c.character_class_id = cl.id
         left join combat_log cl2 on c.id = cl2.actor_id
         left join spell s on cl2.action_id = s.id
where s.spell_impact_type = 1
group by c.id, c.name, c.lvl, cl.name
order by total_damage_dealt desc;

-- View: Strongest Characters
-- Lists characters ordered by aggregated performance metrics.
create view v_strongest_characters as
select c.id                                                                    as character_id,
       c.name                                                                  as character_name,
       c.lvl                                                                   as character_level,
       c.hp                                                                    as current_hp,
       cl.name                                                                 as class_name,
       -- Damage dealt
       coalesce(sum(cl2.impact) filter (where s.spell_impact_type = 1), 0)     as total_damage_dealt,
       -- Healing done
       coalesce(sum(cl2.impact) filter (where s.spell_impact_type = 2), 0)     as total_healing_done,
       -- Successful attacks
       count(cl2.id) filter (where cl2.impact > 0 and s.spell_impact_type = 1) as successful_attacks,
       -- Damage received
       coalesce((select sum(cl3.impact)
                 from combat_log cl3
                          join spell s2 on cl3.action_id = s2.id
                 where cl3.target_id = c.id
                   and s2.spell_impact_type = 1), 0)                           as damage_received,
       -- Performance score (custom formula)
       coalesce(sum(cl2.impact) filter (where s.spell_impact_type = 1), 0) +
       coalesce(sum(cl2.impact) filter (where s.spell_impact_type = 2), 0) * 0.5 -
       coalesce((select sum(cl3.impact)
                 from combat_log cl3
                          join spell s2 on cl3.action_id = s2.id
                 where cl3.target_id = c.id
                   and s2.spell_impact_type = 1), 0) * 0.3 +
       c.hp * 0.2                                                              as performance_score
from character c
         left join class cl on c.character_class_id = cl.id
         left join combat_log cl2 on c.id = cl2.actor_id
         left join spell s on cl2.action_id = s.id
group by c.id, c.name, c.lvl, c.hp, cl.name
order by performance_score desc;

-- View: Combat Damage
-- Summarizes total damage inflicted in each combat session.
create view v_combat_damage as
select c.id                                                  as combat_id,
       l.name                                                as location_name,
       count(distinct r.id)                                  as total_rounds,
       count(distinct cl.actor_id)                           as total_participants,
       sum(cl.impact) filter (where s.spell_impact_type = 1) as total_damage_dealt,
       sum(cl.impact) filter (where s.spell_impact_type = 2) as total_healing_done,
       round(sum(cl.impact) filter (where s.spell_impact_type = 1)::numeric /
             nullif(count(distinct r.id), 0), 2)             as avg_damage_per_round,
       max(cl.impact) filter (where s.spell_impact_type = 1) as max_damage_in_single_action
from combat c
         join location l on c.location_id = l.id
         join combat_combat_rounds ccr on c.id = ccr.combat_id
         join round r on ccr.combat_rounds_id = r.id
         join round_logs rl on r.id = rl.round_id
         join combat_log cl on rl.logs_id = cl.id
         left join spell s on cl.action_id = s.id
group by c.id, l.name
order by total_damage_dealt desc;

-- View: Spell Statistics
-- Spell usage and damage statistics.
create view v_spell_statistics as
select s.id                                                                                         as spell_id,
       s.name                                                                                       as spell_name,
       s.spell_category,
       s.spell_element,
       s.spell_impact_type,
       count(cl.id)                                                                                 as times_used,
       count(distinct cl.actor_id)                                                                  as unique_users,
       sum(cl.impact)                                                                               as total_impact,
       round(avg(cl.impact), 2)                                                                     as avg_impact,
       max(cl.impact)                                                                               as max_impact,
       min(cl.impact) filter (where cl.impact > 0)                                                  as min_impact,
       round(sum(cl.impact)::numeric / nullif(sum(cl.action_points_spent), 0),
             2)                                                                                     as impact_per_ap_spent,
       round(count(case when cl.impact > 0 then 1 end)::numeric / nullif(count(cl.id), 0) * 100, 2) as success_rate
from spell s
         left join combat_log cl on s.id = cl.action_id
group by s.id, s.name, s.spell_category, s.spell_element, s.spell_impact_type
order by times_used desc, total_impact desc;