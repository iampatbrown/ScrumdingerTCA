import ComposableArchitecture

extension FileClient {
  static var live: Self {
    let documentDirectory = FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)
      .first!

    return Self(
      delete: { filename in
        .fireAndForget {
          try? FileManager.default.removeItem(
            at: documentDirectory
              .appendingPathComponent(filename)
              .appendingPathExtension("json")
          )
        }
      },
      load: { filename in
        .catching {
          try Data(
            contentsOf: documentDirectory
              .appendingPathComponent(filename)
              .appendingPathExtension("json")
          )
        }
      },
      save: { filename, data in
        .fireAndForget {
          try? data.write(
            to: documentDirectory
              .appendingPathComponent(filename)
              .appendingPathExtension("json")
          )
        }
      }
    )
  }
}
