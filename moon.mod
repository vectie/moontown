name = "vectie/moontown"

version = "0.1.7"

import {
  "moonbitlang/async@0.16.6",
  "moonbitlang/x@0.4.40",
  "vectie/lepusa@0.1.4",
  "vectie/moonlib@0.1.19",
}

readme = "README.mbt.md"

repository = "https://github.com/vectie/moontown"

license = "Apache-2.0"

keywords = [ ]

description = ""

preferred_target = "native"

source = "src"

// Runtime art and generated Rabbita output ship with the application release,
// not the reusable MoonBit source package published to Mooncakes.

options(
  exclude: [
    "src/ui/assets",
    "src/ui/rabbita-town/_build",
    "src/ui/rabbita-town/dist",
    "src/ui/rabbita-town/node_modules",
  ],
)
