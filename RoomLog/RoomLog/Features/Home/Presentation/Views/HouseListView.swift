//
//  HouseListView.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI

struct HouseListView: View {

    // MARK: - Constants

    private enum Layout {
        static let gridSpacing: CGFloat = 16
        static let gridRowSpacing: CGFloat = 20
        static let cardRadius: CGFloat = 12
        static let cardPadding: CGFloat = 12
        static let cardGap: CGFloat = 20
        static let mainThumbnailHeight: CGFloat = 81
        static let gridThumbnailHeight: CGFloat = 65
        static let radioSize: CGFloat = 13
        static let radioRadius: CGFloat = 7
    }

    private enum Strings {
        static let title = "집 목록"
        static let editButton = "편집"
        static let doneButton = "완료"
        static let deleteButton = "삭제"
        static let mainHouseLabel = "대표집"
        static let emptyTitle = "등록된 집이 없어요"
        static let emptyBody = "홈에서 +버튼을 눌러\n집을 추가해보세요!"
        static let setMainButton = "대표집으로 설정하기"
        static let setMainSuccess = "대표집이 변경되었습니다"
        static let deleteTitle = "집 삭제"
        static let deleteMessage = "이 집을 삭제하시겠어요?\n관련된 방과 스캔 데이터도 함께 삭제됩니다."
        static let deleteConfirm = "삭제"
        static let cancel = "취소"
    }

    // MARK: - Properties

    @State private var viewModel: HouseListViewModel

    init(provider: HomeUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: HouseListViewModel(provider: provider)
        )
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Layout.gridSpacing),
        count: 3
    )

    // MARK: - Body

    var body: some View {
        content(viewModel: viewModel)
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(viewModel.isEditing)
            .task { await viewModel.fetchHouses() }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(viewModel: HouseListViewModel) -> some View {
        ZStack(alignment: .bottom) {
            if viewModel.isLoading && viewModel.houses.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.houses.isEmpty {
                emptyStateView
            } else {
                houseContent(viewModel: viewModel)
            }

            if viewModel.isEditing {
                setMainButton(viewModel: viewModel)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.isEditing {
                    Button(Strings.doneButton) {
                        withAnimation { viewModel.isEditing.toggle() }
                    }
                    .foregroundStyle(.mutedBlue)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.houses.isEmpty {
                    if viewModel.isEditing {
                        Button(Strings.deleteButton) {
                            viewModel.showDeleteConfirm = true
                        }
                        .foregroundStyle(.red)
                        .disabled(viewModel.selectedHouseId == nil)
                    } else {
                        Button(Strings.editButton) {
                            withAnimation { viewModel.isEditing.toggle() }
                        }
                        .foregroundStyle(.mutedBlue)
                    }
                }
            }
        }
        .alert(Strings.deleteTitle, isPresented: $viewModel.showDeleteConfirm) {
            Button(Strings.cancel, role: .cancel) {}
            Button(Strings.deleteConfirm, role: .destructive) {
                Task { await viewModel.deleteSelectedHouse() }
            }
        } message: {
            Text(Strings.deleteMessage)
        }
        .overlay(alignment: .top) {
            if viewModel.showSetMainSuccess {
                successToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { viewModel.showSetMainSuccess = false }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSetMainSuccess)
    }

    // MARK: - House Content

    @ViewBuilder
    private func houseContent(viewModel: HouseListViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let mainHouse = viewModel.mainHouse {
                VStack(alignment: .leading, spacing: 24) {
                    Text(Strings.mainHouseLabel)
                        .font(.semibold, 20)
                        .foregroundStyle(.neutral800)

                    mainHouseCard(house: mainHouse)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Divider()
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
            }

            ScrollView {
                let gridHouses = viewModel.houses.filter { $0.houseId != viewModel.mainHouse?.houseId }
                LazyVGrid(columns: columns, spacing: Layout.gridRowSpacing) {
                    ForEach(gridHouses) { house in
                        houseGridItem(
                            house: house,
                            isEditing: viewModel.isEditing,
                            isSelected: viewModel.selectedHouseId == house.houseId
                        ) {
                            viewModel.selectedHouseId = viewModel.selectedHouseId == house.houseId ? nil : house.houseId
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, viewModel.isEditing ? 89 : 0)
            }
        }
    }

    // MARK: - Main House Card

    @ViewBuilder
    private func mainHouseCard(house: House) -> some View {
        HStack(spacing: 16) {
            Image(.home)
                .resizable()
                .scaledToFit()
                .frame(height: Layout.mainThumbnailHeight)

            VStack(alignment: .leading, spacing: 16) {
                Text(house.name)
                    .font(.semibold, 16)
                    .foregroundStyle(.neutral800)
            }

            Spacer()
        }
    }

    // MARK: - Grid Item

    @ViewBuilder
    private func houseGridItem(
        house: House,
        isEditing: Bool,
        isSelected: Bool,
        onSelect: @escaping () -> Void
    ) -> some View {
        let isCurrent = isEditing && isSelected
        VStack(spacing: Layout.cardGap) {
            Image(.home)
                .resizable()
                .scaledToFit()
                .frame(height: Layout.gridThumbnailHeight)

            VStack(alignment: .leading, spacing: 8) {
                Text(house.name)
                    .font(.semibold, 14)
                    .foregroundStyle(.neutral800)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardRadius)
                .fill(isCurrent ? Color.cloudDancer : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardRadius)
                .stroke(
                    isCurrent ? Color.lightBeige : (isEditing ? Color.blueGray100 : Color.blueGray50),
                    lineWidth: isCurrent ? 1.2 : 1
                )
        )
        .overlay(alignment: .topTrailing) {
            if isEditing {
                radioButton(isSelected: isSelected)
                    .padding(8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                onSelect()
            }
        }
    }

    // MARK: - Radio Button

    @ViewBuilder
    private func radioButton(isSelected: Bool) -> some View {
        Circle()
            .fill(isSelected ? Color.cloudDancer : Color.white200)
            .frame(width: Layout.radioSize, height: Layout.radioSize)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.lightBeige : Color.blueGray100, lineWidth: 1.2)
            )
            .overlay {
                if isSelected {
                    Circle()
                        .fill(Color.lightBeige)
                        .frame(width: 7, height: 7)
                }
            }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(title: Strings.emptyTitle, description: Strings.emptyBody)
    }

    // MARK: - Set Main Button

    @ViewBuilder
    private func setMainButton(viewModel: HouseListViewModel) -> some View {
        BottomCTAButton {
            Task { await viewModel.setMainHouse() }
        } label: {
            Text(Strings.setMainButton)
                .font(.medium, 18)
        }
        .disabled(viewModel.selectedHouseId == nil)
    }

    // MARK: - Toast

    private var successToast: some View {
        ToastView {
            Text(Strings.setMainSuccess)
                .font(.medium, 14)
                .foregroundStyle(.neutral600)
        }
        .padding(.top, 8)
    }
}
