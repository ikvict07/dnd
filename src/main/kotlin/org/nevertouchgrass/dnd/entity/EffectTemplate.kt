package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import org.nevertouchgrass.dnd.enums.AttributeType
import org.nevertouchgrass.dnd.enums.EffectType

@Entity
class EffectTemplate {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 0

    @Enumerated(EnumType.STRING)
    var effect = EffectType.BUFF

    @Enumerated(EnumType.STRING)
    var affectedAttributeType = AttributeType.STRENGTH

    var effectName: String = ""

    var durationRounds: Int = 1

    var value: Int = 1
}