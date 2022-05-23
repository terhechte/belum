import Foundation

/// A very lightweight dependency injection container.
/// It uses keypaths and generics to provide a very seamless dependency access experience.
@dynamicMemberLookup
public struct Belum<Members> {
    internal final class Storage {
        private let mutationQueue: DispatchQueue
        var members: Members
        var initializers: [PartialKeyPath<Members>: () -> Any]

        init(_ members: Members, initializationQueue: DispatchQueue) {
            self.members = members
            self.mutationQueue = initializationQueue
            self.initializers = [:]
        }

        public subscript<U>(memberKeyPath keyPath: WritableKeyPath<Members, U>) -> U {
            /// If the initializer hasn't run yet, run the initializer once.
            if initializers[keyPath] != nil {
                mutationQueue.sync {
                    if let value = initializers.removeValue(forKey: keyPath) {
                        /// If this fails we can't return nil or throw, we have to give up
                        guard let typedValue = value() as? U else {
                            fatalError("Initializer returned invalid type \(String(describing: value))")
                        }
                        members[keyPath: keyPath] = typedValue
                    }
                }
            }
            /// Once a initializer has been run once, this is the fast path for all subsequent accesses
            return members[keyPath: keyPath]
        }
    }

    /// This type is used to register dependencies on app startup.
    /// All the extensions for this type can be found in `Dependencies.swift`
    public struct Registrar {
        internal let storage: Storage

        fileprivate init(_ storage: Storage) {
            self.storage = storage
        }
    }

    private let storage: Storage

    /// Initialize a Belum.
    /// - parameter members: The struct defininig all the dependencies the app contains
    /// - parameter initializationQueue: The queue on which dependencies are lazily initialized on first access. Can't be the main queue
    public init(_ members: Members, initializationQueue: DispatchQueue = DispatchQueue(label: "com.belum.initializationQueue")) {
        self.storage = Storage(members, initializationQueue: initializationQueue)
    }

    public subscript<U>(dynamicMember keyPath: WritableKeyPath<Members, U>) -> U {
        return storage[memberKeyPath: keyPath]
    }
}

extension Belum {
    /// Initialize the Belum to register all dependencies.
    /// This should be run on App Startup
    public func setup(registration: (Registrar) -> Void) {
        registration(Registrar(storage))
    }
}
