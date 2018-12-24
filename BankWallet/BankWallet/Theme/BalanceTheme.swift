import UIKit

class BalanceTheme {
    static let headerHeight: CGFloat = 44
    static var headerSeparatorBackground: UIColor { return .cryptoSteel20 }
    static let amountFont: UIFont = .systemFont(ofSize: 22, weight: .semibold)
    static let amountColor = UIColor.cryptoYellow
    static let amountColorSyncing = UIColor.cryptoYellow40

    static let cellBigMargin: CGFloat = 12
    static let cellSmallMargin: CGFloat = 8
    static let expandedCellHeight: CGFloat = 138
    static let cellPadding: CGFloat = 8
    static let cellHeight: CGFloat = 80

    static var roundedBackgroundColor: UIColor { return .crypto_Steel20_White }
    static let roundedBackgroundCornerRadius: CGFloat = 15

    static let coinIconTintColor = UIColor.cryptoGray
    static let coinIconSide: CGFloat = 24

    static let cellTitleFont = UIFont.cryptoHeadline
    static var cellTitleColor: UIColor { return .crypto_White_Black }

    static let rateTopMargin: CGFloat = 19
    static let rateFont = UIFont.cryptoCaption1
    static let rateColor = UIColor.cryptoGray
    static let rateExpiredColor = UIColor.cryptoGray50

    static let spinnerLineWidth: CGFloat = 2
    static let spinnerSideSize: CGFloat = 16

    static let refreshButtonSize: CGFloat = 32
    static let refreshButtonColor: UIColor = .cryptoGray
    static let refreshButtonColorHighlighted: UIColor = .cryptoGray50

    static let nonZeroBalanceTextColor = UIColor.cryptoYellow
    static let nonZeroBalanceExpiredTextColor = UIColor.cryptoYellow40
    static let zeroBalanceTextColor = UIColor.cryptoGray
    static let coinValueFont: UIFont = .systemFont(ofSize: 14)
    static var coinValueColor: UIColor { return .crypto_Bars_Dark }

    static let currencyValueFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)

    static let buttonsTopMargin: CGFloat = 50
    static let buttonsHeight: CGFloat = 50
    static let buttonCornerRadius: CGFloat = 12
    static let buttonsAnimationDuration = 0.2
}
