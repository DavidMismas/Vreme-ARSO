//
//  ArsoWidgetBundle.swift
//  ArsoWidget
//
//  Created by David Mišmaš on 20. 3. 2026.
//

import WidgetKit
import SwiftUI

@main
struct ArsoWidgetBundle: WidgetBundle {
    var body: some Widget {
        ArsoCurrentWidget()
        ArsoForecastMediumWidget()
        ArsoForecastLargeWidget()
    }
}
