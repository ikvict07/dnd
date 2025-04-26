# DnD Combat System Database Schema

This document provides a comprehensive description of the DnD Combat System database schema, including tables, relationships, functions, procedures, and views.

## Overview

The DnD Combat System is a database schema designed to support a role-playing game with combat mechanics, character progression, and inventory management. The schema includes tables for characters, classes, attributes, spells, items, combat logs, and more.

## File Structure

The database schema is organized into the following directories:

- `sql/schema/`: Contains files for sequences, enums, tables, and indexes
- `sql/functions/`: Contains files for database functions
- `sql/procedures/`: Contains files for stored procedures
- `sql/views/`: Contains files for database views
- `sql/data/`: Contains files for example data
- `sql/tests/`: Contains files for acceptance tests

The main entry point is `sql/main.sql`, which includes all the other files in the correct order.

## Tables and Relationships

### Character System

- **character**: Represents a player character or NPC in the game
  - Relationships:
    - Has one character class (character_class_id)
    - Has one inventory (inventory_id)
    - Has one location (location_id)
    - Has one weapon (weapon_id)
    - Has one armor set (armor_set_id)
    - Has many attributes (via character_attributes)
    - Has many spells (via character_spells)
    - Has many effects (via character_under_effects)

- **class**: Represents a character class (e.g., Warrior, Mage)
  - Attributes:
    - name: The name of the class
    - main_attribute: The primary attribute for the class
    - armor_class: The preferred armor class
    - inventory_multiplier: Affects inventory capacity
    - action_points_multiplier: Affects action points in combat

- **attribute**: Represents a character attribute (e.g., Strength, Intelligence)
  - Attributes:
    - attribute_type: The type of attribute (enum)
    - value: The numeric value of the attribute

### Inventory and Items

- **inventory**: Represents a character's inventory
  - Attributes:
    - capacity: The maximum capacity of the inventory
    - current_size: The current used capacity

- **item**: Represents an item in the game
  - Attributes:
    - name: The name of the item
    - type: The type of item (enum)
    - weight: The weight of the item

- **weapon**: Represents a weapon item
  - Relationships:
    - Belongs to one item (item_id)
  - Attributes:
    - damage_multiplier: Affects damage output
    - action_points_multiplier: Affects action points cost
    - scales_from: The attribute that affects damage

- **armor_set**: Represents an armor item
  - Relationships:
    - Belongs to one item (item_id)
  - Attributes:
    - damage_reduction: Affects damage taken
    - swiftness: Affects dodge chance
    - protects_from: The element it provides resistance against

- **potion**: Represents a potion item
  - Relationships:
    - Belongs to one item (item_id)
    - Has one effect template (cause_effect_id)

### Combat System

- **spell**: Represents a spell that can be cast
  - Attributes:
    - base_cost: The base action points cost
    - is_pvp: Whether it can be used in PvP
    - spell_category: The category of spell (enum)
    - spell_element: The elemental type (enum)
    - scales_from: The attributes that affect the spell
    - spell_impact_type: Whether it deals damage or heals (enum)
    - range: The range of the spell
    - value: The base value of the spell
  - Relationships:
    - May have one effect template (cause_effect_id)

- **effect_template**: Represents a template for effects
  - Attributes:
    - effect_name: The name of the effect
    - effect: The type of effect (enum)
    - affected_attribute_type: The attribute affected
    - value: The modifier value
    - duration_rounds: How long the effect lasts

- **effect**: Represents an active effect on a character
  - Relationships:
    - Belongs to one effect template (effect_template_id)
    - Belongs to one character (character_id)
  - Attributes:
    - rounds_left: How many rounds remain

- **combat**: Represents a combat encounter
  - Relationships:
    - Belongs to one location (location_id)
    - Has many rounds (via combat_combat_rounds)

- **round**: Represents a round in combat
  - Attributes:
    - index: The round number
    - is_finished: Whether the round is complete
  - Relationships:
    - Has many participants (via round_participants)
    - Has many logs (via round_logs)

- **combat_log**: Represents an action in combat
  - Relationships:
    - Has one actor (actor_id)
    - Has one action (action_id)
    - Has one target (target_id)
    - May have one caused effect (caused_effect_id)
    - Has many items used (via combat_log_items_used)
  - Attributes:
    - action_points_spent: How many AP were spent
    - impact: The damage or healing done

### Location System

- **location**: Represents a location in the game
  - Attributes:
    - name: The name of the location
    - is_pvp: Whether PvP is allowed
  - Relationships:
    - Has many characters (via location_characters)
    - Has many items on the floor (via location_items_on_the_floor)

## Functions

### Attribute Functions

- **get_attribute_value(p_character_id, p_attribute_type)**: Gets the value of a specific attribute for a character

### Spell Functions

- **calculate_required_ap(p_spell_id, p_character_id)**: Calculates the AP cost for a spell based on character attributes
- **calculate_hit_chance(p_actor_id, p_target_id)**: Calculates the chance to hit based on actor and target attributes
- **calculate_spell_impact(p_spell_id, p_actor_id, p_target_id)**: Calculates the impact (damage or healing) of a spell

## Procedures

### Spell Procedures

- **cast_spell(p_actor_id, p_spell_id, p_target_id, p_combat_round_id)**: Handles the spell casting process
- **character_rest(p_character_id)**: Allows a character to rest and recover HP

### Character Procedures

- **process_character_death(p_character_id)**: Handles what happens when a character dies
- **apply_effect_to_character(p_effect_id, p_character_id)**: Applies an effect to a character
- **remove_expired_effects()**: Removes effects that have expired
- **loot_item(p_character_id, p_item_id)**: Allows a character to loot an item

### Combat Procedures

- **enter_combat(p_location_id)**: Initiates combat in a location
- **end_combat_round(p_location_id)**: Ends the current combat round and starts a new one if combat continues

## Views

### Character Views

- **character_stats_summary**: Provides a summary of character stats
- **character_attributes_view**: Shows all attributes for each character
- **character_inventory_summary**: Summarizes the contents of character inventories

### Combat Views

- **combat_activity_summary**: Summarizes combat activity by character
- **damage_received_summary**: Summarizes damage received by character
- **current_combat_state**: Shows the current state of active combats
- **combat_round_summary**: Summarizes each combat round

### Miscellaneous Views

- **spell_usage_statistics**: Shows statistics on spell usage
- **location_item_summary**: Summarizes items in each location
- **effect_analysis**: Analyzes active effects

## Example Data

The `sql/data/01_example_data.sql` file contains example data for all tables to demonstrate the functionality of the database. It includes:

- 4 character classes
- 4 locations
- 4 effect templates
- 5 spells
- 6 items (weapons, armor, potions)
- 3 characters with attributes and spells
- Sample combat data

To load the example data, uncomment the corresponding line in `sql/main.sql`.

## Acceptance Tests

The `sql/tests/01_acceptance_tests.sql` file contains a procedure to run tests for various aspects of the database functionality. The tests include:

1. Verifying character stats summary view
2. Verifying combat activity summary view
3. Testing spell casting procedure
4. Testing character rest procedure
5. Testing item looting procedure
6. Testing combat round management
7. Testing damage calculation
8. Testing character death procedure

To run the acceptance tests, uncomment the corresponding lines in `sql/main.sql`.

## Usage

To set up the database schema:

1. Run the main SQL file:
   ```
   psql -U postgres -d your_database -f sql/main.sql
   ```

2. To include example data, uncomment the corresponding line in `sql/main.sql` before running.

3. To run acceptance tests, uncomment the corresponding lines in `sql/main.sql` before running.

## Entity Relationship Diagram

For a visual representation of the database schema, refer to the ER diagram in the project documentation.