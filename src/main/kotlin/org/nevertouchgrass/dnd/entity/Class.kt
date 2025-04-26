package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import org.nevertouchgrass.dnd.enums.ArmorClass
import org.nevertouchgrass.dnd.enums.AttributeType

@Entity
class Class {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 1

    var name: String = ""

    @Enumerated(EnumType.STRING)
    var mainAttribute: AttributeType = AttributeType.STRENGTH

    @Enumerated(EnumType.STRING)
    var armorClass: ArmorClass = ArmorClass.CLOTH

    var inventoryMultiplier: Double = 1.0

    var actionPointsMultiplier: Double = 1.0
}