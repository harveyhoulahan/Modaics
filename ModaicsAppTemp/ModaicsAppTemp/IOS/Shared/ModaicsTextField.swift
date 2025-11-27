//
//  ModaicsTextField.swift
//  Modaics
//
//  Reusable text field component with consistent theming
//

import SwiftUI

struct ModaicsTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.modaicsChrome1)
                }
                
                if isMultiline {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                        .foregroundColor(.modaicsCotton)
                        .scrollContentBackground(.hidden)
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.modaicsCotton)
                        .keyboardType(keyboardType)
                }
            }
            .padding()
            .background(Color.modaicsDarkBlue.opacity(0.6))
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.modaicsLightBlue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct ModaicsPicker<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let label: String
    let icon: String?
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(.modaicsChrome1)
                    }
                    
                    Text(selection.rawValue)
                        .foregroundColor(.modaicsCotton)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsChrome1)
                }
                .padding()
                .background(Color.modaicsDarkBlue.opacity(0.6))
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(Color.modaicsLightBlue.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
