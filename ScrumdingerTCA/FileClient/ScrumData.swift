import SwiftUI

struct ScrumData: Codable, Equatable {
  let attendees: [String]
  let color: Color
  let history: [History]
  let id: UUID
  let lengthInMinutes: Int
  let title: String

  struct History: Codable, Equatable {
    let attendees: [String]
    let date: Date
    let id: UUID
    let lengthInMinutes: Int
    let transcript: String?
  }

  struct Color: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
  }
}

extension ScrumData {
  init(_ scrum: Scrum) {
    self.attendees = scrum.attendees
    self.color = Color(scrum.color)
    self.history = scrum.history.map(History.init)
    self.id = scrum.id
    self.lengthInMinutes = scrum.lengthInMinutes
    self.title = scrum.title
  }
}

extension Scrum {
  init(_ scrum: ScrumData) {
    self.attendees = scrum.attendees
    self.color = Color(scrum.color)
    self.history = scrum.history.map(Scrum.History.init)
    self.id = scrum.id
    self.lengthInMinutes = scrum.lengthInMinutes
    self.title = scrum.title
  }
}

extension ScrumData.History {
  init(_ history: Scrum.History) {
    self.attendees = history.attendees
    self.date = history.date
    self.id = history.id
    self.lengthInMinutes = history.lengthInMinutes
    self.transcript = history.transcript
  }
}

extension Scrum.History {
  init(_ history: ScrumData.History) {
    self.attendees = history.attendees
    self.date = history.date
    self.id = history.id
    self.lengthInMinutes = history.lengthInMinutes
    self.transcript = history.transcript
  }
}

extension ScrumData.Color {
  init(_ color: SwiftUI.Color) {
    (self.red, self.green, self.blue, self.opacity) = color.components
  }
}

extension Color {
  init(_ color: ScrumData.Color) {
    self.init(
      .sRGB,
      red: color.red,
      green: color.green,
      blue: color.blue,
      opacity: color.opacity
    )
  }
}
