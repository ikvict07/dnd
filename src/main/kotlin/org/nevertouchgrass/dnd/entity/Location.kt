package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.ManyToMany
import jakarta.persistence.OneToMany

@Entity
class Location {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 0

    @ManyToMany
    var itemsOnTheFloor: MutableSet<Item> = mutableSetOf()

    @OneToMany
    var characters: MutableSet<Character> = mutableSetOf()

    var name: String = ""

    var isPvp: Boolean = false
}