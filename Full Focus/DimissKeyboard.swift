import SwiftUI
import UIKit

extension View {
    /// Chiude la tastiera solo quando il tocco arriva su uno sfondo vuoto.
    /// A differenza di un semplice `.simultaneousGesture` applicato all'intera
    /// view, questo layer sta DIETRO al contenuto: SwiftUI lo consulta solo
    /// per i tocchi che non vengono già intercettati da bottoni, TextField o
    /// altri controlli sopra di esso, che quindi restano invariati.
    func dismissKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
}
