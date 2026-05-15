import SwiftUI

struct RepairShopListView: View {
    @Environment(\.di) var di
    @State private var viewModel: RepairShopListViewModel

    init(roomId: Int, defect: DefectReportDetail, provider: EstimateUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: RepairShopListViewModel(roomId: roomId, defect: defect, provider: provider)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            TabView(selection: $viewModel.viewMode) {
                listContent
                    .tag(RepairShopListViewModel.ViewMode.list)
                mapContent
                    .tag(RepairShopListViewModel.ViewMode.map)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .bottom) {
            bottomButton
        }
        .navigationTitle("추천 업체 보기")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.fetchShops() }
        .overlay {
            if viewModel.showConfirmation {
                inquiryAlertOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showConfirmation)
        .sheet(isPresented: $viewModel.showSMSComposer) {
            if let shop = viewModel.selectedShop, SMSComposeView.canSendText {
                SMSComposeView(
                    recipients: [shop.phone],
                    body: viewModel.composedMessage,
                    onDismiss: { viewModel.showSMSComposer = false }
                )
                .ignoresSafeArea()
            } else {
                Text("이 기기에서는 문자를 보낼 수 없습니다.")
                    .padding()
            }
        }
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Tab Content

private extension RepairShopListView {
    var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.shops) { shop in
                    ShopCard(shop: shop, isSelected: viewModel.selectedShop?.id == shop.id)
                        .onTapGesture { viewModel.selectShop(shop) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    var mapContent: some View {
        ZStack(alignment: .bottom) {
            KakaoMapView(
                shops: viewModel.shops,
                selectedShop: viewModel.selectedShop,
                onTapShop: { viewModel.selectShop($0) }
            )
            .ignoresSafeArea(edges: .bottom)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.shops) { shop in
                        ShopMapCard(shop: shop, isSelected: viewModel.selectedShop?.id == shop.id)
                            .onTapGesture { viewModel.selectShop(shop) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Header

private extension RepairShopListView {
    var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("총 \(viewModel.shops.count)개 업체")
                    .font(.semibold, 16)
                    .foregroundStyle(Color.blueGray600)
                Text("원하는 업체를 선택해주세요")
                    .font(.medium, 14)
                    .foregroundStyle(Color.blueGray300)
            }
            Spacer()
            viewModeToggle
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    var viewModeToggle: some View {
        GlassEffectContainer {
            HStack(spacing: 0) {
                toggleButton(title: "리스트", grayImage: "recommend_list_gray", blueImage: "recommend_list_blue", mode: .list)
                toggleButton(title: "지도", grayImage: "recommend_map_gray", blueImage: "recommend_map_blue", mode: .map)
            }
            .background(Color.white200, in: Capsule())
            .overlay(
                Capsule().stroke(Color.blueGray100, lineWidth: 1)
            )
        }
        .fixedSize()
    }

    func toggleButton(title: String, grayImage: String, blueImage: String, mode: RepairShopListViewModel.ViewMode) -> some View {
        let isSelected = viewModel.viewMode == mode

        return Button {
            viewModel.viewMode = mode
        } label: {
            Group {
                if isSelected {
                    toggleButtonLabel(title: title, image: blueImage, isSelected: true)
                        .glassEffect(.regular.interactive(), in: Capsule())
                } else {
                    toggleButtonLabel(title: title, image: grayImage, isSelected: false)
                }
            }
            .overlay {
                if isSelected {
                    Capsule().stroke(Color.mutedBlue.opacity(0.5), lineWidth: 1.5)
                }
            }
        }
    }

    func toggleButtonLabel(title: String, image: String, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(title)
                .font(.semibold, 16)
                .foregroundStyle(isSelected ? Color.mutedBlue : Color.blueGray500)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Inquiry Alert
private extension RepairShopListView {
    var inquiryAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { viewModel.cancelInquiry() }

            VStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.messageTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(viewModel.messageBody)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.blueGray600)
                        .lineSpacing(4)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                .padding(.horizontal, 8)

                VStack(spacing: 10) {
                    Button {
                        Task { await viewModel.confirmSend() }
                    } label: {
                        Text(viewModel.isSubmitting ? "전송 중..." : "전송하기")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.mutedBlue, in: Capsule())
                    }
                    .disabled(viewModel.isSubmitting)

                    Button {
                        viewModel.cancelInquiry()
                    } label: {
                        Text("취소하기")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color(red: 1.0, green: 0.22, blue: 0.235))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                }
            }
            .padding(14)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 34))
            .shadow(color: .black.opacity(0.12), radius: 40, y: 8)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Bottom Button

private extension RepairShopListView {
    var bottomButton: some View {
        Button {
            viewModel.requestInquiry()
        } label: {
            Text("문자 문의하기")
                .font(.semibold, 17)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.selectedShop != nil ? Color.mutedBlue : Color.blueGray300,
                    in: Capsule()
                )
        }
        .disabled(viewModel.selectedShop == nil || viewModel.isSubmitting)
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
}

// MARK: - Shop Card

private struct ShopCard: View {
    let shop: RepairShop
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            shopImage
            shopInfo
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            isSelected ? Color.lightBeige.opacity(0.2) : Color.white
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.lightBeige : Color.blueGray50,
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mutedBlue)
                    .padding(16)
            }
        }
    }

    private var shopImage: some View {
        AsyncImage(url: URL(string: shop.imageURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Color.blueGray50
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(Color.blueGray300)
                    )
            }
        }
        .frame(width: 106, height: 113)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var shopInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(shop.name)
                .font(.semibold, 18)
                .foregroundStyle(Color.blueGray700)
                .lineLimit(1)
            Text(shop.phone)
                .font(.regular, 13)
                .foregroundStyle(Color.blueGray500)
                .lineLimit(1)
            Text(shop.address)
                .font(.medium, 13)
                .foregroundStyle(Color.blueGray600)
                .lineLimit(2)
        }
    }
}

// MARK: - Map Card

private struct ShopMapCard: View {
    let shop: RepairShop
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(shop.name)
                .font(.semibold, 20)
                .foregroundStyle(Color.blueGray700)
                .lineLimit(1)
            Text(shop.phone)
                .font(.regular, 14)
                .foregroundStyle(Color.blueGray500)
                .lineLimit(1)
            Text(shop.address)
                .font(.medium, 14)
                .foregroundStyle(Color.blueGray600)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .frame(width: 360, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 2, y: 2)
        .shadow(color: .black.opacity(0.05), radius: 4, x: -1, y: -1)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.mutedBlue.opacity(0.5), lineWidth: 1.5)
            }
        }
    }
}

#Preview("정상") {
    let di = DIContainer.configured()
    let mockDefect = DefectReportDetail(
        id: 1,
        imageURL: nil,
        type: "벽지 찢어짐",
        severity: .medium,
        description: "거실 벽면 하단부 찢어짐",
        repairCost: 15000,
        defectArea: 0.24,
        location: "거실 벽면 하단부",
        discoveredDate: nil,
        memo: nil,
        x: nil, y: nil, z: nil
    )

    NavigationStack {
        RepairShopListView(roomId: 1, defect: mockDefect, provider: di.resolve(EstimateUseCaseProvider.self))
    }
    .environment(\.di, di)
}
