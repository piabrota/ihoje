package br.ihoje.cli

import com.monovore.decline.*
import com.monovore.decline.effect.*

object GeocodeEntrypoint extends CommandIOApp(name= "geocode", header = "Address + Viz"):
  case class GeocodeRawInput(address: String)

  def parseArgs(args: List[String]): Either[String, GeocodeRawInput] =
    args match {
      case x =>  Right(GeocodeRawInput(x.head))
    }
