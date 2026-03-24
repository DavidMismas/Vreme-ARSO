import SwiftUI

struct TimelineLegend {
    let title: String
    let footnote: String?
    let items: [TimelineLegendItem]

    static let radarReflectivity = TimelineLegend(
        title: "Moč padavin",
        footnote: "Barve kažejo, kako močne so padavine na radarju.",
        items: [
            TimelineLegendItem(label: "Šibko", color: Color(red: 0.13, green: 0.38, blue: 0.94)),
            TimelineLegendItem(label: "Zmerno", color: Color(red: 0.10, green: 0.76, blue: 0.33)),
            TimelineLegendItem(label: "Močno", color: Color(red: 0.95, green: 0.85, blue: 0.12)),
            TimelineLegendItem(label: "Zelo močno", color: Color(red: 0.95, green: 0.52, blue: 0.13)),
            TimelineLegendItem(label: "Ekstremno", color: Color(red: 0.83, green: 0.15, blue: 0.23))
        ]
    )
}

struct TimelineLegendItem: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}

extension Endpoint.GraphicKind {
    var timelineLegend: TimelineLegend {
        switch self {
        case .temperatura:
            return TimelineLegend(
                title: "Temperatura",
                footnote: "Barve kažejo približno temperaturo zraka.",
                items: [
                    TimelineLegendItem(label: "< 0 °C", color: Color(red: 0.08, green: 0.34, blue: 0.83)),
                    TimelineLegendItem(label: "0–5 °C", color: Color(red: 0.16, green: 0.71, blue: 0.91)),
                    TimelineLegendItem(label: "5–10 °C", color: Color(red: 0.17, green: 0.73, blue: 0.37)),
                    TimelineLegendItem(label: "10–20 °C", color: Color(red: 0.94, green: 0.86, blue: 0.24)),
                    TimelineLegendItem(label: "20–30 °C", color: Color(red: 0.97, green: 0.58, blue: 0.17)),
                    TimelineLegendItem(label: "> 30 °C", color: Color(red: 0.84, green: 0.22, blue: 0.18))
                ]
            )
        case .veter:
            return TimelineLegend(
                title: "Veter",
                footnote: "Barve kažejo hitrost vetra.",
                items: [
                    TimelineLegendItem(label: "0–2 m/s", color: Color(red: 0.11, green: 0.16, blue: 0.18)),
                    TimelineLegendItem(label: "2–5 m/s", color: Color(red: 0.00, green: 0.47, blue: 0.35)),
                    TimelineLegendItem(label: "5–10 m/s", color: Color(red: 0.21, green: 0.76, blue: 0.60)),
                    TimelineLegendItem(label: "10–15 m/s", color: Color(red: 0.62, green: 0.50, blue: 0.87)),
                    TimelineLegendItem(label: "15–20 m/s", color: Color(red: 0.86, green: 0.38, blue: 0.84)),
                    TimelineLegendItem(label: "> 20 m/s", color: Color(red: 0.95, green: 0.19, blue: 0.57))
                ]
            )
        case .oblacnost:
            return TimelineLegend(
                title: "Oblačnost",
                footnote: "Barve kažejo, koliko neba prekrivajo oblaki.",
                items: [
                    TimelineLegendItem(label: "0–20 %", color: Color(red: 0.96, green: 0.97, blue: 0.99)),
                    TimelineLegendItem(label: "20–40 %", color: Color(red: 0.82, green: 0.85, blue: 0.89)),
                    TimelineLegendItem(label: "40–60 %", color: Color(red: 0.63, green: 0.67, blue: 0.73)),
                    TimelineLegendItem(label: "60–80 %", color: Color(red: 0.40, green: 0.44, blue: 0.51)),
                    TimelineLegendItem(label: "80–100 %", color: Color(red: 0.18, green: 0.21, blue: 0.27))
                ]
            )
        case .padavine:
            return TimelineLegend(
                title: "Padavine",
                footnote: "Barve kažejo količino padavin.",
                items: [
                    TimelineLegendItem(label: "< 1 mm", color: Color(red: 0.74, green: 0.87, blue: 0.98)),
                    TimelineLegendItem(label: "1–5 mm", color: Color(red: 0.23, green: 0.55, blue: 0.96)),
                    TimelineLegendItem(label: "5–10 mm", color: Color(red: 0.10, green: 0.75, blue: 0.36)),
                    TimelineLegendItem(label: "10–20 mm", color: Color(red: 0.95, green: 0.84, blue: 0.12)),
                    TimelineLegendItem(label: "20–40 mm", color: Color(red: 0.96, green: 0.48, blue: 0.14)),
                    TimelineLegendItem(label: "> 40 mm", color: Color(red: 0.84, green: 0.17, blue: 0.22))
                ]
            )
        case .radar:
            return .radarReflectivity
        case .toca:
            return TimelineLegend(
                title: "Možnost toče",
                footnote: "Barve kažejo verjetnost toče.",
                items: [
                    TimelineLegendItem(label: "0–20 %", color: Color(red: 0.58, green: 0.78, blue: 0.98)),
                    TimelineLegendItem(label: "20–40 %", color: Color(red: 0.18, green: 0.71, blue: 0.45)),
                    TimelineLegendItem(label: "40–60 %", color: Color(red: 0.94, green: 0.81, blue: 0.15)),
                    TimelineLegendItem(label: "60–80 %", color: Color(red: 0.95, green: 0.51, blue: 0.13)),
                    TimelineLegendItem(label: "80–100 %", color: Color(red: 0.82, green: 0.18, blue: 0.23))
                ]
            )
        }
    }
}
