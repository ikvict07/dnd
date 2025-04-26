-- DnD Combat System Database Schema - Combat Views

-- View: Combat Activity Summary
CREATE VIEW combat_activity_summary AS
SELECT
    cl.actor_id,
    c.name AS actor_name,
    COUNT(*) AS total_actions,
    SUM(cl.action_points_spent) AS total_ap_spent,
    SUM(cl.impact) AS total_impact,
    COUNT(CASE WHEN cl.impact > 0 THEN 1 END) AS successful_hits,
    ROUND(COUNT(CASE WHEN cl.impact > 0 THEN 1 END)::numeric / COUNT(*)::numeric * 100, 2) AS hit_percentage,
    AVG(cl.impact) FILTER (WHERE cl.impact > 0) AS avg_impact_per_hit,
    MAX(cl.impact) AS max_impact
FROM
    combat_log cl
        JOIN character c ON cl.actor_id = c.id
GROUP BY
    cl.actor_id, c.name;

-- View: Damage Received Summary
CREATE VIEW damage_received_summary AS
SELECT
    cl.target_id,
    c.name AS target_name,
    COUNT(*) AS times_targeted,
    SUM(cl.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE') AS total_damage_received,
    SUM(cl.impact) FILTER (WHERE s.spell_impact_type = 'HEALING') AS total_healing_received,
    AVG(cl.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE') AS avg_damage_per_hit,
    MAX(cl.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE') AS max_damage_received
FROM
    combat_log cl
        JOIN character c ON cl.target_id = c.id
        LEFT JOIN spell s ON cl.action_id = s.id
GROUP BY
    cl.target_id, c.name;

-- View: Current Combat State
CREATE VIEW current_combat_state AS
SELECT
    l.id AS location_id,
    l.name AS location_name,
    r.id AS round_id,
    r.index,
    COUNT(DISTINCT rp.participants_id) AS active_participants,
    COUNT(DISTINCT cl.id) AS actions_this_round
FROM
    location l
        JOIN combat c ON l.id = c.location_id
        JOIN combat_combat_rounds cr ON c.id = cr.combat_id
        JOIN round r ON cr.combat_rounds_id = r.id AND r.is_finished = false
        LEFT JOIN round_participants rp ON r.id = rp.round_id
        LEFT JOIN round_logs rl ON r.id = rl.round_id
        LEFT JOIN combat_log cl ON rl.logs_id = cl.id
GROUP BY
    l.id, l.name, r.id, r.index;

-- View: Combat Round Summary
CREATE VIEW combat_round_summary AS
SELECT
    r.id AS round_id,
    r.index,
    l.id AS location_id,
    l.name AS location_name,
    COUNT(DISTINCT cl.actor_id) AS active_characters,
    COUNT(cl.id) AS total_actions,
    SUM(cl.impact) FILTER (WHERE s.spell_impact_type = 'DAMAGE') AS total_damage_dealt,
    SUM(cl.impact) FILTER (WHERE s.spell_impact_type = 'HEALING') AS total_healing_done,
    SUM(cl.action_points_spent) AS total_ap_spent
FROM
    round r
        JOIN combat_combat_rounds cr ON r.id = cr.combat_rounds_id
        JOIN combat c ON cr.combat_id = c.id
        JOIN location l ON c.location_id = l.id
        LEFT JOIN round_logs rl ON r.id = rl.round_id
        LEFT JOIN combat_log cl ON rl.logs_id = cl.id
        LEFT JOIN spell s ON cl.action_id = s.id
GROUP BY
    r.id, r.index, l.id, l.name;