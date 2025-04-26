-- DnD Combat System Database Schema - Miscellaneous Views

-- View: Spell Usage Statistics
CREATE VIEW spell_usage_statistics AS
SELECT 
    s.id AS spell_id,
    s.name AS spell_name,
    s.spell_category,
    s.spell_element,
    s.spell_impact_type,
    COUNT(*) AS times_used,
    SUM(cl.impact) AS total_impact,
    AVG(cl.impact) AS avg_impact,
    COUNT(DISTINCT cl.actor_id) AS unique_users
FROM 
    spell s
    JOIN combat_log cl ON s.id = cl.action_id
GROUP BY 
    s.id, s.name, s.spell_category, s.spell_element, s.spell_impact_type;

-- View: Location Item Summary
CREATE VIEW location_item_summary AS
SELECT 
    l.id AS location_id,
    l.name AS location_name,
    COUNT(it.id) AS items_on_floor,
    SUM(CASE WHEN it.type = 0 THEN 1 ELSE 0 END) AS armor_count,
    SUM(CASE WHEN it.type = 1 THEN 1 ELSE 0 END) AS weapon_count,
    SUM(CASE WHEN it.type = 2 THEN 1 ELSE 0 END) AS potion_count,
    SUM(CASE WHEN it.type = 3 THEN 1 ELSE 0 END) AS trophy_count,
    SUM(it.weight) AS total_weight
FROM 
    location l
    LEFT JOIN location_items_on_the_floor lif ON l.id = lif.location_id
    LEFT JOIN item it ON lif.items_on_the_floor_id = it.id
GROUP BY 
    l.id, l.name;

-- View: Effect Analysis
CREATE VIEW effect_analysis AS
SELECT 
    et.id AS effect_template_id,
    et.effect_name,
    et.effect AS effect_type,
    et.affected_attribute_type,
    et.value AS modifier_value,
    et.duration_rounds,
    COUNT(e.id) AS active_instances,
    COUNT(DISTINCT cue.character_id) AS affected_characters,
    AVG(e.rounds_left) AS avg_remaining_rounds
FROM 
    effect_template et
    LEFT JOIN effect e ON et.id = e.effect_template_id
    LEFT JOIN character_under_effects cue ON e.id = cue.under_effects_id
GROUP BY 
    et.id, et.effect_name, et.effect, et.affected_attribute_type, et.value, et.duration_rounds;