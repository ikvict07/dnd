-- DnD Combat System Database Schema - Sequences

-- Sequences
create sequence armor_set_seq increment by 1;
alter sequence armor_set_seq owner to postgres;

create sequence attribute_seq increment by 1;
alter sequence attribute_seq owner to postgres;

create sequence character_seq increment by 1;
alter sequence character_seq owner to postgres;

create sequence class_seq increment by 1;
alter sequence class_seq owner to postgres;

create sequence combat_seq increment by 1;
alter sequence combat_seq owner to postgres;

create sequence effect_seq increment by 1;
alter sequence effect_seq owner to postgres;

create sequence effect_template_seq increment by 1;
alter sequence effect_template_seq owner to postgres;

create sequence inventory_seq increment by 1;
alter sequence inventory_seq owner to postgres;

create sequence item_seq increment by 1;
alter sequence item_seq owner to postgres;

create sequence location_seq increment by 1;
alter sequence location_seq owner to postgres;

create sequence spell_seq increment by 1;
alter sequence spell_seq owner to postgres;

create sequence weapon_seq increment by 1;
alter sequence weapon_seq owner to postgres;