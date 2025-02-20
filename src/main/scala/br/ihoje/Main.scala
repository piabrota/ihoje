package br.ihoje

import br.ihoje.core.AppConfig
import br.ihoje.actor.{ HtmlWriter, WebScrapper }
import br.ihoje.actor.WebScrapper.{ ScrapeSympla, StopScrapper, WebScrapperRequest }
import br.ihoje.actor.HtmlWriter.{ HtmlWriterRequest, WriteToFile }
import cats.effect.{ ExitCode, IO, IOApp, Ref, Resource }
import com.suprnation.actor.ActorSystem
import com.suprnation.actor.Actor.{ Actor, Receive }
import com.suprnation.actor.ActorRef
import com.microsoft.playwright.*

import java.util.Date
import scala.concurrent.duration.*
import java.nio.file.Paths
import scala.jdk.CollectionConverters.*

object Main extends IOApp:

  override def run(args: List[String]): IO[ExitCode] =

    val actorSystemResource: Resource[IO, ActorSystem[IO]] = ActorSystem[IO]("HelloWorldSystem")

    actorSystemResource.use { system =>
      for
        cfg <- AppConfig.loadConfig.flatMap(_.addEnv())
        // _            <- IO.println(cfg)
        initialState <- Ref[IO].of(None)
        writerRef    <- system.actorOf(HtmlWriter(), "htmlWriterActor")
        scrapperRef  <- system.actorOf(WebScrapper(initialState, writerRef), "scrapperActor")
//        scrapperRef2 <- system.actorOf(WebScrapper(initialState, writerRef), "scrapperActorMulti")
        _ <- scrapperRef ! ScrapeSympla
//        _            <- scrapperRef2 ! ScrapeSympla
        _ <- IO.sleep(10.seconds)
        _ <- scrapperRef ! StopScrapper
        _ <- IO.sleep(10.seconds)
        _ <- system.terminate()
      yield ExitCode.Success
    }
end Main
