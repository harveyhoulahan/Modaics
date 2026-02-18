//
//  ModaicsTextField.swift
//  Modaics
//
//  Reusable text field component with dark green Porsche aesthetic
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
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.luxeGold)
                }
                
                if isMultiline {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                        .foregroundColor(.sageWhite)
                        .scrollContentBackground(.hidden)
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.sageWhite)
                        .keyboardType(keyboardType)
                }
            }
            .padding()
            .background(.forestMid.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: ForestRadius.medium)
                    .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
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
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
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
                            .foregroundColor(.luxeGold)
                    }
                    
                    Text(selection.rawValue)
                        .foregroundColor(.sageWhite)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.luxeGold)
                }
                .padding()
                .background(.forestMid.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.medium)
                        .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.forestBackground
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            ModaicsTextField(
                label: "Item Name",
                placeholder: "Enter item name",
                text: .constant(""),
                icon: "tshirt.fill"
            )
            
            ModaicsTextField(
                label: "Description",
                placeholder: "Enter description",
                text: .constant(""),
                isMultiline: true
            )
        }
        .padding()
    }
}
