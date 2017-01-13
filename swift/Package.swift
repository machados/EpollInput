import PackageDescription

let package = Package(
  name: "EpollInputInSwift",
  dependencies: [
    .Package(url: "git@github.com:machados/GlibcExtras.git", majorVersion: 0)
  ]
)
