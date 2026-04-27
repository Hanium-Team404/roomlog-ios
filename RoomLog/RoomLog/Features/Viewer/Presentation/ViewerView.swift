//
//  Untitled.swift
//  
//
//  Created by 송민교 on 4/20/26.
//
import SwiftUI

struct ViewerView: View {
    @Environment(\.di) var di
    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        
        List {
            // 하자 점검
            Button {
                pathStore.defectPath.append(.defect(.defectList))
            } label: {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("하자 점검")
                                .font(.system(.title2))
                                .foregroundStyle(Color.black)
                            Text("내 방의 하자 정보 점검하기")
                                .foregroundStyle(Color.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 내 방 비교하기
            Button {
                // TODO: 페이지 연결
            } label: {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("내 방 비교")
                                .font(.system(.title2))
                                .foregroundStyle(Color.black)
                            Text("입주 전/후 내 방 비교하기")
                                .foregroundStyle(Color.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.gray)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("RoomLog")
    }
}
