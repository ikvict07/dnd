-- DnD Combat System Database Schema - Main File

-- This file includes all the SQL files in the correct order to set up the database schema

-- Schema
\i sql/schema/01_sequences.sql
\i sql/schema/02_enums.sql
\i sql/schema/03_tables.sql
\i sql/schema/04_indexes.sql

-- Functions
\i sql/functions/01_attribute_functions.sql
\i sql/functions/02_spell_functions.sql

-- Procedures
\i sql/procedures/01_spell_procedures.sql
\i sql/procedures/02_rest_procedure.sql
\i sql/procedures/03_loot_procedure.sql
\i sql/procedures/04_combat_procedures.sql
\i sql/procedures/05_effect_procedures.sql

-- Views
\i sql/views/01_character_views.sql
\i sql/views/02_combat_views.sql
\i sql/views/03_misc_views.sql

-- Example Data (optional)
-- Uncomment the following line to load example data
-- \i sql/data/01_example_data.sql

-- Acceptance Tests (optional)
-- Uncomment the following line to load acceptance tests
-- \i sql/tests/01_acceptance_tests.sql
-- Uncomment the following line to run acceptance tests
-- CALL run_acceptance_tests();
