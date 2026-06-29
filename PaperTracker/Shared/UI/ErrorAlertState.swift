import Foundation

struct ErrorAlertState: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String

    static func loadFailed(_ detail: String) -> ErrorAlertState {
        ErrorAlertState(
            title: "数据文件无法读取",
            message: detail
        )
    }

    static func saveFailed(_ detail: String) -> ErrorAlertState {
        ErrorAlertState(
            title: "尚未保存到磁盘",
            message: detail
        )
    }
}
