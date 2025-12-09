import Foundation
import Swifter
struct UploadedFile: Identifiable, Hashable {
    let url: URL
    let date: Date

    var id: String { url.path }          // unique per file
    var name: String { url.lastPathComponent }
}


class WebServer: ObservableObject {
    private let server = HttpServer()
    private(set) var isRunning = false

    let port: UInt16 = 8080

    /// ~/Downloads/LocalUploads
    let uploadsDirectory: URL

    @Published var uploadedFiles: [UploadedFile] = []

    init() {
        // Setup uploads directory
        let downloads = FileManager.default.urls(for: .downloadsDirectory,
                                                 in: .userDomainMask).first!
        let folder = downloads.appendingPathComponent("LocalUploads", isDirectory: true)
        self.uploadsDirectory = folder

        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // Initial load
        refreshFileList()
        
        server["/"] = { _ in
            let html = """
            <!doctype html>
            <html lang="en">
            <head>
                <meta charset="utf-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <title>Upload to Mac</title>
                <style>
                    body {
                        margin: 0;
                        padding: 0;
                        font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
                        background: #f3f4f6;
                        color: #111827;
                    }
                    .container {
                        min-height: 100vh;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        padding: 16px;
                    }
                    .card {
                        background: #ffffff;
                        border-radius: 16px;
                        padding: 24px 20px;
                        max-width: 420px;
                        width: 100%;
                        box-shadow: 0 10px 25px rgba(0,0,0,0.05);
                    }
                    h1 {
                        font-size: 22px;
                        margin: 0 0 4px;
                        text-align: center;
                    }
                    p.subtitle {
                        font-size: 14px;
                        margin: 0 0 20px;
                        text-align: center;
                        color: #6b7280;
                    }
                    .field {
                        margin-bottom: 16px;
                    }
                    .file-input {
                        width: 100%;
                        padding: 10px;
                        font-size: 14px;
                    }
                    .button {
                        width: 100%;
                        padding: 12px;
                        font-size: 16px;
                        border-radius: 999px;
                        border: none;
                        background: #2563eb;
                        color: #ffffff;
                        font-weight: 600;
                        cursor: pointer;
                    }
                    .button:active {
                        transform: scale(0.98);
                    }
                    .note {
                        margin-top: 10px;
                        font-size: 12px;
                        text-align: center;
                        color: #9ca3af;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="card">
                        <h1>Send file to Mac</h1>
                        <p class="subtitle">Choose any file from this device and upload it to your Mac.</p>

                        <form action="/upload" method="post" enctype="multipart/form-data">
                            <div class="field">
                                <input class="file-input" type="file" name="file" required />
                            </div>
                            <button class="button" type="submit">Upload</button>
                        </form>

                        <p class="note">Make sure this phone and your Mac are on the same Wi-Fi.</p>
                    </div>
                </div>
            </body>
            </html>
            """
            return HttpResponse.ok(.html(html))
        }

        // "/upload" – save file and update list
        
        server["/upload"] = { [weak self] request in
            guard let self = self else { return HttpResponse.internalServerError }

            let parts = request.parseMultiPartFormData()
            guard let filePart = parts.first(where: { $0.name == "file" }) else {
                return HttpResponse.badRequest(.text("No file selected"))
            }

            let data = Data(filePart.body)
            let fileName = filePart.fileName ?? "upload-\(Int(Date().timeIntervalSince1970))"
            let saveURL = self.uploadsDirectory.appendingPathComponent(fileName)

            do {
                try data.write(to: saveURL)
                DispatchQueue.main.async {
                    self.refreshFileList()
                }

                // 🔥 New mobile responsive success UI
                let html = """
                <!doctype html>
                <html lang="en">
                <head>
                    <meta charset="utf-8" />
                    <meta name="viewport" content="width=device-width, initial-scale=1" />
                    <title>Upload Successful</title>
                    <style>
                        body {
                            margin: 0;
                            padding: 0;
                            font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
                            background: #f3f4f6;
                            color: #111827;
                        }
                        .container {
                            min-height: 100vh;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            padding: 16px;
                        }
                        .card {
                            background: #ffffff;
                            border-radius: 16px;
                            padding: 28px 22px;
                            max-width: 420px;
                            width: 100%;
                            box-shadow: 0 10px 25px rgba(0,0,0,0.06);
                            text-align: center;
                        }
                        h2 {
                            font-size: 22px;
                            margin-bottom: 8px;
                        }
                        p {
                            font-size: 14px;
                            color: #374151;
                        }
                        .file-name {
                            margin-top: 8px;
                            font-size: 15px;
                            color: #111827;
                            font-weight: 600;
                        }
                        .button {
                            margin-top: 20px;
                            display: inline-block;
                            padding: 12px 22px;
                            font-size: 16px;
                            border-radius: 999px;
                            background: #2563eb;
                            color: #ffffff;
                            font-weight: 600;
                            text-decoration: none;
                        }
                        .button:active {
                            transform: scale(0.97);
                        }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="card">
                            <h2>Upload Complete 🎉</h2>
                            <p>Your file has been successfully sent to your Mac.</p>
                            <div class="file-name">\(fileName)</div>

                            <a href="/" class="button">Upload Another</a>
                        </div>
                    </div>
                </body>
                </html>
                """

                return HttpResponse.ok(.html(html))

            } catch {
                return HttpResponse.internalServerError
            }
        }


        // "/files/:name" – serve file (same as before)
        server["/files/:name"] = { [weak self] request in
            guard let self = self else { return HttpResponse.internalServerError }

            guard let name = request.params[":name"]?.removingPercentEncoding else {
                return HttpResponse.badRequest(.text("Invalid file name"))
            }

            let fileURL = self.uploadsDirectory.appendingPathComponent(name)

            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return HttpResponse.notFound
            }

            do {
                let data = try Data(contentsOf: fileURL)
                return HttpResponse.raw(200, "OK", ["Content-Type": "application/octet-stream"]) { writer in
                    try? writer.write(data)
                }
            } catch {
                return HttpResponse.internalServerError
            }
        }
    }

    func start() {
        guard !isRunning else { return }

        do {
            try server.start(port, forceIPv4: true)
            isRunning = true
            print("Server started on port \(port)")
        } catch {
            print("❌ Failed to start server: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }
        server.stop()
        isRunning = false
    }
    
    func refreshFileList() {
        let fm = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey]

        let urls = (try? fm.contentsOfDirectory(at: uploadsDirectory,
                                                includingPropertiesForKeys: Array(resourceKeys),
                                                options: [.skipsHiddenFiles])) ?? []

        let items: [UploadedFile] = urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: resourceKeys)
            let date = values?.contentModificationDate ?? .distantPast
            return UploadedFile(url: url, date: date)
        }

        // newest first
        uploadedFiles = items.sorted { $0.date > $1.date }
    }
}
