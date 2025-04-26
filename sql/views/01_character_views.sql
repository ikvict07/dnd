-- DnD Combat System Database Schema - Character Views

-- View: Character Stats Summary
CREATE VIEW character_stats_summary AS
SELECT 
    c.id AS character_id,
    c.name AS character_name,
    c.hp,
    c.lvl,
    c.xp,
    cl.name AS class_name,
    cl.main_attribute,
    l.name AS location_name,
    l.is_pvp AS in_pvp_zone,
    (SELECT COUNT(*) FROM character_spells WHERE character_id = c.id) AS spell_count,
    (SELECT COUNT(*) FROM character_under_effects WHERE character_id = c.id) AS active_effects_count,
    w.name AS weapon_name,
    a.name AS armor_name,
    a.protects_from AS armor_resistance
FROM 
    character c
    LEFT JOIN class cl ON c.character_class_id = cl.id
    LEFT JOIN location l ON c.location_id = l.id
    LEFT JOIN weapon w ON c.weapon_id = w.id
    LEFT JOIN armor_set a ON c.armor_set_id = a.id;

-- View: Character Attributes
CREATE VIEW character_attributes_view AS
SELECT 
    c.id AS character_id,
    c.name AS character_name,
    a.attribute_type,
    a.value
FROM 
    character c
    JOIN character_attributes ca ON c.id = ca.character_id
    JOIN attribute a ON ca.attributes_id = a.id;

-- View: Character Inventory Summary
CREATE VIEW character_inventory_summary AS
SELECT 
    c.id AS character_id,
    c.name AS character_name,
    i.capacity AS max_capacity,
    i.current_size AS current_used,
    (i.capacity - i.current_size) AS available_space,
    COUNT(it.id) AS item_count,
    SUM(CASE WHEN it.type = 0 THEN 1 ELSE 0 END) AS armor_count,
    SUM(CASE WHEN it.type = 1 THEN 1 ELSE 0 END) AS weapon_count,
    SUM(CASE WHEN it.type = 2 THEN 1 ELSE 0 END) AS potion_count,
    SUM(CASE WHEN it.type = 3 THEN 1 ELSE 0 END) AS trophy_count
FROM 
    character c
    JOIN inventory i ON c.inventory_id = i.id
    LEFT JOIN inventory_items ii ON i.id = ii.inventory_id
    LEFT JOIN item it ON ii.items_id = it.id
GROUP BY 
    c.id, c.name, i.capacity, i.current_size;