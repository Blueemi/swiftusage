import Foundation
import Observation
import UsageCore

/// What the person chose in Customize: which providers the panel follows and how often their limits are
/// read. A provider that's turned off leaves the picker, the totals, the Limits tab and the menu bar, and
/// its history and limits aren't read.
@MainActor
@Observable
final class Preferences {
    var hiddenProviders: Set<Provider> {
        didSet {
            guard hiddenProviders != oldValue else { return }
            UserDefaults.standard.set(hiddenProviders.map(\.rawValue).sorted(), forKey: "hiddenProviders")
            onProvidersChange?()
        }
    }
    /// Set by the menu bar controller, which owns the stores that read the providers.
    @ObservationIgnored var onProvidersChange: (() -> Void)?

    /// How often each provider is asked for its limits, in seconds; one of `limitsIntervals`.
    var limitsInterval: TimeInterval {
        didSet {
            guard limitsInterval != oldValue else { return }
            UserDefaults.standard.set(limitsInterval, forKey: "limitsInterval")
        }
    }

    /// The intervals Customize offers, and the default of five minutes.
    static let limitsIntervals: [TimeInterval] = [60, 120, 300, 900, 1800, 3600]
    static let defaultLimitsInterval: TimeInterval = 300

    init() {
        let defaults = UserDefaults.standard
        // Only the app's very first run chooses providers, before it has ever opened. Kept until the
        // choice is made, in case it quits first; settings from before this existed stay as they were.
        if defaults.object(forKey: "hasOpened") == nil, defaults.object(forKey: "hiddenProviders") == nil {
            defaults.set(true, forKey: "choosesProviders")
        }
        hiddenProviders = Set((defaults.stringArray(forKey: "hiddenProviders") ?? []).compactMap(Provider.init(rawValue:)))
        let interval = defaults.double(forKey: "limitsInterval")
        limitsInterval = Self.limitsIntervals.contains(interval) ? interval : Self.defaultLimitsInterval
    }

    /// In the picker's order.
    var shownProviders: [Provider] {
        Provider.allCases.filter { !hiddenProviders.contains($0) }
    }

    func isShown(_ provider: Provider) -> Bool {
        !hiddenProviders.contains(provider)
    }

    /// Whether this is the first run, still with every provider on, and the person hasn't turned any
    /// on or off in Customize since.
    var isChoosingProviders: Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: "choosesProviders") && defaults.object(forKey: "hiddenProviders") == nil
    }

    /// Leaves on only the providers found on this Mac, the rest waiting in Customize. With none found,
    /// every provider stays on. Either way the choice is made once: a tool installed later doesn't turn
    /// the others off.
    func keepOnly(found: Set<Provider>) {
        let defaults = UserDefaults.standard
        if isChoosingProviders, !found.isEmpty {
            hiddenProviders = Set(Provider.allCases).subtracting(found)
            defaults.set(hiddenProviders.map(\.rawValue).sorted(), forKey: "hiddenProviders")
        }
        defaults.removeObject(forKey: "choosesProviders")
    }

    /// Turns a provider on or off. The last one on stays on, so the panel always has something to show.
    func setShown(_ provider: Provider, _ shown: Bool) {
        if shown {
            hiddenProviders.remove(provider)
        } else if shownProviders != [provider] {
            hiddenProviders.insert(provider)
        }
    }

    /// `5 min`, `1 hour`.
    static func intervalTitle(_ interval: TimeInterval) -> String {
        interval < 3600 ? "\(Int(interval / 60)) min" : "1 hour"
    }
}
