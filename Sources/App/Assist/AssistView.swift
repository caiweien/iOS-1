//
//  AssistView.swift
//  App
//
//  Created by Bruno Pantaleão on 19/11/2023.
//  Copyright © 2023 Home Assistant. All rights reserved.
//

import SwiftUI

@available(iOS 13, *)
struct AssistView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: AssistViewModel

    init(viewModel: AssistViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // TODO localize this even thought not visible, voice over reads out this
                Picker("Assist Pipelines", selection: $viewModel.preferredPipelineId) {
                    ForEach(viewModel.pipelines, id: \.id) {
                        Text($0.name)
                            .tag($0.id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ScrollView {
                VStack {
                    ForEach(viewModel.chatItems, id: \.id) {
                        makeChatBubble(item: $0)
                    }
                }
            }
            .padding(.top)
            HStack {
                TextField("Placeholder", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                Group {
                    Button(action: {
                        viewModel.assist()
                    }, label: {
                        Image(systemName: "paperplane.fill")
                    })
                    Button(action: {
                        viewModel.startStreaming()
                    }, label: {
                        Image(systemName: "mic.fill")
                    })
                }
                .padding(8)
            }
        }
        .padding()
        .onAppear {
            viewModel.initialWebsocketConnection()
        }
        .onDisappear {
            viewModel.endProcesses()
        }
    }

    private func makeChatBubble(item: AssistChatItem) -> some View {
        HStack {
            Text(item.content)
                .padding()
                .background(item.itemType == .input ? Color.blue : Color.gray)
                .cornerRadius(10)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: item.itemType == .input ? .trailing : .leading)
        }
    }
}
