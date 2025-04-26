-- DnD Combat System Database Schema - Reporting Views

-- View: Combat State
-- Displays the current round, list of active characters, and their remaining AP.
CREATE VIEW v_combat_state AS
SELECT 
    r.id AS round_id,
    r.index AS round_number,
    r.is_finished,
    c.id AS character_id,
    c.name AS character_name,
    c.action_points AS remaining_ap,
    c.hp AS remaining_hp,
    cl.name AS class_name
FROM 
    round r
    JOIN round_participants rp ON r.id = rp.round_id
    JOIN character c ON rp.participants_id = c.id
    LEFT JOIN class cl ON c.character_class_id = cl.id
WHERE 
    r.is_finished = FALSE
ORDER BY 
    r.id, c.action_points DESC;

-- View: Most Damage
-- Ranks characters by total damage dealt across all combats.
CREATE VIEW v_most_damage AS
SELECT 
    c.id AS character_id,
    c.name AS character_name,
    c.lvl AS character_level,
    cl.name AS class_name,
    SUM(cl2.impact) AS total_damage_dealt,
    COUNT(cl2.id) AS total_attacks,
    ROUND(SUM(cl2.impact)::numeric / NULLIF(COUNT(cl2.id), 0), 2) AS avg_damage_per_attack,
    MAX(cl2.impact) AS max_damage_dealt
FROM 
    character c
    LEFT JOIN class cl ON c.character_class_id = cl.id
    LEFT JOIN combat_log cl2 ON c.id = cl2.actor_id
    LEFT JOIN spell s ON cl2.action_id = s.id
WHERE 
    s.spell_impact_type = 'DAMAGE'
GROUP BY 
    c.id, c.name, c.lvl, cl.name
ORDER BY 
    total_damage_dealt DESC;

-- View: Strongest Characters
-- Lists characters ordered by aggregated performance metrics.
CREATE VIEW v_strongest_characters AS
SELECT 
    c.id AS character_id,
    c.name AS character_name,
    c.lvl AS character_level,
    c.hp AS current_hp,
    cl.name AS class_name,
    -- Damage dealt
    COALESCE(SUM(cl2.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE'), 0) AS total_damage_dealt,
    -- Healing done
    COALESCE(SUM(cl2.impact) FILTER (WHERE s.spell_impact_type = 'HEALING'), 0) AS total_healing_done,
    -- Successful attacks
    COUNT(cl2.id) FILTER (WHERE cl2.impact > 0 AND s.spell_impact_type = 'DAMAGE') AS successful_attacks,
    -- Damage received
    COALESCE((SELECT SUM(cl3.impact) FROM combat_log cl3 
              JOIN spell s2 ON cl3.action_id = s2.id 
              WHERE cl3.target_id = c.id AND s2.spell_impact_type = 'DAMAGE'), 0) AS damage_received,
    -- Performance score (custom formula)
    COALESCE(SUM(cl2.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE'), 0) + 
    COALESCE(SUM(cl2.impact) FILTER (WHERE s.spell_impact_type = 'HEALING'), 0) * 0.5 - 
    COALESCE((SELECT SUM(cl3.impact) FROM combat_log cl3 
              JOIN spell s2 ON cl3.action_id = s2.id 
              WHERE cl3.target_id = c.id AND s2.spell_impact_type = 'DAMAGE'), 0) * 0.3 + 
    c.hp * 0.2 AS performance_score
FROM 
    character c
    LEFT JOIN class cl ON c.character_class_id = cl.id
    LEFT JOIN combat_log cl2 ON c.id = cl2.actor_id
    LEFT JOIN spell s ON cl2.action_id = s.id
GROUP BY 
    c.id, c.name, c.lvl, c.hp, cl.name
ORDER BY 
    performance_score DESC;

-- View: Combat Damage
-- Summarizes total damage inflicted in each combat session.
CREATE VIEW v_combat_damage AS
SELECT 
    c.id AS combat_id,
    l.name AS location_name,
    COUNT(DISTINCT r.id) AS total_rounds,
    COUNT(DISTINCT cl.actor_id) AS total_participants,
    SUM(cl.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE') AS total_damage_dealt,
    SUM(cl.impact) FILTER (WHERE s.spell_impact_type = 'HEALING') AS total_healing_done,
    ROUND(SUM(cl.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE')::numeric / 
          NULLIF(COUNT(DISTINCT r.id), 0), 2) AS avg_damage_per_round,
    MAX(cl.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE') AS max_damage_in_single_action
FROM 
    combat c
    JOIN location l ON c.location_id = l.id
    JOIN combat_combat_rounds ccr ON c.id = ccr.combat_id
    JOIN round r ON ccr.combat_rounds_id = r.id
    JOIN round_logs rl ON r.id = rl.round_id
    JOIN combat_log cl ON rl.logs_id = cl.id
    LEFT JOIN spell s ON cl.action_id = s.id
GROUP BY 
    c.id, l.name
ORDER BY 
    total_damage_dealt DESC;

-- View: Spell Statistics
-- Spell usage and damage statistics.
CREATE VIEW v_spell_statistics AS
SELECT 
    s.id AS spell_id,
    s.name AS spell_name,
    s.spell_category,
    s.spell_element,
    s.spell_impact_type,
    COUNT(cl.id) AS times_used,
    COUNT(DISTINCT cl.actor_id) AS unique_users,
    SUM(cl.impact) AS total_impact,
    ROUND(AVG(cl.impact), 2) AS avg_impact,
    MAX(cl.impact) AS max_impact,
    MIN(cl.impact) FILTER (WHERE cl.impact > 0) AS min_impact,
    ROUND(SUM(cl.impact)::numeric / NULLIF(SUM(cl.action_points_spent), 0), 2) AS impact_per_ap_spent,
    ROUND(COUNT(CASE WHEN cl.impact > 0 THEN 1 END)::numeric / NULLIF(COUNT(cl.id), 0) * 100, 2) AS success_rate
FROM 
    spell s
    LEFT JOIN combat_log cl ON s.id = cl.action_id
GROUP BY 
    s.id, s.name, s.spell_category, s.spell_element, s.spell_impact_type
ORDER BY 
    times_used DESC, total_impact DESC;
