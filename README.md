# ARSO Vreme

Native iOS aplikacija v SwiftUI za spremljanje vremena v Sloveniji na osnovi javnih ARSO virov za avtomatiziran dostop.

## Arhitektura

- `App/`: entrypoint, DI container, root tab struktura.
- `Core/Networking`: `URLSession` klient, endpoint abstrakcija, validacija odgovorov.
- `Core/Parsing`: robusten XML parser, RSS parser, HTML extractor za tekstovne napovedi.
- `Core/Services`: ločeni ARSO service sloji za aktualne razmere, postaje, tekstovno napoved, opozorila, radar, satelit, grafične prikaze, temperature voda in razmere v gorah.
- `Core/Services/ForecastLocationProvider.swift`: abstrakcija med lokacijsko ločljivostjo prikaza in konkretnim virom napovedi.
- `Core/Services/LocationResolver.swift`: povezuje GPS ali ročni kraj z najbližjo ARSO postajo in z imenom kraja za UI.
- `Core/Services/WeatherIconProvider.swift`: mapiranje ARSO opazovanj in simbolov v lasten sistem pogojev vremena.
- `Features/`: SwiftUI zasloni in MVVM view modeli po funkcionalnih sklopih.
- `Shared/`: tema, reusable komponente, lastni vremenski simboli in preview/mock podatki.
- `Vreme ARSO Tests/`: unit testi parserjev in mock payload-i.

## Nadgradnje v tej verziji

- Domov uporablja sodobnejši “hero” UI z veliko temperaturo, lastnim simbolom vremena, povzetkom napovedi, opozorili ter radar/satelit preview karticami.
- Aplikacija podpira trenutno GPS lokacijo, ročni vnos kraja in fallback na najbližjo ARSO postajo.
- Radar ostaja frame-based prikaz s prednalaganjem in cache-em; satelit uporablja zadnjo stabilno sliko in uradno MP4 animacijo kot fallback.
- V zavihku `Več` sta dodana `Temperature voda` in `Razmere v gorah`, oba iz stabilnih javnih ARSO HTML virov.
- Nova ARSO stran (`https://vreme.arso.gov.si/`) služi kot referenca za UX in lokacijsko logiko. Primarni backend ostajajo XML/HTML/slikovni viri.

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
- Napoved za morje:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/fcast_si-coast_latest.html`
- Napoved za gore:
  `https://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/forecast_si-mountain_latest.html`
- Povzetek za pohodnike, gornike in ljubitelje morja:
  `https://meteo.arso.gov.si/uploads/probase/www/sproduct/mountain/`

## Fallback logika

- Lokacija:
  GPS ali ročno izbran kraj se najprej pretvori v koordinate, nato v najbližjo ARSO postajo, če za koordinato ni potrjenega bolj granularnega javnega feeda.
- Nova ARSO stran:
  če frontend klici niso stabilni ali javno dokumentirani, aplikacija ostane na XML/HTML/slikovnih ARSO virih.
- Satelit:
  če ARSO ne ponuja stabilne serije posameznih frame-ov, aplikacija uporabi zadnjo sliko in uradno MP4 animacijo.
- Temperature voda:
  temperatura morja se bere iz stabilne obalne tabele, za reke in jezera pa aplikacija prikaže statusno sporočilo, če ARSO objavi, da so podatki začasno nedosegljivi.
- Razmere v gorah:
  podatki se berejo iz uradne HTML tabele za gore; če posamezno polje manjka, UI prikaže samo razpoložljive vrh/spodaj podatke brez padca parserja.

## Testiranje

- `XMLParserServiceTests`
- `ARSOObservationFeedMapperTests`
- `HTMLTextExtractorTests`
- `RSSParserServiceTests`
- `ARSOWarningsServiceTests`
- `ARSOWaterTemperaturesServiceTests`
- `ARSOMountainConditionsServiceTests`

## TODO

- Preveriti, ali nova ARSO stran uporablja dovolj stabilen in javen koordinatni forecast endpoint za pravi `coordinate-based` provider brez vezave na frontend bundle.
- Preveriti, ali ARSO za satelit poleg `latest.mp4` ponuja tudi stabilen timeline JSON ali zaporedje frame-ov za nativni slider.
- Če ARSO ponovno objavi ločene temperature rek in jezer, dodati strukturiran parser tudi za ta sklop namesto statusnega fallbacka.
- Preveriti licenčne pogoje za lokalni disk cache radarskih, satelitskih in INCA slik za App Store distribucijo.
- Po potrditvi stabilnosti virov dodati geo overlaye za MapKit na osnovi KMZ ali druge georeferencirane podlage.
- Dodati natančnejšo normalizacijo ARSO simbolov vremena v lasten simbolni sloj, če bo potrebna strožja vizualna konsistenca.
