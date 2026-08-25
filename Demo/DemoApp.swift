//
//  DemoApp.swift
//  DisplayClassPlanner Demo
//
//  The app owns the *product decisions* — which surfaces exist, how big a
//  content cell is, how aggressive the hysteresis should be — and hands them to
//  the library. That is why this file imports `DisplayClassPlanner` directly
//  and not only `DisplayClassPlannerUI`: the configuration below is built out
//  of the core module's own types (`Viewport`, `AreaProportionalBudgetPolicy`,
//  `TransitionDebouncer.Policy`, `WorkItem`), which is exactly the boundary the
//  package is arguing for. Numbers like these belong to the app; the planning
//  algorithm belongs to the library.
//

import SwiftUI
import DisplayClassPlanner
import DisplayClassPlannerUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            CapacityPlannerView(configuration: .demo)
        }
    }
}

extension PlannerDemoConfiguration {

    /// The compiled-in configuration this demo ships with.
    static let demo = PlannerDemoConfiguration(
        stages: [
            .init(
                id: "cover",
                title: "Cover",
                viewport: Viewport(width: 420, height: 900, columnCount: 1, scale: 3)
            ),
            .init(
                id: "inner",
                title: "Inner",
                viewport: Viewport(width: 760, height: 820, columnCount: 2, scale: 3)
            ),
            .init(
                id: "external",
                title: "External",
                viewport: Viewport(width: 1180, height: 900, columnCount: 3, scale: 2)
            ),
        ],
        // A photo-grid-shaped surface: 120x120pt cells, two screenfuls admitted,
        // three screenfuls of decoded pixels allowed resident.
        budgetPolicy: AreaProportionalBudgetPolicy(
            averageCellArea: 14_400,
            prefetchMultiplier: 2,
            itemsPerConcurrencySlot: 4,
            residentScreenfuls: 3,
            bytesPerPixel: 4
        ),
        // Expansion is instant; contraction waits 400 ms so a fold-unfold-fold
        // storm settles without cancelling anything.
        debouncePolicy: TransitionDebouncer.Policy(
            expansionHoldNanos: 0,
            contractionHoldNanos: 400_000_000
        ),
        catalog: PlannerDemoConfiguration.syntheticCatalog(
            count: 48,
            cellArea: 14_400,
            bytesPerCell: 900_000
        )
    )
}
