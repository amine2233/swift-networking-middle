import Foundation
import NetworkingMiddle
import XCTest

public final class NetworkTaskTestRobot: Sendable {
    private let task: NetworkTaskSpy

    init(task: NetworkTaskSpy) {
        self.task = task
    }

    // Given

    /// When
    public func whenResuming() -> Self {
        task.resume()
        return self
    }

    public func whenCancelling() -> Self {
        task.cancel()
        return self
    }

    /// Then
    public func thenVerifyResumeCalled() -> Self {
        XCTAssertTrue(task.invokedResume, "Expected resume() to be called.")
        return self
    }

    public func thenVerifyCancelCalled() -> Self {
        XCTAssertTrue(task.invokedCancel, "Expected cancel() to be called.")
        return self
    }

    public func thenVerifyResumeCalled(times: Int = 1) -> Self {
        XCTAssertEqual(task.invokedResumeCount, times, "Expected resume() to be called \(times) times.")
        return self
    }

    public func thenVerifyCancelCalled(times: Int = 1) -> Self {
        XCTAssertEqual(task.invokedCancelCount, times, "Expected cancel() to be called \(times) times.")
        return self
    }
}

final class NetworkTaskSpy: NetworkTask, @unchecked Sendable {
    var invokedResume = false
    var invokedResumeCount = 0

    func resume() {
        invokedResume = true
        invokedResumeCount += 1
    }

    var invokedCancel = false
    var invokedCancelCount = 0

    func cancel() {
        invokedCancel = true
        invokedCancelCount += 1
    }
}
