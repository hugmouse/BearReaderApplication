//
//  PostTranslationTaskModifier.swift
//  BearReaderApplication
//

import SwiftUI
import Translation

struct PostTranslationTaskModifier: ViewModifier {
    let requestID: Int
    let makeRequests: @Sendable () async -> [PostTranslationRequest]
    let applyTranslations: @Sendable ([String: String]) async -> Void
    let finishTranslation: @Sendable () async -> Void
    let failTranslation: @Sendable (Error) async -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.modifier(
                AvailablePostTranslationTaskModifier(
                    requestID: requestID,
                    makeRequests: makeRequests,
                    applyTranslations: applyTranslations,
                    finishTranslation: finishTranslation,
                    failTranslation: failTranslation
                )
            )
        } else {
            content
        }
    }
}

@available(iOS 18.0, *)
private struct AvailablePostTranslationTaskModifier: ViewModifier {
    let requestID: Int
    let makeRequests: @Sendable () async -> [PostTranslationRequest]
    let applyTranslations: @Sendable ([String: String]) async -> Void
    let finishTranslation: @Sendable () async -> Void
    let failTranslation: @Sendable (Error) async -> Void
    @State private var configuration: TranslationSession.Configuration?

    func body(content: Content) -> some View {
        content
            .onChange(of: requestID) { _, newValue in
                guard newValue > 0 else { return }

                let targetLanguage = Locale.Language(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
                if configuration == nil {
                    configuration = TranslationSession.Configuration(source: nil, target: targetLanguage)
                } else {
                    configuration?.invalidate()
                }
            }
            .translationTask(configuration) { @Sendable session in
                await performTranslation(using: session)
            }
    }

    nonisolated private func performTranslation(using session: TranslationSession) async {
        let requests = await makeRequests()
        guard !requests.isEmpty else {
            await finishTranslation()
            return
        }

        do {
            let translationRequests = requests.map { request in
                TranslationSession.Request(sourceText: request.text, clientIdentifier: request.id)
            }
            let responses = session.translate(batch: translationRequests)
            var translations = [String: String]()
            for try await response in responses {
                if let clientIdentifier = response.clientIdentifier {
                    translations[clientIdentifier] = response.targetText
                }
            }
            await applyTranslations(translations)
        } catch {
            await failTranslation(error)
        }
    }
}
