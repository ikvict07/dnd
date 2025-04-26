-- DnD Combat System Database Schema - Enums

-- Enums
create type attribute_type as enum ('STRENGTH', 'INTELLIGENCE', 'DEXTERITY', 'CONSTITUTION', 'HEALTH');
alter type attribute_type owner to postgres;

create type armor_class as enum ('LEATHER', 'HEAVY', 'CLOTH');
alter type armor_class owner to postgres;

create type spell_category as enum ('MELEE', 'RANGED', 'MAGIC');
alter type spell_category owner to postgres;

create type spell_impact_type as enum ('DAMAGE', 'HEALING');
alter type spell_impact_type owner to postgres;

create type element as enum ('FIRE', 'WATER', 'EARTH', 'AIR', 'LIGHTNING', 'ICE', 'POISON', 'THUNDER', 'PHYSICAL', 'HOLY');
alter type element owner to postgres;

create type effect_type as enum ('BUFF', 'DE_BUFF');
alter type effect_type owner to postgres;

create type item_type as enum ('ARMOR', 'WEAPON', 'POTION', 'TROPHY');
alter type item_type owner to postgres;