package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import org.nevertouchgrass.dnd.enums.AttributeType

@Entity
class Attribute {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 0

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var attributeType: AttributeType = AttributeType.STRENGTH

    @Column(nullable = false)
    var value: Int = 1
}