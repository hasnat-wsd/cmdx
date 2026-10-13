/// Asks Finder to perform one of its native commands.
@MainActor
public protocol FinderCommandSending: AnyObject {
    func send(_ command: FinderCommand)
}
