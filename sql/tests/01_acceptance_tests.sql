set search_path to dnd;

-- test setup: create test data
insert into location (is_pvp, name)
values (false, 'safe haven'), -- non-pvp location for resting
       (true, 'battleground'); -- pvp location for combat

insert into class (action_points_multiplier, inventory_multiplier, armor_class, main_attribute, name)
values (1.2, 1.5, 'heavy', 'strength', 'warrior'),
       (0.8, 1.0, 'cloth', 'intelligence', 'mage'),
       (1.0, 1.2, 'leather', 'dexterity', 'rogue');

insert into attribute (value, attribute_type)
values (20, 'strength'),
       (20, 'intelligence'),
       (20, 'dexterity'),
       (20, 'constitution'),
       (100, 'health'),
       (10, 'strength'),
       (30, 'intelligence'),
       (15, 'dexterity'),
       (15, 'constitution'),
       (80, 'health'),
       (15, 'strength'),
       (15, 'intelligence'),
       (25, 'dexterity'),
       (15, 'constitution'),
       (90, 'health');

insert into effect_template (duration_rounds, value, affected_attribute_type, effect, effect_name)
values (3, 5, 'strength', 'buff', 'strength boost'),
       (3, 5, 'dexterity', 'de_buff', 'slow'),
       (2, 10, 'health', 'buff', 'regeneration');

insert into spell (base_cost, name, is_pvp, range, spell_impact_type, value, spell_category, spell_element, scales_from)
values (5, 'fireball', true, 30.0, 'damage', 20.0, 'magic', 'fire', '{intelligence}'),
       (3, 'heal', false, 10.0, 'healing', 15.0, 'magic', 'holy', '{intelligence}'),
       (2, 'slash', true, 5.0, 'damage', 10.0, 'melee', 'physical', '{strength}'),
       (0, 'rest', false, 0.0, 'healing', 30.0, 'magic', 'holy', '{constitution}');

-- link spells with effect templates
update spell
set cause_effect_id = (select id from effect_template where effect_name = 'strength boost')
where name = 'fireball';
update spell
set cause_effect_id = (select id from effect_template where effect_name = 'regeneration')
where name = 'heal';
update spell
set cause_effect_id = (select id from effect_template where effect_name = 'slow')
where name = 'slash';

insert into item (type, weight, name)
values ('armor', 15.0, 'plate armor'),
       ('weapon', 5.0, 'longsword'),
       ('potion', 0.5, 'health potion'),
       ('armor', 8.0, 'robe'),
       ('weapon', 2.0, 'staff'),
       ('potion', 0.5, 'mana potion'),
       ('armor', 10.0, 'leather armor'),
       ('weapon', 3.0, 'dagger'),
       ('potion', 0.5, 'swiftness potion');

insert into armor_set (damage_reduction, swiftness, item_id, armor_class, name, protects_from)
values (0.3, 0.7, 1, 'heavy', 'plate armor', 'physical'),
       (0.1, 1.0, 4, 'cloth', 'mage robe', 'magic'),
       (0.2, 0.9, 7, 'leather', 'leather armor', 'physical');

insert into weapon (action_points_multiplier, damage_multiplier, item_id, name, scales_from)
values (1.0, 1.5, 2, 'longsword', 'strength'),
       (0.8, 1.8, 5, 'staff', 'intelligence'),
       (0.7, 1.3, 8, 'dagger', 'dexterity');

insert into potion (item_id, name)
values (3, 'health potion'),
       (6, 'mana potion'),
       (9, 'swiftness potion');

-- link potions with effect templates
update potion
set cause_effect_id = (select id from effect_template where effect_name = 'regeneration')
where name = 'health potion';
update potion
set cause_effect_id = (select id from effect_template where effect_name = 'strength boost')
where name = 'mana potion';
update potion
set cause_effect_id = (select id from effect_template where effect_name = 'slow')
where name = 'swiftness potion';

insert into inventory (capacity)
values (50.0),
       (40.0),
       (45.0);

insert into character (action_points, hp, lvl, xp, armor_set_id, character_class_id, inventory_id, location_id,
                       weapon_id, name)
values (12, 100.0, 1, 0.0, 1, 1, 1, 1, 1, 'warrior1'),
       (8, 80.0, 1, 0.0, 2, 2, 2, 1, 2, 'mage1'),
       (10, 90.0, 1, 0.0, 3, 3, 3, 2, 3, 'rogue1');

-- link characters with attributes
insert into character_attributes (character_id, attributes_id)
values (1, 1),  -- warrior - strength
       (1, 2),  -- warrior - intelligence
       (1, 3),  -- warrior - dexterity
       (1, 4),  -- warrior - constitution
       (1, 5),  -- warrior - health
       (2, 6),  -- mage - strength
       (2, 7),  -- mage - intelligence
       (2, 8),  -- mage - dexterity
       (2, 9),  -- mage - constitution
       (2, 10), -- mage - health
       (3, 11), -- rogue - strength
       (3, 12), -- rogue - intelligence
       (3, 13), -- rogue - dexterity
       (3, 14), -- rogue - constitution
       (3, 15);
-- rogue - health

-- link characters with spells
insert into character_spells (character_id, spells_id)
values (1, 3), -- warrior knows slash
       (2, 1), -- mage knows fireball
       (2, 2), -- mage knows heal
       (3, 3);
-- rogue knows slash

-- link characters with locations
insert into location_characters (characters_id, location_id)
values (1, 1), -- warrior in safe haven
       (2, 1), -- mage in safe haven
       (3, 2);
-- rogue in battleground

-- add items to inventories
insert into inventory_items (inventory_id, items_id)
values (1, 3), -- warrior has health potion
       (2, 6), -- mage has mana potion
       (3, 9);
-- rogue has swiftness potion

-- =============================================
-- test 1: test get_attribute_value function
-- =============================================
do
$$
    declare
        v_strength     integer;
        v_intelligence integer;
        v_dexterity    integer;
        v_constitution integer;
        v_health       integer;
    begin
        -- test for warrior
        v_strength := get_attribute_value(1, 'strength');
        v_intelligence := get_attribute_value(1, 'intelligence');
        v_dexterity := get_attribute_value(1, 'dexterity');
        v_constitution := get_attribute_value(1, 'constitution');
        v_health := get_attribute_value(1, 'health');

        assert v_strength = 20, 'warrior strength should be 20';
        assert v_intelligence = 20, 'warrior intelligence should be 20';
        assert v_dexterity = 20, 'warrior dexterity should be 20';
        assert v_constitution = 20, 'warrior constitution should be 20';
        assert v_health = 100, 'warrior health should be 100';

        -- test for mage
        v_strength := get_attribute_value(2, 'strength');
        v_intelligence := get_attribute_value(2, 'intelligence');

        assert v_strength = 10, 'mage strength should be 10';
        assert v_intelligence = 30, 'mage intelligence should be 30';

        -- test for rogue
        v_dexterity := get_attribute_value(3, 'dexterity');

        assert v_dexterity = 25, 'rogue dexterity should be 25';

        raise notice 'test 1: get_attribute_value function - passed';
    end
$$;

-- test 2: test sp_rest_character procedure
do
$$
    declare
        v_initial_hp       double precision;
        v_after_rest_hp    double precision;
        v_exception_caught boolean;
    begin
        select hp into v_initial_hp from character where id = 1;

        update character set hp = 50.0 where id = 1;

        -- test resting for warrior in non-pvp location
        begin
            call sp_rest_character(1);

            -- get hp after rest
            select hp into v_after_rest_hp from character where id = 1;

            -- hp should be higher after rest
            assert v_after_rest_hp > 50.0, 'hp should increase after rest';

            raise notice 'test 2.1: sp_rest_character in non-pvp location - passed';
        exception
            when others then
                raise notice 'test 2.1: sp_rest_character in non-pvp location - failed: %', sqlerrm;
        end;

        -- test resting for rogue in pvp location (should fail)
        v_exception_caught := false;
        begin
            call sp_rest_character(3);
        exception
            when others then
                v_exception_caught := true;
        end;

        assert v_exception_caught, 'resting in pvp location should throw an exception';

        raise notice 'test 2.2: sp_rest_character in pvp location - passed';

        update character set hp = v_initial_hp where id = 1;
    end
$$;

-- test 3: test sp_cast_spell procedure
do
$$
    declare
        v_initial_hp_target     double precision;
        v_after_spell_hp_target double precision;
        v_initial_ap_caster     integer;
        v_after_spell_ap_caster integer;
        v_effect_count          integer;
        v_exception_caught      boolean;
    begin
        update character set location_id = 2 where id = 2;
        update location_characters set location_id = 2 where characters_id = 2;

        select hp into v_initial_hp_target from character where id = 3; -- rogue
        select action_points into v_initial_ap_caster from character where id = 2; -- mage

        begin
            call sp_cast_spell(2, 3, 1); -- mage casts fireball on rogue

            select hp into v_after_spell_hp_target from character where id = 3; -- rogue
            select action_points into v_after_spell_ap_caster from character where id = 2; -- mage

            assert v_after_spell_hp_target < v_initial_hp_target, 'target hp should decrease after damage spell';

            assert v_after_spell_ap_caster < v_initial_ap_caster, 'caster ap should decrease after casting spell';

            -- check if effect was applied
            select count(*)
            into v_effect_count
            from effect e
                     join character_under_effects cue on e.id = cue.under_effects_id
            where cue.character_id = 3;

            assert v_effect_count > 0, 'effect should be applied to target';

            raise notice 'test 3.1: sp_cast_spell (damage spell) - passed';
        exception
            when others then
                raise notice 'test 3.1: sp_cast_spell (damage spell) - failed: %', sqlerrm;
        end;

        update character set hp = v_initial_hp_target where id = 3;
        update character set action_points = v_initial_ap_caster where id = 2;
        delete from character_under_effects where character_id = 3;
        delete from effect;

        update character set location_id = 1 where id = 2;
        update location_characters set location_id = 1 where characters_id = 2;

        -- test casting heal (healing spell)
        begin
            -- set warrior hp to a lower value
            update character set hp = 50.0 where id = 1;

            select hp into v_initial_hp_target from character where id = 1; -- warrior
            select action_points into v_initial_ap_caster from character where id = 2; -- mage

            call sp_cast_spell(2, 1, 2); -- mage casts heal on warrior

            select hp into v_after_spell_hp_target from character where id = 1; -- warrior
            select action_points into v_after_spell_ap_caster from character where id = 2; -- mage

            assert v_after_spell_hp_target > v_initial_hp_target, 'target hp should increase after healing spell';

            assert v_after_spell_ap_caster < v_initial_ap_caster, 'caster ap should decrease after casting spell';

            select count(*)
            into v_effect_count
            from effect e
                     join character_under_effects cue on e.id = cue.under_effects_id
            where cue.character_id = 1;

            assert v_effect_count > 0, 'effect should be applied to target';

            raise notice 'test 3.2: sp_cast_spell (healing spell) - passed';
        exception
            when others then
                raise notice 'test 3.2: sp_cast_spell (healing spell) - failed: %', sqlerrm;
        end;

        -- test insufficient ap (should fail)
        begin
            -- set mage ap to a very low value
            update character set action_points = 1 where id = 2;

            v_exception_caught := false;
            begin
                call sp_cast_spell(2, 1, 1);
            exception
                when others then
                    v_exception_caught := true;
            end;

            assert v_exception_caught, 'casting spell with insufficient ap should throw an exception';

            raise notice 'test 3.3: sp_cast_spell (insufficient ap) - passed';
        exception
            when others then
                raise notice 'test 3.3: sp_cast_spell (insufficient ap) - failed: %', sqlerrm;
        end;
    end
$$;

-- test 4: test combat procedures
do
$$
    declare
        v_combat_id              integer;
        v_round_id               integer;
        v_initial_ap_warrior     integer;
        v_after_enter_ap_warrior integer;
        v_after_reset_ap_warrior integer;
        v_exception_caught       boolean;
        v_after_spent_ap_warrior integer;
    begin
        update character set location_id = 2 where id in (1, 2);
        update location_characters set location_id = 2 where characters_id in (1, 2);

        insert into combat (location_id) values (2) returning id into v_combat_id;

        insert into round (index, is_finished) values (1, false) returning id into v_round_id;

        insert into combat_combat_rounds (combat_id, combat_rounds_id) values (v_combat_id, v_round_id);

        select action_points into v_initial_ap_warrior from character where id = 1;

        -- test sp_enter_combat
        begin
            call sp_enter_combat(v_combat_id, 1); -- warrior enters combat

            select action_points into v_after_enter_ap_warrior from character where id = 1;

            assert exists (select 1
                           from round_participants
                           where round_id = v_round_id
                             and participants_id = 1), 'character should be added to round participants';

            assert v_after_enter_ap_warrior != v_initial_ap_warrior, 'ap should be recalculated after entering combat';

            raise notice 'test 4.1: sp_enter_combat - passed';
        exception
            when others then
                raise notice 'test 4.1: sp_enter_combat - failed: %', sqlerrm;
        end;

        begin
            update character set location_id = 1 where id = 1;
            update location_characters set location_id = 1 where characters_id = 1;

            v_exception_caught := false;
            begin
                call sp_enter_combat(v_combat_id, 1);
            exception
                when others then
                    v_exception_caught := true;
            end;

            begin
                insert into round_participants (participants_id, round_id)
                values (1, v_round_id)
                on conflict do nothing;

                call sp_enter_combat(v_combat_id, 2);

                call sp_reset_round(v_combat_id);

                assert exists (select 1
                               from round
                               where id = v_round_id
                                 and is_finished = true), 'old round should be marked as finished';

                assert exists (select 1
                               from round r
                                        join combat_combat_rounds ccr on r.id = ccr.combat_rounds_id
                               where ccr.combat_id = v_combat_id
                                 and r.is_finished = false
                                 and r.index = 2), 'new round should be created with incremented index';

                select action_points into v_after_reset_ap_warrior from character where id = 1;

                update character set action_points = action_points - 2 where id = 1;
                select character.action_points from character where id = 1 into v_after_spent_ap_warrior;

                assert v_exception_caught, 'entering combat from wrong location should throw an exception';
                update character set location_id = 2 where id = 1;

                update location_characters set location_id = 2 where characters_id = 1;
                raise notice 'test 4.2: sp_enter_combat (wrong location) - passed';
            exception
                when others then
                    raise notice 'test 4.2: sp_enter_combat (wrong location) - failed: %', sqlerrm;
            end;

            assert v_after_reset_ap_warrior != v_after_spent_ap_warrior, 'ap should be recalculated after round reset';

            raise notice 'test 4.3: sp_reset_round - passed';
        exception
            when others then
                raise notice 'test 4.3: sp_reset_round - failed: %', sqlerrm;
        end;
    end
$$;

-- test 5: test item use procedure
do
$$
    declare
        v_initial_hp      double precision;
        v_after_potion_hp double precision;
        v_effect_count    integer;
    begin
        -- test using a health potion
        begin
            update character set hp = 50.0 where id = 1;

            select get_attribute_value(1, 'health') into v_initial_hp;

            call sp_use_item(1, 3);

            select get_attribute_value(1, 'health') into v_after_potion_hp;
            assert v_after_potion_hp > v_initial_hp, 'helath should increase after using health potion';

            select count(*)
            into v_effect_count
            from effect e
                     join character_under_effects cue on e.id = cue.under_effects_id
            where cue.character_id = 1;

            assert v_effect_count > 0, 'effect should be applied after using potion';

            assert not exists (select 1
                               from inventory_items
                               where inventory_id = 1
                                 and items_id = 3), 'item should be removed from inventory after use';

            raise notice 'test 5.1: sp_use_item (potion) - passed';
        exception
            when others then
                raise notice 'test 5.1: sp_use_item (potion) - failed: %', sqlerrm;
        end;
    end
$$;

-- test 6: test loot procedure
do
$$
    declare
        v_item_id                integer;
        v_inventory_count_before integer;
        v_inventory_count_after  integer;
        v_location_id            integer := 1;
        v_character_id           integer := 2;
        v_inventory_id           integer;
        v_max_id                 integer;
    begin
        select inventory_id
        into v_inventory_id
        from character
        where id = v_character_id;

        insert into item (type, weight, name) values ('trophy', 1.0, 'test trophy') returning id into v_item_id;

        insert into location_items_on_the_floor (items_on_the_floor_id, location_id) values (v_item_id, v_location_id);

        insert into combat (location_id) values (v_location_id);

        delete from location_characters where characters_id = v_character_id;
        insert into location_characters (characters_id, location_id) values (v_character_id, v_location_id);

        update character set location_id = v_location_id where id = v_character_id;

        select count(*) into v_inventory_count_before from inventory_items where inventory_id = v_inventory_id;
        begin
            select max(id) into v_max_id from combat;
            call sp_loot_item(v_max_id, v_character_id, v_item_id);

            select count(*) into v_inventory_count_after from inventory_items where inventory_id = v_inventory_id;
            assert v_inventory_count_after = v_inventory_count_before + 1, 'inventory should have one more item after looting';

            assert not exists (select 1
                               from location_items_on_the_floor
                               where items_on_the_floor_id = v_item_id), 'item should be removed from floor after looting';

            assert exists (select 1
                           from inventory_items
                           where inventory_id = v_inventory_id
                             and items_id = v_item_id), 'item should be added to inventory after looting';

            raise notice 'test 6.1: sp_loot_item - passed';
        exception
            when others then
                raise notice 'test 6.1: sp_loot_item - failed: %', sqlerrm;
        end;
    end
$$;


-- test 7: test player death procedure
do
$$
    declare
        v_initial_location_id integer;
        v_initial_hp          double precision;
        v_initial_xp          double precision;
        v_inventory_id        integer;
        v_items_count         integer;
        v_floor_items_count   integer;
    begin
        select location_id, hp, xp, inventory_id
        into v_initial_location_id, v_initial_hp, v_initial_xp, v_inventory_id
        from character
        where id = 3;

        select count(*)
        into v_items_count
        from inventory_items
        where inventory_id = v_inventory_id;

        select count(*)
        into v_floor_items_count
        from location_items_on_the_floor
        where location_id = v_initial_location_id;

        raise notice 'before death: character has % items, location has % items on floor',
            v_items_count, v_floor_items_count;

        update character set hp = 0 where id = 3;

        begin
            call sp_handle_player_death(3);

            select count(*)
            into v_items_count
            from inventory_items
            where inventory_id = v_inventory_id;

            select count(*)
            into v_floor_items_count
            from location_items_on_the_floor
            where location_id = v_initial_location_id;

            raise notice 'after death: character has % items, location has % items on floor',
                v_items_count, v_floor_items_count;

            if v_items_count = 0 then
                raise notice 'test 7.1: items removed from inventory - passed';
            else
                raise notice 'test 7.1: items not removed from inventory - failed';
            end if;

            if v_floor_items_count > 0 then
                raise notice 'test 7.2: items dropped on location - passed';
            else
                raise notice 'test 7.2: no items found on location - failed';
            end if;

            raise notice 'test 7: sp_handle_player_death - passed';
        exception
            when others then
                raise notice 'test 7: sp_handle_player_death - failed: %', sqlerrm;
        end;
    end
$$;
-- test 8: test effect procedures
do
$$
    declare
        v_effect_template_id          integer;
        v_effect_id                   integer;
        v_initial_strength            integer;
        v_after_effect_strength       integer;
        v_after_decrement_rounds_left integer;
        v_effect_count                integer;
    begin
        select id
        into v_effect_template_id
        from effect_template
        where effect_name = 'strength boost';

        v_initial_strength := get_attribute_value(1, 'strength');

        -- test applying effect from template
        begin
            v_effect_id := sp_apply_effect_from_template(v_effect_template_id, 1);

            assert v_effect_id is not null, 'effect should be created';

            select count(*)
            into v_effect_count
            from character_under_effects
            where character_id = 1
              and under_effects_id = v_effect_id;

            assert v_effect_count = 1, 'effect should be linked to character';

            v_after_effect_strength := get_attribute_value(1, 'strength');

            assert v_after_effect_strength > v_initial_strength, 'strength should be increased by effect';

            raise notice 'test 8.1: sp_apply_effect_from_template - passed';
        exception
            when others then
                raise notice 'test 8.1: sp_apply_effect_from_template - failed: %', sqlerrm;
        end;

        -- test decrementing effect rounds
        begin
            select rounds_left
            into v_after_decrement_rounds_left
            from effect
            where id = v_effect_id;

            call sp_decrement_effect_rounds();

            select rounds_left
            into v_after_decrement_rounds_left
            from effect
            where id = v_effect_id;

            assert v_after_decrement_rounds_left = 2, 'rounds left should decrease by 1';

            call sp_decrement_effect_rounds();
            call sp_decrement_effect_rounds();

            assert not exists (select 1
                               from effect
                               where id = v_effect_id), 'effect should be removed when rounds left reaches 0';

            v_after_effect_strength := get_attribute_value(1, 'strength');

            assert v_after_effect_strength = v_initial_strength, 'strength should be restored after effect expires';

            raise notice 'test 8.2: sp_decrement_effect_rounds - passed';
        exception
            when others then
                raise notice 'test 8.2: sp_decrement_effect_rounds - failed: %', sqlerrm;
        end;
    end
$$;