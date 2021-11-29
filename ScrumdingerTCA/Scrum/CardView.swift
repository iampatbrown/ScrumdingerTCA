import SwiftUI

struct CardView: View {
  let scrum: Scrum
  var body: some View {
    VStack(alignment: .leading) {
      Text(scrum.title)
        .font(.headline)
      Spacer()
      HStack {
        Label("\(scrum.attendees.count)", systemImage: "person.3")
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(Text("Attendees"))
          .accessibilityValue(Text("\(scrum.attendees.count)"))
        Spacer()
        Label("\(scrum.lengthInMinutes)", systemImage: "clock")
          .padding(.trailing, 20)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(Text("Meeting length"))
          .accessibilityValue(Text("\(scrum.lengthInMinutes) minutes"))
      }
      .font(.caption)
    }
    .padding()
    .foregroundColor(scrum.color.accessibleFontColor)
  }
}
