package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.easteregg.EasterEggEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class EasterEggEngineTest {

    // =========================================================================
    // 1. Calculator Easter Egg Detection Tests
    // =========================================================================

    @Test
    fun testDetectZeroMode_TriggersOnZeroVariants() {
        val r1 = EasterEggEngine.detectCalculatorEasterEgg("0", "0.00")
        assertTrue(r1 is EasterEggEngine.CalculatorEasterEgg.ZeroMode)
        assertEquals("Congratulations. You spent nothing.", r1?.message)

        val r2 = EasterEggEngine.detectCalculatorEasterEgg("0.00", "0.00")
        assertTrue(r2 is EasterEggEngine.CalculatorEasterEgg.ZeroMode)

        val r3 = EasterEggEngine.detectCalculatorEasterEgg("00", "0.00")
        assertTrue(r3 is EasterEggEngine.CalculatorEasterEgg.ZeroMode)
    }

    @Test
    fun testDetectOneRupeeTest_TriggersOn1Divide3Multiply3() {
        val r1 = EasterEggEngine.detectCalculatorEasterEgg("1 ÷ 3 × 3", "1.00")
        assertTrue(r1 is EasterEggEngine.CalculatorEasterEgg.RoundingTest)
        assertEquals("Rounding is where money gets weird.", r1?.message)

        val r2 = EasterEggEngine.detectCalculatorEasterEgg("1/3*3", "0.99")
        assertTrue(r2 is EasterEggEngine.CalculatorEasterEgg.RoundingTest)
    }

    @Test
    fun testDetectPaisaPerfect_TriggersOnExactFractionalPaisa() {
        val r1 = EasterEggEngine.detectCalculatorEasterEgg("100 ÷ 3", "33.33")
        assertTrue(r1 is EasterEggEngine.CalculatorEasterEgg.PaisaPerfect)
        assertEquals("Every paisa accounted for.", r1?.message)

        val r2 = EasterEggEngine.detectCalculatorEasterEgg("250.50 + 0.25", "250.75")
        assertTrue(r2 is EasterEggEngine.CalculatorEasterEgg.PaisaPerfect)
    }

    @Test
    fun testDetectCalculatorEasterEgg_DoesNotTriggerOnNormalWholeNumbers() {
        val r1 = EasterEggEngine.detectCalculatorEasterEgg("10 + 20", "30.00")
        assertNull("Whole number result should not trigger paisa perfect", r1)

        val r2 = EasterEggEngine.detectCalculatorEasterEgg("500", "500.00")
        assertNull(r2)
    }

    // =========================================================================
    // 2. Perfect Split Detection Tests
    // =========================================================================

    @Test
    fun testIsPerfectSplit_ReturnsTrueWhenAllSharesEqual() {
        assertTrue(EasterEggEngine.isPerfectSplit(listOf(20000L, 20000L, 20000L)))
        assertTrue(EasterEggEngine.isPerfectSplit(listOf(50000L, 50000L)))
    }

    @Test
    fun testIsPerfectSplit_ReturnsFalseWhenSharesUnequalOrLessThanTwo() {
        assertFalse(EasterEggEngine.isPerfectSplit(listOf(20000L, 25000L, 20000L)))
        assertFalse(EasterEggEngine.isPerfectSplit(listOf(20000L)))
        assertFalse(EasterEggEngine.isPerfectSplit(emptyList()))
        assertFalse(EasterEggEngine.isPerfectSplit(listOf(0L, 0L)))
    }

    // =========================================================================
    // 3. Midnight Leaf Tests
    // =========================================================================

    @Test
    fun testIsMidnight_DetectsMidnightHoursAccurately() {
        assertTrue(EasterEggEngine.isMidnight(0))
        assertTrue(EasterEggEngine.isMidnight(1))
        assertTrue(EasterEggEngine.isMidnight(2))
        assertTrue(EasterEggEngine.isMidnight(3))
        assertTrue(EasterEggEngine.isMidnight(23))

        assertFalse(EasterEggEngine.isMidnight(4))
        assertFalse(EasterEggEngine.isMidnight(8))
        assertFalse(EasterEggEngine.isMidnight(12))
        assertFalse(EasterEggEngine.isMidnight(18))
        assertFalse(EasterEggEngine.isMidnight(22))
    }

    // =========================================================================
    // 4. Konami Sequence Tracker Tests
    // =========================================================================

    @Test
    fun testKonamiSequenceTracker_UnlocksOnExactSequence() {
        val tracker = EasterEggEngine.KonamiSequenceTracker()

        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.UP))
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.UP))
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.DOWN))
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.DOWN))
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.LEFT))
        assertTrue(tracker.onSwipe(EasterEggEngine.SwipeDirection.RIGHT))
    }

    @Test
    fun testKonamiSequenceTracker_ResetsOnWrongInput() {
        val tracker = EasterEggEngine.KonamiSequenceTracker()

        tracker.onSwipe(EasterEggEngine.SwipeDirection.UP)
        tracker.onSwipe(EasterEggEngine.SwipeDirection.UP)
        // Wrong swipe
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.LEFT))
        // Should not unlock immediately
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.RIGHT))
    }

    @Test
    fun testKonamiSequenceTracker_ExplicitResetClearsProgress() {
        val tracker = EasterEggEngine.KonamiSequenceTracker()

        tracker.onSwipe(EasterEggEngine.SwipeDirection.UP)
        tracker.onSwipe(EasterEggEngine.SwipeDirection.UP)
        tracker.onSwipe(EasterEggEngine.SwipeDirection.DOWN)
        tracker.reset()

        // Continuing the previous sequence should now fail because it was reset
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.DOWN))
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.LEFT))
        assertFalse(tracker.onSwipe(EasterEggEngine.SwipeDirection.RIGHT))
    }

    @Test
    fun testDetectCalculatorEasterEgg_HandlesWhitespaceAndSymbols() {
        val r1 = EasterEggEngine.detectCalculatorEasterEgg("  0.00  ", "0.00")
        assertTrue(r1 is EasterEggEngine.CalculatorEasterEgg.ZeroMode)

        val r2 = EasterEggEngine.detectCalculatorEasterEgg(" 1 ÷ 3 × 3 ", "1.00")
        assertTrue(r2 is EasterEggEngine.CalculatorEasterEgg.RoundingTest)

        // Normal computation should never trigger ZeroMode or RoundingTest
        val r3 = EasterEggEngine.detectCalculatorEasterEgg("150 + 250", "400.00")
        assertNull(r3)
    }

    @Test
    fun testSplit2Model_EqualityDetectionDoesNotAlterAmounts() {
        // Equal split: 1000 divided among 5 friends equally = 200 each (20000 subunits)
        val equalShares = listOf(20000L, 20000L, 20000L, 20000L, 20000L)
        assertTrue(EasterEggEngine.isPerfectSplit(equalShares))

        // Unequal custom split: 250, 250, 200, 200, 100
        val customShares = listOf(25000L, 25000L, 20000L, 20000L, 10000L)
        assertFalse(EasterEggEngine.isPerfectSplit(customShares))
    }
}
