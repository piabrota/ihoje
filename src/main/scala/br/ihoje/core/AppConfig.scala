package br.ihoje.core

import br.ihoje.core.AppConfig.GEOCODE_API_KEY
import cats.effect.IO

import java.net.{ URL, URLDecoder }
import scala.concurrent.duration.{ Duration, FiniteDuration }
import pureconfig.module.yaml.*
import com.typesafe.config.Config
import pureconfig.ConfigReader
import pureconfig.*

import java.nio.file.{ Files, Path, Paths }
import scala.io.Source
import cats.effect.std.Env
import pureconfig.error.ConfigReaderException

case class AppConfig(
    geoConverter: GeoConverterConfig
) derives ConfigReader:

  // sensible config
  def addEnv(): IO[AppConfig] = Env[IO].get(GEOCODE_API_KEY).flatMap {
    case Some(value) => IO.pure(this.copy(geoConverter = this.geoConverter.copy(apiKey = value)))
    case None =>
      IO.raiseError(
        new RuntimeException(s"Environment variable $GEOCODE_API_KEY not found")
      ) // convert to InternalError
  }

case class GeoConverterConfig(host: String, apiKey: String, throttle: FiniteDuration) derives ConfigReader
object AppConfig:
  private val GEOCODE_API_KEY = "GEOCODE_API_KEY"
  private val RESOURCES_PATH  = "src/main/resources"
  private val APP_CONFIG_FILE = "application-conf.yaml"

  // non sensible config
  def loadConfig: IO[AppConfig] =
    IO.delay(YamlConfigSource.file(RESOURCES_PATH + "/" + APP_CONFIG_FILE).loadOrThrow[AppConfig])
