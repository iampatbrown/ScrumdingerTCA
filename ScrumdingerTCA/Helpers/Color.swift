import SwiftUI

extension Color {
  static var random: Self {
    Self(
      .sRGB,
      red: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1),
      opacity: 1
    )
  }

  var components: (red: Double, green: Double, blue: Double, opacity: Double) {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var opacity: CGFloat = 0
    UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
    return (red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(opacity))
  }

  var luminance: Double {
    let (red, green, blue, _) = self.components
    return red * 0.299 + green * 0.587 + blue * 0.114
  }

  var accessibleFontColor: Color { self.luminance > 0.5 ? .black : .white }
}
