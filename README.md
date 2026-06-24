# BikeSlo

iOS aplikacija za prikaz razpoložljivosti koles BicikeLJ in Nomago v Ljubljani.

## Funkcije

- Najbližje postaje glede na lokacijo (seznam in zemljevid)
- Iskanje med vsemi postajami
- Število razpoložljivih koles in prostih mest v živo
- Priljubljene postaje
- Filter po sistemu (BicikeLJ / Nomago)
- Kolesarska navigacija do postaje

## Podatki

Aplikacija uporablja CityBikes API (https://api.citybik.es), ki ne zahteva ključa in pokriva oba ljubljanska sistema:

- bicikelj — BicikeLJ
- nomago-ljubljana — Nomago Bikes (električna kolesa)

Razpoložljivost se osvežuje samodejno: seznam ob osvežitvi, podrobnosti postaje vsakih 30 sekund.

## Zahteve

- Xcode 26 ali novejši
- iOS 26 ali novejši

## Zagon

1. Odpri BikeSlo.xcodeproj v Xcode.
2. V Signing & Capabilities izberi svojo razvojno ekipo.
3. Zgradi in poženi (Cmd+R).

## Zgradba

- Models/ — podatkovni model (BikeStation)
- Services/ — CityBikes API in lokacija
- ViewModels/ — nalaganje in osveževanje
- Views/ — vmesnik (SwiftUI)
- Shared/ — barve in pomožne razširitve

## Opomba

To ni uradna aplikacija sistemov BicikeLJ ali Nomago.
