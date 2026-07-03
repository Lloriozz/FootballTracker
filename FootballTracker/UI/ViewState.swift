import Foundation

/// Standard screen-loading state used by view models.
enum ViewState<Value> {
    /// The screen has not started loading yet.
    case idle

    /// A request is in progress.
    case loading

    /// Data loaded successfully.
    case loaded(Value)

    /// The request succeeded but returned no displayable data.
    case empty

    /// The request failed with a user-facing message.
    case error(String)
}
