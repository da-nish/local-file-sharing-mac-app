import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var webServer: WebServer
    @State private var serverURL: String = "http://localhost:8080"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top){
                VStack(spacing: 8) {
                    if let image = QRCodeGenerator.generate(from: serverURL) {
                        Image(nsImage: image)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 100, height: 100)
                    } else {
                        Text("QR generation failed")
                            .foregroundColor(.red)
                    }

                    Text("\(serverURL.prefix(44))\(serverURL.count>44 ? "..." : "")")
                        .font(.caption)
                        .textSelection(.enabled)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                
                .background(.gray.opacity(0.1))
                .cornerRadius(12)
                
                VStack(alignment: .leading){
                    Text("Local Share Server")
                        .font(.title2)
                    
                    Text(serverURL)
                        .font(.caption)
                        .textSelection(.enabled)
                    Spacer()
                        .frame(height: 10)

                    Text("Uploads folder: \(webServer.uploadsDirectory.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Spacer()
                        .frame(height: 6)

                    HStack {
                        Button("Refresh list") {
                            webServer.refreshFileList()
                        }

                        Spacer()
                    }
                }
            }

            List(webServer.uploadedFiles) { file in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.body)

                        Text(file.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(file.url.path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Locate") {
                        locateInFinder(file.url)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .onAppear {
            webServer.refreshFileList()
            updateServerURL()
        }
    }
    
    private func updateServerURL() {
        // Use your existing getWiFiIP() here
        if let ip = getIP() {
            serverURL = "http://\(ip):\(webServer.port)"
        } else {
            serverURL = "http://localhost:\(webServer.port)"
        }
    }

    private func locateInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}


#Preview {
    ContentView()
        .environmentObject(WebServer())
}
