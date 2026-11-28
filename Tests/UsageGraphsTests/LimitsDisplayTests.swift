import Foundation
import Testing
import UsageCore
@testable import UsageGraphs

struct LimitsDisplayTests {
    let now = Date(timeIntervalSince1970: 1_792_425_600)

    @Test func percentRoundsDownForBothUsedAndRemaining() {
        let zero = LimitMeter.percent("s", "Session", used: 0, resetsAt: nil, period: nil)
        #expect(LimitText.percent(zero, remaining: false) == 0)
        #expect(LimitText.percent(zero, remaining: true) == 100)

        // Small non-zero usage never promises 100% remaining.
        let tiny = LimitMeter.percent("s", "Session", used: 0.4, resetsAt: nil, period: nil)
        #expect(LimitText.percent(tiny, remaining: false) == 0)
        #expect(LimitText.percent(tiny, remaining: true) == 99)

        let mid = LimitMeter.percent("s", "Session", used: 58, resetsAt: nil, period: nil)
        #expect(LimitText.percent(mid, remaining: false) == 58)
        #expect(LimitText.percent(mid, remaining: true) == 42)

        let full = LimitMeter.percent("s", "Session", used: 100, resetsAt: nil, period: nil)
        #expect(LimitText.percent(full, remaining: false) == 100)
        #expect(LimitText.percent(full, remaining: true) == 0)
    }

    @Test func amountFormatsPercentDollarsAndCountsInBothModes() {
        let pct = LimitMeter.percent("s", "Session", used: 33, resetsAt: nil, period: nil)
        #expect(LimitText.amount(pct, remaining: false) == "33%")
        #expect(LimitText.amount(pct, remaining: true) == "67%")

        let dollars = LimitMeter(id: "d", label: "On-demand", used: 3, limit: 250, unit: .dollars)
        #expect(LimitText.amount(dollars, remaining: false) == "$3/$250")
        #expect(LimitText.amount(dollars, remaining: true) == "$247/$250")

        let requests = LimitMeter(id: "r", label: "Requests", used: 120, limit: 500, unit: .count)
        #expect(LimitText.amount(requests, remaining: false) == "120/500")
        #expect(LimitText.amount(requests, remaining: true) == "380/500")

        let large = LimitMeter(id: "l", label: "Tokens", used: 12_300, limit: 100_000, unit: .count)
        #expect(LimitText.amount(large, remaining: false) == "12.3K/100K")
        #expect(LimitText.amount(large, remaining: true) == "87.7K/100K")

        // Used past limit clamps remaining at 0 rather than going negative.
        let over = LimitMeter(id: "o", label: "Requests", used: 550, limit: 500, unit: .count)
        #expect(LimitText.amount(over, remaining: true) == "0/500")
    }

    @Test func factsDescribeUsedOrLeftAndPaceProjection() {
        let resetsAt = now.addingTimeInterval(2.5 * 3600)
        let meter = LimitMeter.percent("s", "Session", used: 30, resetsAt: resetsAt, period: 5 * 3600)
        let pace = Pace(meter, now: now)

        let usedFacts = LimitText.facts(meter, pace: pace, now: now, remaining: false)
        #expect(usedFacts.first == "30% used")
        #expect(usedFacts.contains("on pace for ~60% by then"))

        let leftFacts = LimitText.facts(meter, pace: pace, now: now, remaining: true)
        #expect(leftFacts.first == "70% left")
        #expect(leftFacts.contains("on pace for ~40% left by then"))
    }
}
