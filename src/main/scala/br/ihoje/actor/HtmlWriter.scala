package br.ihoje.actor

import br.ihoje.actor.HtmlWriter.{ HtmlWriterRequest, WriteToFile }
import cats.effect.IO
import com.suprnation.actor.Actor.{ Actor, Receive }

import java.nio.file.{ Files, Path, Paths, StandardOpenOption }
import scala.util.{ Failure, Success, Try }

object HtmlWriter:
  sealed trait HtmlWriterRequest
  case class WriteToFile(contentHTML: String) extends HtmlWriterRequest
end HtmlWriter

case class HtmlWriter() extends Actor[IO, HtmlWriterRequest]:

  private def initOutputFIle(outputPath: String): Path =
    val outputDirectory = Paths.get(outputPath)
    val outputFilePath  = outputDirectory.resolve(f"debug-pg-${System.currentTimeMillis()}.html")
    Try(Files.createDirectories(outputDirectory)) match
      case Failure(exception) => println(f"Error initializing output directory: $exception")
      case Success(_)         => Files.writeString(outputFilePath, "<!-- DEBUG HTML -->\n", StandardOpenOption.CREATE)
    outputFilePath

  override def receive: Receive[IO, HtmlWriterRequest] = {

    case WriteToFile(pageResult) =>
      val outputFilePath = initOutputFIle("output")
      Try(
        Files.writeString(
          outputFilePath,
          pageResult,
          StandardOpenOption.CREATE,
          StandardOpenOption.APPEND
        )
      ) match
        case Failure(exception) => IO.println(f"error writing to file ${exception.getMessage}")
        case Success(_)         => IO.pure(())

  }
