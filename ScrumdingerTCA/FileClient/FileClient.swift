import ComposableArchitecture
import Foundation

struct FileClient {
  var delete: (String) -> Effect<Never, Error>
  var load: (String) -> Effect<Data, Error>
  var save: (String, Data) -> Effect<Never, Error>

  func load<A: Decodable>(
    _ type: A.Type, from filename: String
  ) -> Effect<Result<A, NSError>, Never> {
    self.load(filename)
      .decode(type: A.self, decoder: JSONDecoder())
      .mapError { $0 as NSError }
      .catchToEffect()
  }

  func save<A: Encodable>(
    _ data: A, to filename: String
  ) -> Effect<Never, Never> {
    Effect.catching { try JSONEncoder().encode(data) }
      .flatMap { self.save(filename, $0) }
      .fireAndForget()
  }
}

extension FileClient {
  static let failing = Self(
    delete: { .failing("\(Self.self).delete(\($0)) is unimplemented") },
    load: { .failing("\(Self.self).load(\($0)) is unimplemented") },
    save: { file, _ in .failing("\(Self.self).save(\(file)) is unimplemented") }
  )

  static var mock: Self {
    var storage = [String: Data]()
    return Self(
      delete: { filename in
        .fireAndForget { storage[filename] = nil }
      },
      load: { filename in
        if let data = storage[filename] {
          return Effect(value: data)
        } else {
          return Effect(error: NSError(domain: "", code: NSFileReadNoSuchFileError))
        }
      },
      save: { filename, data in
        .fireAndForget { storage[filename] = data }
      }
    )
  }
}
