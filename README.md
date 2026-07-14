# ARSO Vreme

Native iOS aplikacija v SwiftUI za spremljanje vremena v Sloveniji na osnovi javnih ARSO virov za avtomatiziran dostop.

## Arhitektura

- `App/`: entrypoint, DI container, root tab struktura.
- `Core/Networking`: `URLSession` klient, endpoint abstrakcija, validacija odgovorov.
- `Core/Parsing`: robusten XML parser, RSS parser, HTML extractor za tekstovne napovedi.
- `Core/Services`: ločeni ARSO service sloji za aktualne razmere, postaje, tekstovno napoved, opozorila, radar, satelit, grafične prikaze, temperature voda, razmere v gorah in čistost zraka.
- `Core/Services/ForecastLocationProvider.swift`: abstrakcija med lokacijsko ločljivostjo prikaza in konkretnim virom napovedi.
- `Core/Services/LocationResolver.swift`: povezuje GPS ali ročni kraj z najbližjo ARSO postajo in z imenom kraja za UI.
- `Core/Services/WeatherIconProvider.swift`: mapiranje ARSO opazovanj in simbolov v lasten sistem pogojev vremena.
- `Features/`: SwiftUI zasloni in MVVM view modeli po funkcionalnih sklopih.
- `Shared/`: tema, reusable komponente, lastni vremenski simboli in preview/mock podatki.
- `Vreme ARSO Tests/`: unit testi parserjev in mock payload-i.

## Nadgradnje v tej verziji

- Osvežena je vizualna tema z globljim ozadjem, jasnejšo hierarhijo kartic, barvno ločenimi metrikami in bolj pregledno domačo hero kartico.
- Domov uporablja sodobnejši “hero” UI z veliko temperaturo, lastnim simbolom vremena, povzetkom napovedi, opozorili ter radar/satelit preview karticami.
- Aplikacija podpira trenutno GPS lokacijo, ročni vnos kraja in fallback na najbližjo ARSO postajo.
- Radar ostaja frame-based prikaz s prednalaganjem in cache-em; satelit uporablja zadnjo stabilno sliko in uradno MP4 animacijo kot fallback.
- V zavihku `Več` sta dodana `Temperature voda` in `Razmere v gorah`, oba iz stabilnih javnih ARSO HTML virov. Temperature voda vključujejo strukturirano obalno tabelo in ARSO karto rek, jezer in morja.
- V zavihku `Več` je dodana `Čistost zraka`, prenesena iz ločenega projekta `Zrak`: zemljevid merilnih postaj, PM2.5/PM10 ocena, podrobne meritve in 7-dnevni trend.
- Nova ARSO stran (`https://vreme.arso.gov.si/`) služi kot referenca za UX in lokacijsko logiko. Primarni backend ostajajo XML/HTML/slikovni viri.

## Uporabljeni endpoint-i ARSO

Stanje virov je bilo nazadnje preverjeno 14. 7. 2026. Vsi spodnji ključni viri ter lokacijski API `vreme.arso.gov.si/api/1.0` so bili dosegljivi, osnovna JSON struktura za opazovanja in dnevno napoved pa je ostala združljiva z obstoječim parserjem.

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
- Karta temperature rek, jezer in morja:
  `https://meteo.arso.gov.si/uploads/probase/www/sproduct/mountain/assets/hydro/T_vode_latest.png`
- Lokacijska napoved in trenutne razmere JSON:
  `https://vreme.arso.gov.si/api/1.0/location/?lang=sl&location={KRAJ}`
- Najbližja lokacija napovedi JSON:
  `https://vreme.arso.gov.si/api/1.0/locations/?lat={LAT}&lon={LON}`
- Nelokacijske vsebine za widget JSON:
  `https://vreme.arso.gov.si/api/1.0/nonlocation/?lang=sl`
- Čistost zraka, zadnji urni podatki XML:
  `https://www.arso.gov.si/xml/zrak/ones_zrak_urni_podatki_zadnji.xml`
- Čistost zraka, zadnji dnevni podatki XML:
  `https://www.arso.gov.si/xml/zrak/ones_zrak_dnevni_podatki_zadnji.xml`
- Čistost zraka, zadnjih 7 dni urnih podatkov XML:
  `https://www.arso.gov.si/xml/zrak/ones_zrak_urni_podatki_7dni.xml`

## Fallback logika

- Lokacija:
  GPS ali ročno izbran kraj se najprej pretvori v koordinate, nato v najbližjo ARSO postajo, če za koordinato ni potrjenega bolj granularnega javnega feeda.
- Nova ARSO stran:
  če frontend klici niso stabilni ali javno dokumentirani, aplikacija ostane na XML/HTML/slikovnih ARSO virih.
- Satelit:
  če ARSO ne ponuja stabilne serije posameznih frame-ov, aplikacija uporabi zadnjo sliko in uradno MP4 animacijo.
- Temperature voda:
  temperatura morja se bere iz stabilne obalne tabele, karta rek, jezer in morja pa iz ARSO HTML strani za pohodnike, gornike in ljubitelje morja. Parser ignorira zakomentirana HTML sporočila o nedosegljivosti in upošteva samo vidno vsebino.
- Razmere v gorah:
  podatki se berejo iz uradne HTML tabele za gore; če posamezno polje manjka, UI prikaže samo razpoložljive vrh/spodaj podatke brez padca parserja.
- Čistost zraka:
  zadnje meritve se berejo iz urnega XML vira, seznam postaj se dopolni iz dnevnega in urnega XML vira, trend pa uporablja 7-dnevni urni XML vir. Če PM2.5 manjka, UI za oceno uporabi PM10.

## Testiranje

- `XMLParserServiceTests`
- `ARSOObservationFeedMapperTests`
- `HTMLTextExtractorTests`
- `RSSParserServiceTests`
- `ARSOWarningsServiceTests`
- `ARSOWaterTemperaturesServiceTests`
- `ARSOMountainConditionsServiceTests`
- `ARSOAirQualityParserTests`

## TODO

- Še naprej spremljati stabilnost trenutno uporabljenega, vendar ločeno nedokumentiranega lokacijskega JSON API-ja `vreme.arso.gov.si/api/1.0` in ohraniti XML fallback.
- Preveriti, ali ARSO za satelit poleg `latest.mp4` ponuja tudi stabilen timeline JSON ali zaporedje frame-ov za nativni slider.
- Če ARSO objavi strukturirane tabelarične temperature rek in jezer, dodati parser tudi za ta sklop poleg trenutne kartografske slike.
- Preveriti licenčne pogoje za lokalni disk cache radarskih, satelitskih in INCA slik za App Store distribucijo.
- Po potrditvi stabilnosti virov dodati geo overlaye za MapKit na osnovi KMZ ali druge georeferencirane podlage.
- Dodati natančnejšo normalizacijo ARSO simbolov vremena v lasten simbolni sloj, če bo potrebna strožja vizualna konsistenca.
