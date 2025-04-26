package org.nevertouchgrass.dnd.entity

import jakarta.persistence.CascadeType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.ManyToOne
import jakarta.persistence.OneToMany

@Entity
class Combat {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 0

    @ManyToOne(fetch = FetchType.LAZY)
    var location: Location = Location()

    @OneToMany(cascade = [CascadeType.ALL])
    var combatRounds: MutableList<Round> = mutableListOf()
}