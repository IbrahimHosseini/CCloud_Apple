import Foundation

public enum Formatting {
    /// "1:05:09" or "5:09" for a playback position.
    public static func playbackTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let duration = Duration.seconds(seconds.rounded(.down))
        return seconds >= 3600
            ? duration.formatted(.time(pattern: .hourMinuteSecond))
            : duration.formatted(.time(pattern: .minuteSecond))
    }

    /// "12 KB"
    public static func bytes(_ count: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }

    /// "120%"
    public static func percent(_ value: Int) -> String {
        (Double(value) / 100).formatted(.percent.precision(.fractionLength(0)))
    }

    /// "1.25×"
    public static func playbackRate(_ rate: Float) -> String {
        Double(rate).formatted(.number.precision(.fractionLength(0...2))) + "×"
    }
}
