package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.ManyToMany
import jakarta.persistence.OneToMany

@Entity
class Round {
    @Id
    @Column(nullable = false)
    var id: Long = 0

    var index = 1

    var isFinished = false

    @OneToMany
    var logs: MutableList<CombatLog> = mutableListOf()

    @ManyToMany
    var participants: MutableList<Character> = mutableListOf()
}