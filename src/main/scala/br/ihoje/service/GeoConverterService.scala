package br.ihoje.service

import br.ihoje.core.GeoConverterConfig
import cats.effect.{IO, MonadCancelThrow, Resource}
import cats.syntax.flatMap.*
import cats.syntax.functor.*
import io.circe.Decoder
import io.circe.generic.semiauto.deriveDecoder
import sttp.client4.circe.asJson
import sttp.client4.{UriContext, basicRequest}
import sttp.client4.httpclient.cats.HttpClientCatsBackend

case class GeocodeRequest(address: String)

case class MapboxConversionResponse(`type`: String, features: List[MapboxFeatures]):
  def toModel[F[_]](using F: MonadCancelThrow[F]): F[ConversionModel] =
    this.features match
      case head :: _ =>
        head.geometry.coordinates match
          case coordinates if coordinates.length == 2 =>
            F.pure(ConversionModel(coordinates.head, coordinates.last))
          case _ =>
            F.raiseError(new RuntimeException("Invalid number of coordinates"))
      case Nil =>
        F.raiseError(new RuntimeException("Empty features"))

case class ConversionModel(lat: Double, long: Double)
case class MapboxFeatures(`type`: String, id: String, geometry: MapboxGeometry)
case class MapboxGeometry(`type`: String, coordinates: List[Double])

trait GeocodeClient[F[_]]:
  def convert(geoRequest: GeocodeRequest): F[ConversionModel]

object GeocodeClient:
  private val GEOCODE_V6 = "search/geocode/v6/forward"
  private val COUNTRY = "br"

  given Decoder[MapboxConversionResponse] = deriveDecoder[MapboxConversionResponse]
  given Decoder[MapboxFeatures] = deriveDecoder[MapboxFeatures]
  given Decoder[MapboxGeometry] = deriveDecoder[MapboxGeometry]

  def make[F[_]](cfg: GeoConverterConfig, backend: HttpClientCatsBackend[F])
                (using F: MonadCancelThrow[F]): GeocodeClient[F] = new GeocodeClient[F]:
    override def convert(geoRequest: GeocodeRequest): F[ConversionModel] =
      val request = basicRequest
        .get(uri"https://${cfg.host}/$GEOCODE_V6?q=${geoRequest.address}&country=$COUNTRY&access_token=${cfg.apiKey}")
        .response(asJson[MapboxConversionResponse])

      request
        .send(backend)
        .flatMap { response =>
          (response.body, response.statusText) match
            case (Right(mapboxResponse), "200") => mapboxResponse.toModel[F]
            case(Right(_), nonSucceededCode) => F.raiseError(new RuntimeException(s"Non 200 response: $nonSucceededCode"))
            case (Left(error), _)  => F.raiseError(new RuntimeException(s"Failed to decode response: $error"))
        }
