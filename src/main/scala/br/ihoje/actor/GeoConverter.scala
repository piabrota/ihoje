package br.ihoje.actor

import br.ihoje.actor.GeoConverter.{ ConvertAddressToLatLong, GeoConverterRequest, GeoConverterResponse, GeocodedEvent }
import cats.effect.IO
import com.suprnation.actor.Actor.ReplyingReceive
import com.suprnation.actor.ReplyingActor

object GeoConverter:
  // requests
  sealed trait GeoConverterRequest
  case class ConvertAddressToLatLong(address: String) extends GeoConverterRequest
  // responses
  sealed trait GeoConverterResponse
  case class GeocodedEvent(lat: Double, long: Double, metadata: String) extends GeoConverterResponse
end GeoConverter

case class GeoConverter() extends ReplyingActor[IO, GeoConverterRequest, GeoConverterResponse]:
  override def receive: ReplyingReceive[IO, GeoConverterRequest, GeoConverterResponse] = {
    case ConvertAddressToLatLong(address) =>
      IO.println(s"Hello, World! $address").as(GeocodedEvent(1, 1, "potato"))
  }

end GeoConverter
