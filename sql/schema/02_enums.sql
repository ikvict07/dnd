create type attribute_type as enum ('strength', 'intelligence', 'dexterity', 'constitution', 'health');
alter type attribute_type owner to postgres;

create type armor_class as enum ('leather', 'heavy', 'cloth');
alter type armor_class owner to postgres;

create type spell_category as enum ('melee', 'ranged', 'magic');
alter type spell_category owner to postgres;

create type spell_impact_type as enum ('damage', 'healing');
alter type spell_impact_type owner to postgres;

create type element as enum ('fire', 'water', 'earth', 'air', 'lightning', 'ice', 'poison', 'thunder', 'physical', 'holy');
alter type element owner to postgres;

create type effect_type as enum ('buff', 'de_buff');
alter type effect_type owner to postgres;

create type item_type as enum ('armor', 'weapon', 'potion', 'trophy');
alter type item_type owner to postgres;