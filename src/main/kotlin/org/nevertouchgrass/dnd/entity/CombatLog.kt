package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.ManyToMany
import jakarta.persistence.ManyToOne
import jakarta.persistence.OneToMany

@Entity
class CombatLog {
    @Id
    @Column(nullable = false)
    var id: Long = 0

    @ManyToOne
    var actor: Character = Character()

    @ManyToOne
    var action: Spell? = null

    @ManyToOne
    var target: Character = Character()

    @ManyToOne
    var causedEffect: Effect? = null

    var actionPointsSpent: Int = 0

    @OneToMany
    var itemsUsed = mutableListOf<Item>()

    var impact = 0
}