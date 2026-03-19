# ARSO Vreme

Native iOS aplikacija v SwiftUI za spremljanje vremena v Sloveniji na osnovi javnih ARSO virov za avtomatiziran dostop.

## Arhitektura

- `App/`: entrypoint, DI container, root tab struktura.
- `Core/Networking`: `URLSession` klient, endpoint abstrakcija, validacija odgovorov.
- `Core/Parsing`: robusten XML parser, RSS parser, HTML extractor za tekstovne napovedi.
- `Core/Services`: ločeni ARSO service sloji za aktualne razmere, postaje, tekstovno napoved, opozorila, radar, satelit in grafične prikaze.
- `Features/`: SwiftUI zasloni in MVVM view modeli po funkcionalnih sklopih.
- `Shared/`: tema, reusable komponente in preview/mock podatki.
- `Vreme ARSO Tests/`: unit testi parserjev in mock payload-i.

## Uporabljeni endpoint-i ARSO

- Opazovanja vseh postaj XML:
  `https://meteo.arso.gov.si/uploads/probase/www/observ/surface/text/sl/observation_si_latest.xml`
- Tekstovna napoved, celo besedilo:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/fcast_si_text.html`
- Napoved za Slovenijo:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/fcast_SLOVENIA_d1-d2_text.html`
- Obeti:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/fcast_SLOVENIA_d3-d5_text.html`
- 5 do 10 dni:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/fcast_SLOVENIA_d5-d10_text.html`
- Sosednje pokrajine:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/fcast_SI_NEIGHBOURS_d1-d2_text.html`
- Vremenska slika:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/fcast_EUROPE_d1_text.html`
- Tekstovno opozorilo:
  `https://meteo.arso.gov.si/uploads/probase/www/warning/text/sl/warning_SLOVENIA_text.html`
- CAP opozorila po regijah:
  `https://meteo.arso.gov.si/uploads/probase/www/warning/text/sl/warning_{REGIJA}_latest_CAP.xml`
- Radar timeline JSON:
  `https://meteo.arso.gov.si/uploads/probase/www/nowcast/inca/inca_si0zm_data.json`
- Grafične timeline JSON datoteke:
  `https://meteo.arso.gov.si/uploads/probase/www/nowcast/inca/inca_t2m_data.json`
  `https://meteo.arso.gov.si/uploads/probase/www/nowcast/inca/inca_wind_data.json`
  `https://meteo.arso.gov.si/uploads/probase/www/nowcast/inca/inca_sp_data.json`
  `https://meteo.arso.gov.si/uploads/probase/www/nowcast/inca/inca_tp_data.json`
  `https://meteo.arso.gov.si/uploads/probase/www/nowcast/inca/inca_si0zm_data.json`
  `https://meteo.arso.gov.si/uploads/probase/www/nowcast/inca/inca_hp_data.json`
- Satelitska zadnja slika:
  `https://meteo.arso.gov.si/uploads/probase/www/observ/satellite/mtg_geocolor_si-neighbours_latest.jpg`
- Satelitska uradna animacija:
  `https://meteo.arso.gov.si/uploads/probase/www/observ/satellite/mtg_geocolor_si-neighbours_latest.mp4`

## Testiranje

- `XMLParserServiceTests`
- `ARSOObservationFeedMapperTests`
- `HTMLTextExtractorTests`
- `RSSParserServiceTests`
- `ARSOWarningsServiceTests`

## TODO

- Preveriti, ali ARSO za satelit poleg `latest.mp4` ponuja tudi stabilen timeline JSON ali zaporedje frame-ov za nativni slider.
- Preveriti licenčne pogoje za lokalni disk cache radarskih, satelitskih in INCA slik za App Store distribucijo.
- Po potrditvi stabilnosti virov dodati geo overlaye za MapKit na osnovi KMZ ali druge georeferencirane podlage.
- Dodati natančnejšo normalizacijo ARSO simbolov vremena v lasten simbolni sloj, če bo potrebna strožja vizualna konsistenca.
