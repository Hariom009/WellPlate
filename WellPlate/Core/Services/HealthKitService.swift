//
//  HealthKitService.swift
//  WellPlate
//
//  Created by Hari's Mac on 20.02.2026.
//

import HealthKit

// MARK: - Error Type

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:     return "HealthKit is not available on this device."
        case .typeNotAvailable: return "This health data type is not supported."
        }
    }
}

// MARK: - Concrete Service

final class HealthKitService: HealthKitServiceProtocol {

    /// Call this before constructing the service to guard against Simulator.
    static let isAvailable: Bool = HKHealthStore.isHealthDataAvailable()

    private let store = HKHealthStore()
    private(set) var isAuthorized = false

    // MARK: - Types

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let quantityIDs: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .heartRate, .dietaryWater
        ]
        quantityIDs.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
                   .forEach { types.insert($0) }

        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    self?.isAuthorized = success
                    cont.resume()
                }
            }
        }
    }

    // MARK: - Public Fetch Methods

    func fetchSteps(for range: DateInterval) async throws -> [DailyMetricSample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }
        return try await fetchDailySum(type: type, unit: .count(), range: range)
    }

    func fetchHeartRate(for range: DateInterval) async throws -> [DailyMetricSample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeNotAvailable
        }
        return try await fetchDailyAvg(type: type, unit: HKUnit(from: "count/min"), range: range)
    }

    func fetchActiveEnergy(for range: DateInterval) async throws -> [DailyMetricSample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.typeNotAvailable
        }
        return try await fetchDailySum(type: type, unit: .kilocalorie(), range: range)
    }

    func fetchWater(for range: DateInterval) async throws -> [DailyMetricSample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.typeNotAvailable
        }
        return try await fetchDailySum(type: type, unit: .liter(), range: range)
    }

    func fetchSleep(for range: DateInterval) async throws -> [SleepSample] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }
        return try await withCheckedThrowingContinuation { cont in
            let predicate = HKQuery.predicateForSamples(
                withStart: range.start, end: range.end, options: .strictStartDate
            )
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                ]
                let result = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .map { s -> SleepSample in
                        let hours = s.endDate.timeIntervalSince(s.startDate) / 3600
                        return SleepSample(date: s.startDate, value: hours)
                    }
                cont.resume(returning: result)
            }
            store.execute(query)
        }
    }

    // MARK: - Private Helpers

    private func fetchDailySum(
        type: HKQuantityType,
        unit: HKUnit,
        range: DateInterval
    ) async throws -> [DailyMetricSample] {
        return try await fetchCollection(type: type, unit: unit, options: .cumulativeSum, range: range) { stat in
            stat.sumQuantity()?.doubleValue(for: unit) ?? 0
        }
    }

    private func fetchDailyAvg(
        type: HKQuantityType,
        unit: HKUnit,
        range: DateInterval
    ) async throws -> [DailyMetricSample] {
        return try await fetchCollection(type: type, unit: unit, options: .discreteAverage, range: range) { stat in
            stat.averageQuantity()?.doubleValue(for: unit) ?? 0
        }
    }

    private func fetchCollection(
        type: HKQuantityType,
        unit: HKUnit,
        options: HKStatisticsOptions,
        range: DateInterval,
        valueExtractor: @escaping (HKStatistics) -> Double
    ) async throws -> [DailyMetricSample] {
        return try await withCheckedThrowingContinuation { cont in
            var interval = DateComponents()
            interval.day = 1

            let predicate = HKQuery.predicateForSamples(
                withStart: range.start, end: range.end, options: .strictStartDate
            )
            let anchor = Calendar.current.startOfDay(for: range.start)

            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchor,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, error in
                if let error = error { cont.resume(throwing: error); return }
                var samples: [DailyMetricSample] = []
                results?.enumerateStatistics(from: range.start, to: range.end) { stat, _ in
                    samples.append(DailyMetricSample(date: stat.startDate, value: valueExtractor(stat)))
                }
                cont.resume(returning: samples)
            }
            store.execute(query)
        }
    }
}
