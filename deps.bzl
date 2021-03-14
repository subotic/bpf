load("@bazel_gazelle//:deps.bzl", "go_repository")

def go_dependencies():
    go_repository(
        name = "com_github_iovisor_gobpf",
        importpath = "github.com/iovisor/gobpf",
        sum = "h1:4LGPE9xTZmhI2BscCzKFDWvm8hn4NbTEvSIyKRrJUcg=",
        version = "v0.1.1",
    )
