import CCloudDesignSystem
import SwiftUI

/// App version, links and credits.
struct AboutScreen: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Brand.logo
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: logoSize, height: logoSize)
                        .clipShape(RoundedRectangle(cornerRadius: logoSize * 0.225, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        .accessibilityHidden(true)
                    Text(verbatim: "CCloud")
                        .appFont(.title2, weight: .bold)
                    Text(L10n.About.version(version, build: build))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(L10n.About.tagline)
                        .appFont(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            #if !os(tvOS)
            Section {
                Link(destination: URL(string: "https://github.com/IbrahimHosseini/CCloud_apple")!) {
                    Label(L10n.About.sourceCode, systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/IbrahimHosseini/CCloud")!) {
                    Label(L10n.About.androidProject, systemImage: "iphone.gen3")
                }
            }
            #endif

            Section(L10n.About.credits) {
                Text(L10n.About.androidCredit)
                Text(L10n.About.fontCredit)
                Text(L10n.About.vlcCredit)
            }
            .appFont(.footnote)
            .foregroundStyle(.secondary)
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        .navigationTitle(L10n.About.title)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    #if os(tvOS)
    private let logoSize: CGFloat = 180
    #else
    private let logoSize: CGFloat = 96
    #endif
}
