import ComposableArchitecture

extension FileClient {
  func loadScrums() -> Effect<Result<Scrums, NSError>, Never> {
    self.load([ScrumData].self, from: scrumsFilename)
      .map { $0.map { Scrums($0.map(Scrum.init)) } }
      .eraseToEffect()
  }

  func saveScrums(_ state: Scrums) -> Effect<Never, Never> {
    self.save(state.scrums.map(ScrumData.init), to: scrumsFilename)
  }
}

private let scrumsFilename = "scrums.data"

