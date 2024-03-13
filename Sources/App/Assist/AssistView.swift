import Shared
import SwiftUI

struct AssistView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AssistViewModel

    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    init(viewModel: AssistViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: .zero) {
                pipelinesPicker
                chatList
                bottomBar
            }
            .navigationTitle("Assist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
        .tint(Color(uiColor: .label))
    }

    private var pipelinesPicker: some View {
        VStack {
            // TODO: localize this even thought not visible, voice over reads out this
            Picker(L10n.Assist.PipelinesPicker.title, selection: $viewModel.preferredPipelineId) {
                ForEach(viewModel.pipelines, id: \.id) { pipeline in
                    Text(pipeline.name)
                        .font(.footnote)
                        .tag(pipeline.id)
                }
            }
            .pickerStyle(.menu)
            .tint(.gray)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.bottom)
    }

    private func makeChatBubble(item: AssistChatItem) -> some View {
        Text(item.content)
            .padding(8)
            .padding(.horizontal, 8)
            .background(backgroundForChatItemType(item.itemType))
            .roundedCorner(10, corners: roundedCornersForChatItemType(item.itemType))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: alignmentForChatItemType(item.itemType))
            .textSelection(.enabled)
    }

    private var chatList: some View {
        ZStack(alignment: .top) {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(viewModel.chatItems, id: \.id) { item in
                            makeChatBubble(item: item)
                                .id(item.id)
                        }
                    }
                    .padding()
                    .onChange(of: viewModel.chatItems) { _ in
                        proxy.scrollTo(viewModel.chatItems.last?.id)
                    }
                }
            }
            linearGradientDivider
        }
    }

    private var linearGradientDivider: some View {
        VStack {}
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            .background(LinearGradient(colors: [
                Color(uiColor: .systemBackground),
                .clear,
            ], startPoint: .top, endPoint: .bottom))
    }

    private var bottomBar: some View {
        HStack(spacing: .zero) {
            TextField("", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: viewModel.isRecording ? 0 : .infinity)
                .opacity(viewModel.isRecording ? 0 : 1)
                .animation(.smooth, value: viewModel.isRecording)
                .onSubmit {
                    viewModel.assistWithText()
                }
            assistSendTextButton
                .padding(.horizontal, Spaces.one)
            assistMicButton
        }
        .padding(.horizontal, Spaces.two)
        .padding(.bottom, isIpad ? Spaces.two : Spaces.one)
    }

    private var assistSendTextButton: some View {
        Button(action: {
            viewModel.assistWithText()
        }, label: {
            sendIcon
        })
        .frame(maxWidth: viewModel.isRecording ? 0 : nil)
        .opacity(viewModel.isRecording ? 0 : 1)
        .font(.system(size: 32))
        .tint(Color.asset(Asset.Colors.haPrimary))
        .animation(.smooth, value: viewModel.isRecording)
    }

    private var assistMicButton: some View {
        Button(action: {
            feedbackGenerator.notificationOccurred(.warning)
            if viewModel.isRecording {
                viewModel.stopStreaming()
            } else {
                viewModel.assistWithAudio()
            }
        }, label: {
            micIcon
        })
        .font(.system(size: viewModel.isRecording ? 60 : 32))
        .animation(.smooth, value: viewModel.isRecording)
        .onChange(of: viewModel.isRecording) { newValue in
            if !newValue {
                feedbackGenerator.notificationOccurred(.success)
            }
        }
    }

    private var sendIcon: some View {
        Image(systemName: "paperplane.circle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, Color.asset(Asset.Colors.haPrimary))
    }

    private var micIcon: some View {
        let micIcon = "mic.circle.fill"
        if #available(iOS 17.0, *) {
            return Image(systemName: viewModel.isRecording ? "waveform.badge.mic" : micIcon)
                .symbolEffect(
                    .variableColor.cumulative.dimInactiveLayers.nonReversing,
                    options: viewModel.isRecording ? .repeating : .nonRepeating,
                    value: viewModel.isRecording
                )
                .symbolRenderingMode(.palette)
                .foregroundStyle(viewModel.isRecording ? .gray : .white, Color.asset(Asset.Colors.haPrimary))
        } else {
            if viewModel.isRecording {
                return Image(systemName: "stop.circle")
            } else {
                return Image(systemName: micIcon)
            }
        }
    }

    private func backgroundForChatItemType(_ itemType: AssistChatItem.ItemType) -> Color {
        switch itemType {
        case .input:
            .asset(Asset.Colors.haPrimary)
        case .output:
            .gray
        case .error:
            .red
        case .info:
            .gray.opacity(0.5)
        }
    }

    private func alignmentForChatItemType(_ itemType: AssistChatItem.ItemType) -> Alignment {
        switch itemType {
        case .input:
            .trailing
        case .output:
            .leading
        case .error, .info:
            .center
        }
    }

    private func roundedCornersForChatItemType(_ itemType: AssistChatItem.ItemType) -> UIRectCorner {
        switch itemType {
        case .input:
            [.topLeft, .topRight, .bottomLeft]
        case .output:
            [.topLeft, .topRight, .bottomRight]
        case .error, .info:
            [.allCorners]
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true), content: {
            AssistView(viewModel: .init(server: ServerFixture.standard))
        })
}
