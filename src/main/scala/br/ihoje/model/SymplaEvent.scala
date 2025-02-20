package br.ihoje.model
//record screen on failure
case class SymplaEvent(
    eventDescription: String,
    eventId: String,
    url: String,
    image: Array[Byte],
    fullLocation: String,
    city: String
)

case class EventRow(
    id: String,
    eventDescription: String,
    externalId: String,
    url: String,
    image: Array[Byte],
    fullLocation: String,
    city: String,
    latitude: Double,
    longitude: Double
)
