package org.nevertouchgrass.dnd

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class DndApplication

fun main(args: Array<String>) {
    runApplication<DndApplication>(*args)
}
