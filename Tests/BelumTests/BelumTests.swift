import XCTest
@testable import Belum

protocol FirstProtocol {
    var number: Int { get }
}

typealias FirstDependencies = Dependencies2<
    TestMembers,
    SecondProtocol,
    ThirdProtocol
>

final class FirstClass: FirstProtocol {
    var number: Int {
        42
    }

    public let dependencies: FirstDependencies
    public init(_ dependencies: FirstDependencies) {
        self.dependencies = dependencies
    }
}

protocol SecondProtocol {
    var number: Int { get }
}

typealias SecondDependencies = Dependencies1<
    TestMembers,
    ThirdProtocol
>

final class SecondClass: SecondProtocol {
    var number: Int {
        24
    }

    public let dependencies: SecondDependencies
    public init(_ dependencies: SecondDependencies) {
        self.dependencies = dependencies
    }
}

protocol ThirdProtocol {
    var number: Int { get }
}

final class ThirdClass: ThirdProtocol {
    var number: Int {
        dependencies.first?.number ?? 0
    }

    public let dependencies: ThirdDependencies
    public init(_ dependencies: ThirdDependencies) {
        self.dependencies = dependencies
    }
}

typealias ThirdDependencies = Dependencies2<
    TestMembers,
    FirstProtocol,
    SecondProtocol
>

public struct TestMembers {
    var first: FirstProtocol!
    var second: SecondProtocol!
    var third: ThirdProtocol!

    public init() {}
}


final class BelumTests: XCTestCase {
    var belum: Belum<TestMembers> = {
        let belum = Belum(TestMembers())
        // Add reverse dependencies
        belum.setup { registrar in
            registrar.register(
                { FirstClass($0) },
                for: \.first,
                dependencies: \.second, \.third)
            registrar.register(
                { SecondClass($0) },
                for: \.second,
                dependencies: \.third)
            registrar.register(
                { ThirdClass($0) },
                for: \.third,
                dependencies: \.first, \.second)
        }
        return belum
    }()

    func testExample() throws {
        XCTAssertEqual(belum.third?.number, 42)
    }
}
