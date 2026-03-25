// Flutter texture sharing plugin for wgpu surfaces via IOSurface.
// Shared between iOS and macOS using sharedDarwinSource.

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import Cocoa
#endif

import IOSurface
import CoreVideo

/// Context stored per engine for FFI access.
private class EngineContext {
    weak var textureRegistry: FlutterTextureRegistry?

    init(textureRegistry: FlutterTextureRegistry) {
        self.textureRegistry = textureRegistry
    }
}

@objc(FlutterWgpuPlugin)
public class FlutterWgpuPlugin: NSObject, FlutterPlugin {
    // Static registry for engine contexts, keyed by handle.
    // Allows Rust FFI to access texture registry directly.
    private static var engineContexts: [Int64: EngineContext] = [:]
    private static var nextHandle: Int64 = 1

    private let textureRegistry: FlutterTextureRegistry
    private let engineHandle: Int64
    private var textures: [Int64: WgpuTextureHolder] = [:]

    init(textureRegistry: FlutterTextureRegistry, engineHandle: Int64) {
        self.textureRegistry = textureRegistry
        self.engineHandle = engineHandle
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        let textures = registrar.textures()
        #elseif os(macOS)
        let messenger = registrar.messenger
        let textures = registrar.textures
        #endif

        // Assign unique handle for this engine
        let handle = nextHandle
        nextHandle += 1

        // Store context for FFI access
        let context = EngineContext(textureRegistry: textures)
        engineContexts[handle] = context

        let channel = FlutterMethodChannel(name: "flutter_wgpu", binaryMessenger: messenger)
        let instance = FlutterWgpuPlugin(textureRegistry: textures, engineHandle: handle)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - FFI Entry Points
    // These class methods are called from Rust via objc runtime.

    /// Get texture registry for the given engine handle.
    /// Called from Rust: `msg_send![class!(FlutterWgpuPlugin), getTextureRegistry: handle]`
    @objc public static func getTextureRegistry(_ handle: Int64) -> FlutterTextureRegistry? {
        return engineContexts[handle]?.textureRegistry
    }

    /// Mark a texture frame as available. Direct FFI path, bypasses MethodChannel.
    /// Called from Rust: `msg_send![class!(FlutterWgpuPlugin), markFrameAvailable: handle textureId: id]`
    @objc public static func markFrameAvailable(_ handle: Int64, textureId: Int64) {
        engineContexts[handle]?.textureRegistry?.textureFrameAvailable(textureId)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getEngineHandle":
            result(engineHandle)
        case "registerTexture":
            handleRegisterTexture(call, result: result)
        case "unregisterTexture":
            handleUnregisterTexture(call, result: result)
        case "markFrameAvailable":
            handleMarkFrameAvailable(call, result: result)
        case "updateTexture":
            handleUpdateTexture(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleRegisterTexture(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let platformHandle = args["platformHandle"] as? UInt32,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
            return
        }

        // Look up IOSurface by ID
        guard let surface = IOSurfaceLookup(platformHandle) else {
            result(FlutterError(code: "IOSURFACE_NOT_FOUND", message: "IOSurface not found: \(platformHandle)", details: nil))
            return
        }

        // Create CVPixelBuffer from IOSurface
        guard let buffer = createPixelBuffer(from: surface) else {
            result(FlutterError(code: "PIXELBUFFER_FAILED", message: "Failed to create CVPixelBuffer from IOSurface", details: nil))
            return
        }

        // Create texture holder and register with Flutter
        let holder = WgpuTextureHolder(pixelBuffer: buffer, width: width, height: height)
        let textureId = textureRegistry.register(holder)
        textures[textureId] = holder

        NSLog("flutter_wgpu: Registered texture \(textureId) from IOSurface \(platformHandle) (\(width)x\(height))")
        result(textureId)
    }

    private func handleUnregisterTexture(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let textureId = args["textureId"] as? Int64 else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing textureId", details: nil))
            return
        }

        textureRegistry.unregisterTexture(textureId)
        textures.removeValue(forKey: textureId)
        NSLog("flutter_wgpu: Unregistered texture \(textureId)")
        result(nil)
    }

    private func handleMarkFrameAvailable(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let textureId = args["textureId"] as? Int64 else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing textureId", details: nil))
            return
        }

        textureRegistry.textureFrameAvailable(textureId)
        result(nil)
    }

    private func handleUpdateTexture(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let textureId = args["textureId"] as? Int64,
              let platformHandle = args["platformHandle"] as? UInt32,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
            return
        }

        // Look up new IOSurface
        guard let surface = IOSurfaceLookup(platformHandle) else {
            result(FlutterError(code: "IOSURFACE_NOT_FOUND", message: "IOSurface not found: \(platformHandle)", details: nil))
            return
        }

        // Create new CVPixelBuffer
        guard let buffer = createPixelBuffer(from: surface) else {
            result(FlutterError(code: "PIXELBUFFER_FAILED", message: "Failed to create CVPixelBuffer from IOSurface", details: nil))
            return
        }

        // Update holder
        if let holder = textures[textureId] {
            holder.updatePixelBuffer(buffer, width: width, height: height)
            NSLog("flutter_wgpu: Updated texture \(textureId) to IOSurface \(platformHandle) (\(width)x\(height))")
        }

        result(nil)
    }
}

class WgpuTextureHolder: NSObject, FlutterTexture {
    private var pixelBuffer: CVPixelBuffer
    private var width: Int
    private var height: Int

    init(pixelBuffer: CVPixelBuffer, width: Int, height: Int) {
        self.pixelBuffer = pixelBuffer
        self.width = width
        self.height = height
        super.init()
    }

    func updatePixelBuffer(_ buffer: CVPixelBuffer, width: Int, height: Int) {
        self.pixelBuffer = buffer
        self.width = width
        self.height = height
    }

    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        return Unmanaged.passRetained(pixelBuffer)
    }
}

private func createPixelBuffer(from surface: IOSurfaceRef) -> CVPixelBuffer? {
    var unmanagedBuffer: Unmanaged<CVPixelBuffer>?
    let attrs: [String: Any] = [
        kCVPixelBufferMetalCompatibilityKey as String: true
    ]
    let status = CVPixelBufferCreateWithIOSurface(
        kCFAllocatorDefault,
        surface,
        attrs as CFDictionary,
        &unmanagedBuffer
    )
    guard status == kCVReturnSuccess, let unmanaged = unmanagedBuffer else {
        return nil
    }
    return unmanaged.takeRetainedValue()
}
