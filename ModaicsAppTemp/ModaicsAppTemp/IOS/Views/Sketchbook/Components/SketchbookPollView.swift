//
//  SketchbookPollView.swift
//  ModaicsAppTemp
//
//  Poll voting interface for Sketchbook posts
//

import SwiftUI

struct SketchbookPollView: View {
    let question: String
    let options: [PollOption]
    let totalVotes: Int
    let isPollClosed: Bool
    let userHasVoted: Bool
    let onVote: ((Int) -> Void)?
    
    @State private var selectedOption: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsChrome1)
                
                Text(question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
            }
            
            // Options
            VStack(spacing: 12) {
                ForEach(options.indices, id: \.self) { index in
                    pollOptionView(option: options[index], index: index)
                }
            }
            
            // Footer
            HStack {
                Text("\(totalVotes) vote\(totalVotes == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.modaicsCottonLight)
                
                if isPollClosed {
                    Spacer()
                    Text("Poll closed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.modaicsChrome1.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(Color.modaicsDarkBlue.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func pollOptionView(option: PollOption, index: Int) -> some View {
        let percentage = totalVotes > 0 ? Double(option.votes) / Double(totalVotes) : 0.0
        let isSelected = selectedOption == index
        let showResults = userHasVoted || isPollClosed
        
        return Button(action: {
            guard !isPollClosed && !userHasVoted else { return }
            selectedOption = index
            onVote?(index)
        }) {
            ZStack(alignment: .leading) {
                // Background bar (results)
                if showResults {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.modaicsChrome1.opacity(0.3),
                                        Color.modaicsChrome2.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * percentage)
                    }
                }
                
                // Content
                HStack {
                    // Radio/Checkmark
                    if showResults {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .modaicsChrome1 : .modaicsCottonLight)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    Text(option.label)
                        .font(.system(size: 15))
                        .foregroundColor(.modaicsCotton)
                    
                    Spacer()
                    
                    if showResults {
                        Text("\(Int(percentage * 100))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.modaicsChrome1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.modaicsDarkBlue.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.modaicsChrome1.opacity(0.5) : Color.modaicsChrome1.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .disabled(isPollClosed || userHasVoted)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SketchbookPollView(
            question: "Which drop should we prioritize?",
            options: [
                PollOption(id: UUID().uuidString, label: "Summer Collection", votes: 45),
                PollOption(id: UUID().uuidString, label: "Fall Basics", votes: 32),
                PollOption(id: UUID().uuidString, label: "Winter Outerwear", votes: 23)
            ],
            totalVotes: 100,
            isPollClosed: false,
            userHasVoted: false,
            onVote: { _ in }
        )
        
        SketchbookPollView(
            question: "Favorite colorway?",
            options: [
                PollOption(id: UUID().uuidString, label: "Charcoal Gray", votes: 15),
                PollOption(id: UUID().uuidString, label: "Forest Green", votes: 8)
            ],
            totalVotes: 23,
            isPollClosed: true,
            userHasVoted: true,
            onVote: nil
        )
    }
    .padding()
    .background(Color.modaicsDarkBlue)
}
