import ComposableArchitecture

extension FileClient {
  func loadScrums() -> Effect<Result<Scrums, NSError>, Never> {
    self.load([ScrumData].self, from: scrumsFileName)
      .map { $0.map { Scrums($0.map(Scrum.init)) } }
      .eraseToEffect()
  }

  func saveScrums(_ state: Scrums) -> Effect<Never, Never> {
    self.save(state.scrums.map(ScrumData.init), to: scrumsFileName)
  }
}

private let scrumsFileName = "scrums.data"
