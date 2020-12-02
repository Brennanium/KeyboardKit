//
//  StandardKeyboardLayoutProvider.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2020-12-01.
//  Copyright © 2020 Daniel Saidi. All rights reserved.
//

import Foundation
import UIKit

/**
 This keyboard layout provider bases its layout decisions on
 factors like device, screen orientation and locale. It aims
 to create a system keyboard layout for the provided context,
 which is not always what you want.
 
 This provider will fallback to lowercased alphabetic layout
 if the current context state doesn't have a standard layout.
 One example is if the current keyboard type is `.emojis` or
 another non-standard keyboard. Make sure to check for these
 states your self, and only use this for standard use cases.
 
 If you want to create a custom keyboard extension that does
 not rely on standard system keyboard conventions, you could
 register a custom layout provider or just ignore the entire
 layout provider concept altogether.
 
 You can inherit and customize this class to create your own
 provider that builds on this foundation.
 
 You can provide a custom left and right space action, which
 gives you a chance to customize the default actions, but in
 a limited way. If you want to make bigger changes, subclass.
 
 `IMPORTANT` This is a best effort. The iOS/iPadOS keyboards
 have layouts that depend on many factors. Some locales will
 not receive the correct layout with this implementation. To
 solve this, either subclass and fill in the gaps, or better:
 add the missing parts that you find and send a PR.
 */
open class StandardKeyboardLayoutProvider: KeyboardLayoutProvider {
    
    public init(
        leftSpaceAction: KeyboardAction? = nil,
        rightSpaceAction: KeyboardAction? = nil) {
        self.leftSpaceAction = leftSpaceAction
        self.rightSpaceAction = rightSpaceAction
    }
    
    private let leftSpaceAction: KeyboardAction?
    private let rightSpaceAction: KeyboardAction?
    
    open func keyboardLayout(for context: KeyboardContext) -> KeyboardLayout {
        let rows = context.actionRows
        let iPad = context.device.userInterfaceIdiom == .pad
        return keyboardLayout(for: context, iPad: iPad, rows: rows)
    }
    
    func keyboardLayout(
        for context: KeyboardContext,
        iPad: Bool,
        rows: KeyboardActionRows) -> KeyboardLayout {
        let rows = iPad
            ? iPadActions(for: context, rows: rows)
            : iPhoneActions(for: context, rows: rows)
        return KeyboardLayout(actionRows: rows)
    }
}

private extension StandardKeyboardLayoutProvider {
    
    /**
     Dictation is currently not supported and will not be in
     layouts generated that are generated by this class.
     */
    var isDictationSupported: Bool { false }
}


// MARK: - iPad layouts

private extension StandardKeyboardLayoutProvider {
    
    func iPadActions(
        for context: KeyboardContext,
        rows: KeyboardActionRows) -> KeyboardActionRows {
        var rows = rows
        
        if rows.count > 0 { rows[0] =
            iPadUpperLeadingActions(for: context) +
            rows[0] +
            iPadUpperTrailingActions(for: context)
        }
        
        if rows.count > 1 { rows[1] =
            iPadMiddleLeadingActions(for: context) +
            rows[1] +
            iPadMiddleTrailingActions(for: context)
        }
        
        if rows.count > 2 { rows[2] =
            iPadLowerLeadingActions(for: context) +
            rows[2] +
            iPadLowerTrailingActions(for: context)
        }
        
        rows.append(iPadBottomActions(for: context))
        
        return rows
    }
    
    func iPadUpperLeadingActions(for context: KeyboardContext) -> KeyboardActionRow {
        context.needsInputModeSwitchKey ? [] : [.tab]
    }
    
    func iPadUpperTrailingActions(for context: KeyboardContext) -> KeyboardActionRow {
        [.backspace]
    }
    
    func iPadMiddleLeadingActions(for context: KeyboardContext) -> KeyboardActionRow {
        context.needsInputModeSwitchKey ? [] : [.keyboardType(.alphabetic(.capsLocked))]
    }
    
    func iPadMiddleTrailingActions(for context: KeyboardContext) -> KeyboardActionRow {
        [.newLine]
    }
    
    func iPadLowerLeadingActions(for context: KeyboardContext) -> KeyboardActionRow {
        guard let action = context.keyboardType.standardSideKeyboardSwitcherAction else { return [] }
        return [action]
    }
    
    func iPadLowerTrailingActions(for context: KeyboardContext) -> KeyboardActionRow {
        iPadLowerLeadingActions(for: context)
    }
    
    func iPadBottomActions(for context: KeyboardContext) -> KeyboardActionRow {
        var result = KeyboardActionRow()
        let switcher = context.keyboardType.standardBottomKeyboardSwitcherAction
        
        if !context.needsInputModeSwitchKey {
            result.append(.nextKeyboard)
        }
        if let action = switcher {
            result.append(action)
        }
        if context.needsInputModeSwitchKey {
            result.append(.nextKeyboard)
        }
        if isDictationSupported {
            result.append(.dictation)
        }
        if let action = leftSpaceAction {
            result.append(action)
        }
        result.append(.space)
        if let action = rightSpaceAction {
            result.append(action)
        }
        if let action = switcher {
            result.append(action)
        }
        result.append(.dismissKeyboard)
        
        return result
    }
}


// MARK: - iPhone layouts

private extension StandardKeyboardLayoutProvider {
    
    func iPhoneActions(
        for context: KeyboardContext,
        rows: KeyboardActionRows) -> KeyboardActionRows {
        var rows = rows
        
        if rows.count > 0 { rows[0] =
            iPhoneUpperLeadingActions(for: context) +
            rows[0] +
            iPhoneUpperTrailingActions(for: context)
        }
        
        if rows.count > 1 { rows[1] =
            iPhoneMiddleLeadingActions(for: context) +
            rows[1] +
            iPhoneMiddleTrailingActions(for: context)
        }
        
        if rows.count > 2 { rows[2] =
            iPhoneLowerLeadingActions(for: context) +
            rows[2] +
            iPhoneLowerTrailingActions(for: context)
        }
        
        rows.append(iPhoneBottomActions(for: context))
        
        return rows
    }
    
    func iPhoneUpperLeadingActions(for context: KeyboardContext) -> KeyboardActionRow {
        []
    }
    
    func iPhoneUpperTrailingActions(for context: KeyboardContext) -> KeyboardActionRow {
        []
    }
    
    func iPhoneMiddleLeadingActions(for context: KeyboardContext) -> KeyboardActionRow {
        []
    }
    
    func iPhoneMiddleTrailingActions(for context: KeyboardContext) -> KeyboardActionRow {
        []
    }
    
    func iPhoneLowerLeadingActions(for context: KeyboardContext) -> KeyboardActionRow {
        guard let action = context.keyboardType.standardSideKeyboardSwitcherAction else { return [] }
        return [action]
    }
    
    func iPhoneLowerTrailingActions(for context: KeyboardContext) -> KeyboardActionRow {
        [.backspace]
    }
    
    func iPhoneBottomActions(for context: KeyboardContext) -> KeyboardActionRow {
        var result = KeyboardActionRow()
        let switcher = context.keyboardType.standardBottomKeyboardSwitcherAction
        
        if let action = switcher {
            result.append(action)
        }
        if context.needsInputModeSwitchKey {
            result.append(.nextKeyboard)
        }
        if isDictationSupported {
            result.append(.dictation)
        }
        if let action = leftSpaceAction {
            result.append(action)
        }
        result.append(.space)
        if let action = rightSpaceAction {
            result.append(action)
        }
        result.append(.newLine)
        
        return result
    }
}

private extension KeyboardContext {

    var actionRows: KeyboardActionRows {
        KeyboardActionRows(characters: inputRows)
    }
    
    var inputRows: [KeyboardInputSet.InputRow] {
        switch keyboardType {
        case .alphabetic(let state):
            let rows = inputSetProvider.alphabeticInputSet.inputRows
            return state.isUppercased ? rows.uppercased() : rows
        case .numeric: return inputSetProvider.numericInputSet.inputRows
        case .symbolic: return inputSetProvider.symbolicInputSet.inputRows
        default: return inputSetProvider.alphabeticInputSet.inputRows
        }
    }
}
