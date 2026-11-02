import Foundation

final class LoggerPrinterMock: @unchecked Sendable {
    var printerCalls: [String] = []

    func printer(_ string: String) {
        printerCalls.append(string)
    }
}
