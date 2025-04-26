package org.nevertouchgrass.dnd.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.ManyToOne
import jakarta.persistence.OneToOne

@Entity
class Potion {
    @Id
    @Column(nullable = false)
    var id: Long = 0

    var name: String = ""

    @ManyToOne
    var causeEffect: EffectTemplate = EffectTemplate()

    @OneToOne
    var item: Item = Item()
}