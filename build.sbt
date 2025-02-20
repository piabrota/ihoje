// *****************************************************************************
// Build settings
// *****************************************************************************

inThisBuild(
  Seq(
    organization := "br.ihoje",
    startYear    := Some(2024),
    licenses += ("Apache-2.0", url("http://www.apache.org/licenses/LICENSE-2.0")),
    scalaVersion := "3.5.2",
    resolvers ++= Seq("jitpack" at "https://jitpack.io"), //"mapbox" at "https://api.mapbox.com/downloads/v2/releases/maven"),
//    credentials += Credentials("Mapbox","api.mapbox.com", "mapbox", sys.env.get("MAPBOX_ACCESS_TOKEN").orNull),

    //    semanticdbEnabled := true,
//    semanticdbVersion := scalafixSemanticdb.revision,
//    scalafixDependencies += library.scalafix,
//    scalacOptions ++= Seq(
//      "-deprecation",
//      "-unchecked",
//      "-Xfatal-warnings",
//      "-Ywarn-unused"
//    ),
    scalafmtOnCompile := true
  )
)

// *****************************************************************************
// Projects
// *****************************************************************************

lazy val ihoje =
  project
    .in(file("."))
    .settings(commonSettings)
    .settings(
      libraryDependencies ++= Seq(
        library.akka,
        library.akkaLogging,
        library.logBack,
        library.jSoup,
        library.catsActors,
        library.playwright,
        library.pureConfig,
        library.pureConfigYAML,
        library.sttp,
        library.sttpCats,
        library.sttpCirce,
        library.circeGeneric,
        library.decline,
        library.declineEff,
        library.sCaffeine   % Compile,
        library.akkaTestKit % Test,
        library.scalaTest   % Test,
      ),
      Compile / run / mainClass := Some("br.ihoje.Main")
    )

// *****************************************************************************
// Project settings
// *****************************************************************************

lazy val commonSettings =
  Seq(
    // Also (automatically) format build definition together with sources
    Compile / scalafmt := {
      val _ = (Compile / scalafmtSbt).value
      (Compile / scalafmt).value
    }
  )

// Run in a separate JVM, to make sure sbt waits until all threads have
// finished before returning.
fork := true

// *****************************************************************************
// Library dependencies
// *****************************************************************************

lazy val library =
  new {
    object Version {
      val CatsActorsVersion = "2.0.0"
      val AkkaVersion       = "2.6.20"
      val ScalaTestVersion  = "3.2.19"
      val ScalafixVersion   = "0.6.0"
      val LogbackVersion    = "1.5.12"
      val JSoupVersion      = "1.18.1"
      val SCaffeineVersion  = "5.3.0"
      val KamonVersion      = "2.7.5"
    }
    val akka        = "com.typesafe.akka"  %% "akka-actor-typed"         % Version.AkkaVersion
    val akkaTestKit = "com.typesafe.akka"  %% "akka-actor-testkit-typed" % Version.AkkaVersion
    val scalaTest   = "org.scalatest"      %% "scalatest"                % Version.ScalaTestVersion
    val akkaLogging = "com.typesafe.akka"  %% "akka-slf4j"               % Version.AkkaVersion
    val logBack     = "ch.qos.logback"      % "logback-classic"          % Version.LogbackVersion
    val jSoup       = "org.jsoup"           % "jsoup"                    % Version.JSoupVersion
    val sCaffeine   = "com.github.blemale" %% "scaffeine"                % Version.SCaffeineVersion

    val scalafix = "com.github.liancheng" %% "organize-imports" % Version.ScalafixVersion

    val catsActors = "com.github.suprnation.cats-actors" %% "cats-actors" % Version.CatsActorsVersion

    val playwright = "com.microsoft.playwright" % "playwright" % "1.49.0"

    val pureConfig     = "com.github.pureconfig" %% "pureconfig-core" % "0.17.8"
    val pureConfigYAML = "com.github.pureconfig" %% "pureconfig-yaml" % "0.17.8"

    val sttp         = "com.softwaremill.sttp.client4" %% "core"          % "4.0.0-M19"
    val sttpCats     = "com.softwaremill.sttp.client4" %% "circe"         % "4.0.0-M19"
    val sttpCirce    = "com.softwaremill.sttp.client4" %% "cats"          % "4.0.0-M19"
    val circeGeneric = "io.circe"                      %% "circe-generic" % "0.14.10"


    val decline    = "com.monovore" %% "decline" % "2.4.1"
    val declineEff = "com.monovore" %% "decline-effect" % "2.4.1"

//    val mapboxGeoJson  = "com.mapbox.mapboxsdk" % "mapbox-sdk-geojson"  % "7.3.1"
//    val mapboxServices = "com.mapbox.mapboxsdk" % "mapbox-sdk-services" % "7.3.1"
  }

addCommandAlias(
  "styleCheck",
  "; scalafmtCheckAll; scalafmtSbtCheck ; scalafixAll --check"
)
