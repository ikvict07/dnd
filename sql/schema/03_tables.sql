create schema if not exists dnd;

set search_path to dnd;

create table item
(
    type   item_type,
    weight double precision not null,
    id     serial           not null
        primary key,
    name   varchar(255)
);

alter table item
    owner to postgres;

create table inventory
(
    capacity double precision not null,
    id       serial           not null
        primary key
);

alter table inventory
    owner to postgres;

create table location
(
    is_pvp boolean not null,
    name   varchar(255),
    id     serial  not null
        primary key
);

alter table location
    owner to postgres;

create table class
(
    action_points_multiplier double precision not null,
    inventory_multiplier     double precision not null,
    id                       serial           not null
        primary key,
    armor_class              varchar(255),
    main_attribute           varchar(255),
    name                     varchar(255)
);

alter table class
    owner to postgres;

create table effect_template
(
    duration_rounds         integer not null,
    value                   integer not null,
    id                      serial  not null
        primary key,
    affected_attribute_type varchar(255),
    effect                  varchar(255),
    effect_name             varchar(255)
);

alter table effect_template
    owner to postgres;

create table attribute
(
    value          integer      not null,
    id             serial       not null
        primary key,
    attribute_type varchar(255) not null
);

alter table attribute
    owner to postgres;

create table round
(
    index       integer not null,
    is_finished boolean not null,
    id          serial  not null
        primary key
);

alter table round
    owner to postgres;

create table armor_set
(
    damage_reduction double precision not null,
    swiftness        double precision not null,
    id               serial           not null
        primary key,
    item_id          bigint
        references item,
    armor_class      varchar(255),
    name             varchar(255),
    protects_from    varchar(255)
);

alter table armor_set
    owner to postgres;

create unique index armor_set_item_id_key
    on armor_set (item_id);

create table weapon
(
    action_points_multiplier double precision not null,
    damage_multiplier        double precision not null,
    id                       serial           not null
        primary key,
    item_id                  bigint
        references item,
    name                     varchar(255),
    scales_from              varchar(255)
);

alter table weapon
    owner to postgres;

create unique index weapon_item_id_key
    on weapon (item_id);

create table inventory_items
(
    inventory_id bigint not null
        references inventory,
    items_id     bigint not null
        references item
);

alter table inventory_items
    owner to postgres;

create unique index inventory_items_items_id_key
    on inventory_items (items_id);

create table location_items_on_the_floor
(
    items_on_the_floor_id bigint not null
        references item,
    location_id           bigint not null
        references location,
    primary key (items_on_the_floor_id, location_id)
);

alter table location_items_on_the_floor
    owner to postgres;

create table spell
(
    base_cost         integer          not null,
    name              varchar(255)     not null,
    is_pvp            boolean          not null,
    range             double precision not null,
    spell_impact_type spell_impact_type,
    value             double precision not null,
    cause_effect_id   bigint
        references effect_template,
    id                serial           not null
        primary key,
    scales_from       attribute_type[],
    spell_category    spell_category,
    spell_element     element
);

alter table spell
    owner to postgres;

create table effect
(
    rounds_left        integer not null,
    effect_template_id bigint
        references effect_template,
    id                 serial  not null
        primary key
);

alter table effect
    owner to postgres;

create table potion
(
    cause_effect_id bigint
        references effect_template,
    id              serial not null
        primary key,
    item_id         bigint
        references item,
    name            varchar(255)
);

alter table potion
    owner to postgres;

create unique index potion_item_id_key
    on potion (item_id);

create table combat
(
    id          serial not null
        primary key,
    location_id bigint
        references location
);

alter table combat
    owner to postgres;

create table character
(
    action_points      integer          not null,
    hp                 double precision not null,
    lvl                integer          not null,
    xp                 double precision not null,
    armor_set_id       bigint
        references armor_set,
    character_class_id bigint
        references class,
    id                 serial           not null
        primary key,
    inventory_id       bigint
        references inventory,
    location_id        bigint
        references location,
    weapon_id          bigint
        references weapon,
    name               varchar(255)
);

alter table character
    owner to postgres;

create unique index character_inventory_id_key
    on character (inventory_id);

create table character_attributes
(
    attributes_id bigint not null
        references attribute,
    character_id  bigint not null
        references character
);

alter table character_attributes
    owner to postgres;

create unique index character_attributes_attributes_id_key
    on character_attributes (attributes_id);

create table character_spells
(
    character_id bigint not null
        references character,
    spells_id    bigint not null
        references spell
);

alter table character_spells
    owner to postgres;

create table character_under_effects
(
    character_id     bigint not null
        references character,
    under_effects_id bigint not null
        references effect
);

alter table character_under_effects
    owner to postgres;

create unique index character_under_effects_under_effects_id_key
    on character_under_effects (under_effects_id);

create table location_characters
(
    characters_id bigint not null
        references character,
    location_id   bigint not null
        references location,
    primary key (characters_id, location_id)
);

alter table location_characters
    owner to postgres;

create unique index location_characters_characters_id_key
    on location_characters (characters_id);

create table combat_combat_rounds
(
    combat_id        bigint not null
        references combat,
    combat_rounds_id bigint not null
        references round
);

alter table combat_combat_rounds
    owner to postgres;

create unique index combat_combat_rounds_combat_rounds_id_key
    on combat_combat_rounds (combat_rounds_id);

create table round_participants
(
    participants_id bigint not null
        references character,
    round_id        bigint not null
        references round
);

alter table round_participants
    owner to postgres;

create table combat_log
(
    action_points_spent integer not null,

    impact              integer not null,
    description         text,
    action_id           bigint
        references spell,
    actor_id            bigint
        references character,
    caused_effect_id    bigint
        references effect,
    id                  serial  not null
        primary key,
    target_id           bigint
        references character
);

alter table combat_log
    owner to postgres;

create table combat_log_items_used
(
    combat_log_id bigint not null
        references combat_log,
    items_used_id bigint not null
        references item
);

alter table combat_log_items_used
    owner to postgres;

create unique index combat_log_items_used_items_used_id_key
    on combat_log_items_used (items_used_id);

create table round_logs
(
    logs_id  bigint not null
        references combat_log,
    round_id bigint not null
        references round
);

alter table round_logs
    owner to postgres;

create unique index round_logs_logs_id_key
    on round_logs (logs_id);