package org.nevertouchgrass.dnd.entity

import jakarta.persistence.CascadeType
import jakarta.persistence.Column
import jakarta.persistence.Convert
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.OneToOne
import org.nevertouchgrass.dnd.enums.AttributeType

@Entity
class Weapon {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 0

    var name: String = ""

    @OneToOne(cascade = [(CascadeType.ALL)])
    var item = Item()

    var damageMultiplier: Double = 1.1
    var actionPointsMultiplier: Double = 1.0

    @Convert(converter = AttributeTypeListConverter::class)
    var scalesFrom: MutableList<AttributeType> = mutableListOf(AttributeType.STRENGTH)
}