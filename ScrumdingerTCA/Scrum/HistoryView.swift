import SwiftUI

struct HistoryView: View {
  let history: Scrum.History
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Divider()
          .padding(.bottom)
        Text("Attendees")
          .font(.headline)
        Text(history.attendeeString)
        if let transcript = history.transcript {
          Text("Transcript")
            .font(.headline)
            .padding(.top)
          Text(transcript)
        }
      }
    }
    .navigationTitle(Text(history.date, style: .date))
    .padding()
  }
}

extension Scrum.History {
  var attendeeString: String {
    ListFormatter.localizedString(byJoining: attendees)
  }
}

struct HistoryView_Previews: PreviewProvider {
  static var previews: some View {
    HistoryView(history: Scrum.History(
      attendees: ["Jon", "Darla", "Luis"],
      lengthInMinutes: 10,
      transcript: "Darla, would you like to start today? Sure, yesterday I reviewed Luis' PR and met with the design team to finalize the UI..."
    ))
  }
}
