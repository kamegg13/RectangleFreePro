//
//  HyperKeyManager.swift
//  Rectangle
//
//  Pro Feature: Caps Lock → Hyper key (Cmd+Ctrl+Alt+Shift)
//  - Tap rapide (<150ms) → émet Escape
//  - Maintenu → injecte les modificateurs Hyper dans les events suivants
//

import Cocoa

class HyperKeyManager {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Timestamp du moment où Caps Lock a été pressé
    private var capsDownTime: TimeInterval = 0
    /// Indique si Caps Lock est actuellement maintenu
    private var capsHeld: Bool = false
    /// Indique si on a déjà injecté des events "hyper" depuis ce hold
    private var hyperInjected: Bool = false

    static let tapTimeout: TimeInterval = 0.15  // 150ms

    // Flags Hyper = Cmd + Ctrl + Alt + Shift
    static let hyperFlags: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]

    // MARK: - Lifecycle

    func enable() {
        guard Defaults.hyperKeyEnabled.enabled else { return }
        guard eventTap == nil else { return }

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, userInfo in
                guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HyperKeyManager>.fromOpaque(userInfo).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = tap else {
            Logger.log("HyperKeyManager: failed to create event tap (accessibility permission required)")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func disable() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Event handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let capsLockKeyCode: Int64 = 57

        switch type {
        case .flagsChanged:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            guard keyCode == capsLockKeyCode else {
                // Pass through, but inject Hyper flags if caps is held
                if capsHeld {
                    event.flags = event.flags.union(HyperKeyManager.hyperFlags)
                }
                return Unmanaged.passRetained(event)
            }

            let capsCurrentlyDown = event.flags.contains(.maskAlphaShift) || isCapsDown(event)

            if capsCurrentlyDown && !capsHeld {
                // Caps Lock pressed down
                capsDownTime = Date.timeIntervalSinceReferenceDate
                capsHeld = true
                hyperInjected = false
                return nil  // consume the event
            } else if !capsCurrentlyDown && capsHeld {
                // Caps Lock released
                capsHeld = false
                let elapsed = Date.timeIntervalSinceReferenceDate - capsDownTime
                if elapsed < HyperKeyManager.tapTimeout && !hyperInjected {
                    // Short tap → emit Escape
                    injectEscape(proxy: proxy)
                }
                return nil  // consume the event
            }
            return nil

        case .keyDown, .keyUp:
            if capsHeld {
                // Inject Hyper modifiers into the key event
                event.flags = event.flags.union(HyperKeyManager.hyperFlags)
                hyperInjected = true
            }
            return Unmanaged.passRetained(event)

        default:
            return Unmanaged.passRetained(event)
        }
    }

    private func isCapsDown(_ event: CGEvent) -> Bool {
        // On flagsChanged events, check if the Caps Lock scan code is being pressed
        // CGEvent doesn't directly expose this, so we rely on the alpha-shift flag
        // being set on key-down and unset on key-up
        return event.flags.contains(.maskAlphaShift)
    }

    private func injectEscape(proxy: CGEventTapProxy) {
        guard let escDown = CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: true),
              let escUp = CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: false)
        else { return }
        escDown.tapPostEvent(proxy)
        escUp.tapPostEvent(proxy)
    }
}
