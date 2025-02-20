//sbt-revolver - for starting and stopping app in the background
//see: https://github.com/spray/sbt-revolver
addSbtPlugin("io.spray" % "sbt-revolver" % "0.10.0")

// scalafmt -  Format source files
addSbtPlugin("org.scalameta" % "sbt-scalafmt" % "2.5.2")

// bind .env as env vars
addSbtPlugin("nl.gn0s1s" % "sbt-dotenv" % "3.1.0")

// improving compiler rules: https://github.com/typelevel/sbt-tpolecat
// addSbtPlugin("org.typelevel" % "sbt-tpolecat" % "0.5.0")
