import SwiftUI

@main
struct ZenBackupManagerApp: App {
    @State private var hasStarted = false
    @StateObject private var model = AppModel()
    @StateObject private var updater = UpdateChecker(configuration: .init(owner: "L-K-M", repo: "ZenBackupManager"))

    var body: some Scene {
        Window("Zen Backup Manager", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 980, minHeight: 640)
                .task {
                    guard !hasStarted else { return }
                    hasStarted = true
                    model.start()
                    updater.start()
                }
        }
        .defaultSize(width: 1220, height: 800)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updater.checkNow() }.disabled(updater.isChecking)
            }
            CommandGroup(replacing: .newItem) {
                Button("Choose Profile Folder…") { model.chooseProfile() }.disabled(model.busy)
                Button("Refresh Backups") { model.refresh() }.keyboardShortcut("r").disabled(model.busy)
            }
        }
        Settings {
            Form {
                Toggle("Check for updates automatically", isOn: $updater.automaticChecksEnabled)
                Text("Only the update checker contacts GitHub. Backups and tab previews stay on this Mac.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Show Safety Copies in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: model.safetyRoot.path)
                }
            }.padding(24).frame(width: 440)
        }
    }
}
