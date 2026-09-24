import SwiftUI

public enum Brand {
    /// The app icon artwork, for About screens.
    public static var logo: Image {
        Image("Logo", bundle: .module)
    }
}
