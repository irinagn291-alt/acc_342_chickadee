import SwiftUI

/// Root chrome. Reads `ReviewLaunch.screen` once, after the rite is ready,
/// and opens that destination. Today stays on the unfurled rite.

@MainActor
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: RitualSession?
    @State private var cover: Cover?
    @State private var path: [Int] = []
    @State private var didReadReview = false
    @State private var reviewInstant = false
    @State private var replaying = false
    @State private var breathCue = false

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            if let session {
                if session.record.onboardingComplete && !replaying {
                    NavigationStack {
                        TimelineView(.periodic(from: .now, by: 30)) { context in
                            RitualView(
                                session: session,
                                now: context.date,
                                breathCue: breathCue,
                                onHistory: { cover = .log },
                                onSettings: { cover = .goals },
                                onReflect: { cover = .reflect },
                                onRetry: { Task { await reload() } }
                            )
                        }
                    }
                } else {
                    OnboardingView(session: session) {
                        replaying = false
                        consumeReview()
                    }
                }
            } else {
                RitualSkeleton()
                    .redacted(reason: .placeholder)
                    .accessibilityLabel("Loading")
            }
        }
        .sheet(item: $cover) { item in
            sheet(item)
        }
        .task {
            if session == nil {
                session = await RitualSession.openLive()
            }
            consumeReview()
        }
        .onChange(of: scenePhase) { _, phase in
            session?.noteScene(phase)
        }
        .onChange(of: session?.record.onboardingComplete) { _, complete in
            if complete == true { consumeReview() }
        }
    }

    @ViewBuilder
    private func sheet(_ item: Cover) -> some View {
        if let session {
            NavigationStack(path: $path) {
                sheetRoot(item, session: session)
                    .navigationDestination(for: Int.self) { key in
                        if let night = night(key, in: session) {
                            NightScreen(night: night, spread: false)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                cover = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(DesignTokens.ink)
                                    .frame(minWidth: Measure.hit, minHeight: Measure.hit)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Close")
                        }
                    }
            }
            .presentationBackground(DesignTokens.bg)
            .presentationDragIndicator(.visible)
            .modifier(SheetEntrance(instant: reviewInstant))
        }
    }

    @ViewBuilder
    private func sheetRoot(_ item: Cover, session: RitualSession) -> some View {
        switch item {
        case .log:
            HistoryView(
                session: session,
                onSelect: { path.append($0) },
                onBegin: { cover = nil },
                onRetry: { Task { await reload() } }
            )
        case .goals, .settings:
            SettingsView(
                session: session,
                onBegin: { cover = nil },
                onRetry: { Task { await reload() } },
                onReplay: {
                    cover = nil
                    replaying = true
                },
                onDidReset: {
                    cover = nil
                    replaying = false
                }
            )
        case .reflect:
            ReflectView(session: session, now: Date())
        case .breathe:
            DesignTokens.bg.ignoresSafeArea()
                .onAppear {
                    breathCue = true
                    cover = nil
                }
        case .history:
            if let night = nights(in: session).first {
                NightScreen(night: night, spread: false)
            } else {
                HistoryView(
                    session: session,
                    onSelect: { path.append($0) },
                    onBegin: { cover = nil },
                    onRetry: { Task { await reload() } }
                )
            }
        case .rolled:
            RolledScreen(night: nights(in: session).first)
        case .night:
            if let night = nights(in: session).dropFirst().first ?? nights(in: session).first {
                NightScreen(night: night, spread: true)
            } else {
                RolledScreen(night: nil)
            }
        }
    }

    private func consumeReview() {
        guard !didReadReview, let session, session.record.onboardingComplete, !replaying else { return }
        didReadReview = true
        let key = ReviewLaunch.screen
        reviewInstant = key != nil
        if key == "breathe" {
            breathCue = true
            cover = nil
        } else {
            cover = Cover.resolve(key)
        }
        path = []
    }

    private func reload() async {
        session = await RitualSession.openLive()
    }

    private func nights(in session: RitualSession) -> [NightMark] {
        HistorySurface.make(record: session.record, notice: nil).nights
    }

    private func night(_ key: Int, in session: RitualSession) -> NightMark? {
        nights(in: session).first { $0.dayKey == key }
    }
}

enum Cover: Identifiable, Equatable {
    case log
    case goals
    case reflect
    case breathe
    case history
    case settings
    case rolled
    case night

    var id: String {
        switch self {
        case .log: "log"
        case .goals: "goals"
        case .reflect: "reflect"
        case .breathe: "breathe"
        case .history: "history"
        case .settings: "settings"
        case .rolled: "rolled"
        case .night: "night"
        }
    }

    static func resolve(_ key: String?) -> Cover? {
        switch key {
        case "log": .log
        case "goals": .goals
        case "reflect": .reflect
        case "breathe": .breathe
        case "history": .history
        case "settings": .settings
        case "rolled": .rolled
        case "night": .night
        default: nil
        }
    }
}

#Preview {
    ContentView()
}
