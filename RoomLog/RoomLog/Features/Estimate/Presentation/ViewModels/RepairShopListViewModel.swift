//
//  RepariShopListViewModel.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

@Observable
final class RepairShopListViewModel {
    enum ViewMode {
        case list, map
    }

    // MARK: - State
    private(set) var shops: [RepairShop] = []
    private(set) var isLoading = false
    private(set) var isSubmitting = false
    private(set) var analysisId: Int?
    var selectedShop: RepairShop?
    var viewMode: ViewMode = .list
    var errorMessage: String?

    var showConfirmation = false
    var showSMSComposer = false
    private(set) var composedMessage = ""
    private(set) var preview: EstimatePreview?
    private(set) var isLoadingPreview = false

    // MARK: - Context
    let roomId: Int
    let defect: DefectReportDetail

    // MARK: - Provider
    private let provider: EstimateUseCaseProvider

    init(roomId: Int, defect: DefectReportDetail, provider: EstimateUseCaseProvider) {
        self.roomId = roomId
        self.defect = defect
        self.provider = provider
    }

    // MARK: - Derived

    var messageTitle: String { defect.type.displayName }

    var messageBody: String {
        let cost = Self.costFormatter.string(from: NSNumber(value: defect.repairCost)) ?? "\(defect.repairCost)"
        let area = String(format: "%.2f", defect.defectArea)
        return "\(defect.location) \(defect.type.displayName) (\(area)m²) 으로 인해 예상 비용인 \(cost)원 정도로 수리가 가능할지 문의 남깁니다."
    }

    private static let costFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    // MARK: - Actions

    func fetchShops() async {
        isLoading = true
        defer { isLoading = false }
        print("[Estimate] fetchShops start — roomId=\(roomId)")
        do {
            let result = try await provider.makeGetRepairShopsByRoomUseCase().execute(roomId: roomId)
            shops = result.shops
            analysisId = result.analysisId
            print("[Estimate] fetchShops OK — count=\(result.shops.count), analysisId=\(String(describing: result.analysisId))")
        } catch {
            errorMessage = error.localizedDescription
            print("[Estimate] fetchShops FAIL — \(error)")
        }
    }

    func selectShop(_ shop: RepairShop) {
        selectedShop = selectedShop?.id == shop.id ? nil : shop
    }

    func requestInquiry() async {
        guard let shop = selectedShop else { return }
        guard let analysisId else {
            errorMessage = "분석 정보가 없어 문의 미리보기를 생성할 수 없습니다."
            return
        }
        isLoadingPreview = true
        defer { isLoadingPreview = false }
        do {
            let message = "\(messageTitle)\n\n\(messageBody)"
            let result = try await provider.makePreviewEstimateUseCase().execute(
                message: message,
                analysisId: analysisId,
                providerExternalId: shop.externalId
            )
            preview = result
            composedMessage = result.messagePreview
            showConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmSend() async {
        guard let shop = selectedShop else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await provider.makeCreateEstimateUseCase().execute(
                message: composedMessage,
                roomId: roomId,
                analysisId: analysisId,
                defectIds: [defect.id],
                provider: shop
            )
            showConfirmation = false
            showSMSComposer = true
        } catch {
            errorMessage = error.localizedDescription
            showConfirmation = false
        }
    }

    func cancelInquiry() {
        showConfirmation = false
    }
}
