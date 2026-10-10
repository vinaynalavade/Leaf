package com.vinaynalavade.expensetracker.core.easteregg

import java.time.LocalTime

/**
 * Core evaluation engine and constants for Leaf's Easter Egg universe.
 * Strictly decoupled from financial calculations, balances, or database mutations.
 */
object EasterEggEngine {

    const val MSG_HIDDEN_LEAF = "You found something that wasn't in the budget."
    const val MSG_ZERO_MODE = "Congratulations. You spent nothing."
    const val MSG_PERFECT_SPLIT = "Balance achieved."
    const val MSG_PAISA_PERFECT = "Every paisa accounted for."
    const val MSG_DEVELOPERS_BILL_TITLE = "The Bill That Started It All"
    const val MSG_PHILOSOPHY = "Money is a tool. Clarity is freedom."
    const val MSG_MIDNIGHT_GREETING = "Still keeping an eye on your money?"
    const val MSG_KONAMI_UNLOCKED = "Leaf Bloom Unlocked 🌿"
    const val MSG_ROUNDING_TEST = "Rounding is where money gets weird."
    const val MSG_FOUNDER_SIGNATURE = "Built with too many cups of chai. — Vinay"

    sealed interface CalculatorEasterEgg {
        val message: String

        data class ZeroMode(override val message: String = MSG_ZERO_MODE) : CalculatorEasterEgg
        data class RoundingTest(override val message: String = MSG_ROUNDING_TEST) : CalculatorEasterEgg
        data class PaisaPerfect(override val message: String = MSG_PAISA_PERFECT) : CalculatorEasterEgg
    }

    /**
     * Inspects a calculator expression and its evaluated output to determine if an Easter Egg applies.
     * Does NOT alter arithmetic values or results in any way.
     */
    fun detectCalculatorEasterEgg(expression: String, resultDisplayString: String): CalculatorEasterEgg? {
        val clean = expression.replace(" ", "").trim()

        // 1. ₹0.00 Mode: User typed 0, 0.0, 0.00, or 00 and evaluated
        if (clean == "0" || clean == "0.0" || clean == "0.00" || clean == "00") {
            return CalculatorEasterEgg.ZeroMode()
        }

        // 2. The ₹1 Test: 1 ÷ 3 × 3
        if (clean == "1÷3×3" || clean == "1/3*3" || clean == "1÷3*3" || clean == "1/3×3") {
            return CalculatorEasterEgg.RoundingTest()
        }

        // 3. Paisa Perfect: Exact fractional paisa reached (e.g. .25, .50, .75, .33, etc.)
        val cleanResult = resultDisplayString.trim()
        val decimalMatch = Regex("""\.\d{2}$""").find(cleanResult)
        if (decimalMatch != null && decimalMatch.value != ".00" && clean.isNotBlank() && clean != "0") {
            return CalculatorEasterEgg.PaisaPerfect()
        }

        return null
    }

    /**
     * Detects if all participants in a split bill have strictly equal, non-zero final shares.
     */
    fun isPerfectSplit(sharesSubunits: List<Long>): Boolean {
        if (sharesSubunits.size < 2) return false
        val first = sharesSubunits.firstOrNull() ?: return false
        if (first <= 0L) return false
        return sharesSubunits.all { it == first }
    }

    /**
     * Determines whether the current device local time corresponds to Midnight Leaf (11 PM - 3:59 AM).
     */
    fun isMidnight(hour: Int = LocalTime.now().hour): Boolean {
        return hour in 0..3 || hour == 23
    }

    enum class SwipeDirection {
        UP, DOWN, LEFT, RIGHT
    }

    /**
     * Tracks the original Leaf-specific sequence inspired by classic secret codes:
     * UP, UP, DOWN, DOWN, LEFT, RIGHT
     */
    class KonamiSequenceTracker(
        private val targetSequence: List<SwipeDirection> = listOf(
            SwipeDirection.UP,
            SwipeDirection.UP,
            SwipeDirection.DOWN,
            SwipeDirection.DOWN,
            SwipeDirection.LEFT,
            SwipeDirection.RIGHT
        )
    ) {
        private var currentIndex = 0

        fun onSwipe(direction: SwipeDirection): Boolean {
            if (targetSequence.isEmpty()) return false

            if (direction == targetSequence[currentIndex]) {
                currentIndex++
                if (currentIndex == targetSequence.size) {
                    currentIndex = 0
                    return true
                }
            } else {
                // If wrong direction matches start of sequence, restart at 1, else reset to 0
                currentIndex = if (direction == targetSequence[0]) 1 else 0
            }
            return false
        }

        fun reset() {
            currentIndex = 0
        }
    }
}
