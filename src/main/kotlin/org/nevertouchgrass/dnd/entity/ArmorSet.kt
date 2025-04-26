package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.OneToOne
import org.nevertouchgrass.dnd.enums.ArmorClass
import org.nevertouchgrass.dnd.enums.Element

@Entity
class ArmorSet {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 0
    var name: String = ""

    @Enumerated(EnumType.STRING)
    var armorClass = ArmorClass.CLOTH

    @OneToOne
    var item = Item()


    @Enumerated(EnumType.STRING)
    var protectsFrom = Element.PHYSICAL
    var damageReduction: Double = 0.1
    var swiftness: Double = 1.5
}