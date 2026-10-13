/// Reports which application currently receives keyboard input.
@MainActor
public protocol FrontmostApplicationProviding: AnyObject {
    func isFinderFrontmost() -> Bool
}
