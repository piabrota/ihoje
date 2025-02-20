package br.ihoje.actor

import br.ihoje.actor.HtmlWriter.{ HtmlWriterRequest, WriteToFile }
import br.ihoje.actor.WebScrapper.*
import cats.effect.{ IO, Ref }
import com.microsoft.playwright.{ BrowserType, Page, Playwright }
import com.suprnation.actor.Actor.{ Actor, Receive }
import com.suprnation.actor.ActorRef
import scala.jdk.CollectionConverters.*

import java.nio.file.Paths
import java.util.Date
import scala.concurrent.duration.*

object WebScrapper:
  // fetch from existing events until consolidation day
  sealed trait ReadMode
  case object Full                               extends ReadMode
  case class Incremental(consolidationDay: Date) extends ReadMode

  // if the bot should enable Record on failure (in success delete) ... convert it from Config
  sealed trait TrackingMode
  case object RecordErrors extends TrackingMode
  case object IgnoreErrors extends TrackingMode
  case object ReportErrors extends TrackingMode

  // WebScrapper request API
  sealed trait WebScrapperRequest
  case object ScrapeSympla extends WebScrapperRequest
  case object StopScrapper extends WebScrapperRequest

  val PLACE_SELECTOR       = "button[class^='Locationstyle__LocationButton-']"
  val PLACE_WHERE_SELECTOR = "input[placeholder='Onde?']"
  val FLN_OPTION           = "a[href^='/eventos/florianopolis']"

  val URL_SYMPLA_FLN_EVENTS =
    "https://www.sympla.com.br/eventos/florianopolis-sc/show-musica-festa/shows?ordem=month_trending_score&d=2024-12-01%2C2024-12-31&cl=17-festas-e-shows"
end WebScrapper

case class WebScrapper(
    state: Ref[IO, Option[Page]],
    writerRef: ActorRef.ActorRef[IO, HtmlWriterRequest],
    readMode: ReadMode = Full,
    trackingMode: TrackingMode = RecordErrors
) extends Actor[IO, WebScrapperRequest]:
  // add scrapper service: symple, shotgun, ingressocerto

  private def initPage: IO[Page] =
    IO.delay {
      val playwright = Playwright.create()
      val browser    = playwright.firefox.launch(new BrowserType.LaunchOptions().setHeadless(false).setSlowMo(50))
      val page       = browser.newPage()
      page.navigate(URL_SYMPLA_FLN_EVENTS)
      page
    }

  override def receive: Receive[IO, WebScrapperRequest] = {

    case StopScrapper =>
      state.get.flatMap {
        case Some(x) =>
          //            IO.println(x.content()) *>
          IO.println("Page closed.") *>
          IO.delay(x.close())
        case None =>
          IO.println("Page already closed")
      } *> IO.println("Stopping Scrapper")

    case ScrapeSympla =>
      for
        page <- initPage
        _    <- state.set(Some(page))
        // _ <- record screen
        _ <- IO.delay {
          page.screenshot(new Page.ScreenshotOptions().setPath(Paths.get("example.png")))
          val count = page.locator("a[class*='sympla-card']").count()
          println(s"=== Events page 1 === Total count $count")
          val fln = page.locator("a[class*='sympla-card']")
          fln.all().asScala.take(1).foreach { l =>
            println(l.getAttribute("data-name"))
            val location = l.getAttribute("alt")
            println(location)
            l.click()
          }

          //            initPage.waitForSelector(PLACE_SELECTOR)
          //            initPage.click(PLACE_SELECTOR)
          //            initPage.waitForSelector(PLACE_WHERE_SELECTOR)
          //            initPage.fill(PLACE_WHERE_SELECTOR, "Florianópolis")
          //            initPage.waitForSelector(FLN_OPTION)
          //            initPage.click(FLN_OPTION)
        }
        _ <- IO.sleep(1.second)
        // _ <- IO.delay(initPage.click(FLN_OPTION))
        _ <- writerRef ! WriteToFile(page.content())
        _ <- IO.sleep(10.second)
        _ <- IO.println("Hello, World!")
      yield ()
  }
