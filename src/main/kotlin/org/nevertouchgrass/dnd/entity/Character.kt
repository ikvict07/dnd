package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.ManyToMany
import jakarta.persistence.ManyToOne
import jakarta.persistence.OneToMany
import jakarta.persistence.OneToOne

@Entity
class Character {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 0

    var name: String = ""

    @OneToMany(fetch = FetchType.LAZY)
    var attributes = mutableListOf<Attribute>()

    @ManyToOne(fetch = FetchType.LAZY)
    var characterClass: Class = Class()

    @OneToOne(fetch = FetchType.LAZY)
    var inventory: Inventory = Inventory()

    var actionPoints: Int = 0

    @OneToMany(fetch = FetchType.LAZY)
    var underEffects: MutableList<Effect> = mutableListOf()

    @ManyToOne
    var armorSet: ArmorSet = ArmorSet()

    @ManyToOne
    var weapon: Weapon = Weapon()

    @ManyToMany
    var spells: MutableList<Spell> = mutableListOf()

    @ManyToOne
    var location: Location = Location()

    var hp: Double = 100.0

    var xp: Double = 0.0
    var lvl: Int = 1
}