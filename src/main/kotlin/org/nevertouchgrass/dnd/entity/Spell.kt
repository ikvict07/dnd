package org.nevertouchgrass.dnd.entity

import jakarta.persistence.AttributeConverter
import jakarta.persistence.Column
import jakarta.persistence.Convert
import jakarta.persistence.Converter
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.ManyToOne
import org.nevertouchgrass.dnd.enums.AttributeType
import org.nevertouchgrass.dnd.enums.Element
import org.nevertouchgrass.dnd.enums.SpellCategory
import org.nevertouchgrass.dnd.enums.SpellImpactType

@Entity
class Spell {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(nullable = false)
    var id: Long = 1

    var baseCost: Int = 1

    var isPvp: Boolean = true

    var name: String = ""

    @Enumerated(EnumType.STRING)
    var spellCategory = SpellCategory.MELEE

    @Enumerated(EnumType.STRING)
    var spellElement = Element.PHYSICAL

    @Convert(converter = AttributeTypeListConverter::class)
    var scalesFrom: MutableList<AttributeType> = mutableListOf(AttributeType.STRENGTH)

    @Enumerated
    var spellImpactType = SpellImpactType.DAMAGE

    @ManyToOne(fetch = FetchType.LAZY)
    var causeEffect: EffectTemplate? = null

    var range: Double = 0.0

    var value: Double = 0.0
}
@Converter
class AttributeTypeListConverter : AttributeConverter<List<AttributeType>, String> {

    private val separator = ","

    override fun convertToDatabaseColumn(attribute: List<AttributeType>?): String {
        return attribute?.joinToString(separator) { it.name } ?: ""
    }

    override fun convertToEntityAttribute(dbData: String?): List<AttributeType> {
        return dbData?.takeIf { it.isNotEmpty() }
            ?.split(separator)
            ?.map { AttributeType.valueOf(it) }
            ?.toMutableList()
            ?: mutableListOf()
    }
}