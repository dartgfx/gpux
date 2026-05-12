package dev.dartgfx.flutter_wgpu

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

/**
 * Flutter texture sharing plugin for wgpu surfaces.
 *
 * Uses the new SurfaceProducer API for Impeller/Vulkan compatibility.
 * wgpu renders directly to the Surface via Vulkan swapchain.
 */
@RequiresApi(Build.VERSION_CODES.O)
class FlutterWgpuPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var textureRegistry: TextureRegistry
    private val surfaces = mutableMapOf<Long, WgpuSurfaceHolder>()
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "flutter_wgpu"

        init {
            System.loadLibrary("wgpu_native")
        }

        @JvmStatic
        external fun nativeGetWindow(surface: Surface): Long

        @JvmStatic
        external fun nativeReleaseWindow(windowPtr: Long)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_wgpu")
        channel.setMethodCallHandler(this)
        textureRegistry = binding.textureRegistry
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        surfaces.values.forEach { it.release() }
        surfaces.clear()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "createSurface" -> handleCreateSurface(call, result)
            "destroySurface" -> handleDestroySurface(call, result)
            "resizeSurface" -> handleResizeSurface(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleCreateSurface(call: MethodCall, result: Result) {
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")

        if (width == null || height == null) {
            result.error("INVALID_ARGS", "Missing width or height", null)
            return
        }

        try {
            // Use new SurfaceProducer API for Impeller compatibility
            val producer = textureRegistry.createSurfaceProducer()
            producer.setSize(width, height)

            val textureId = producer.id()
            val holder = WgpuSurfaceHolder(producer, width, height)

            // Set up lifecycle callbacks
            producer.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                override fun onSurfaceAvailable() {
                    Log.i(TAG, "Surface available: textureId=$textureId")
                    holder.updateSurface()
                    // Notify Dart that surface is ready
                    mainHandler.post {
                        channel.invokeMethod("onSurfaceAvailable", mapOf("textureId" to textureId))
                    }
                }

                override fun onSurfaceCleanup() {
                    Log.i(TAG, "Surface cleanup: textureId=$textureId")
                    holder.clearSurface()
                    // Notify Dart that surface is gone
                    mainHandler.post {
                        channel.invokeMethod("onSurfaceCleanup", mapOf("textureId" to textureId))
                    }
                }
            })

            // Get initial surface
            holder.updateSurface()

            if (holder.windowPtr == 0L) {
                producer.release()
                result.error("NATIVE_ERROR", "Failed to get ANativeWindow", null)
                return
            }

            surfaces[textureId] = holder

            Log.i(TAG, "Created surface: textureId=$textureId, windowPtr=0x${holder.windowPtr.toString(16)}, ${width}x${height}")

            result.success(mapOf(
                "textureId" to textureId,
                "windowPtr" to holder.windowPtr
            ))
        } catch (e: LinkageError) {
            Log.e(TAG, "Failed to link native surface bridge", e)
            result.error(
                "NATIVE_LINK_ERROR",
                "Failed to link native surface bridge: ${e.javaClass.simpleName}: ${e.message}",
                null
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create surface", e)
            result.error(
                "SURFACE_FAILED",
                "Failed to create surface: ${e.javaClass.simpleName}: ${e.message}",
                null
            )
        }
    }

    private fun handleDestroySurface(call: MethodCall, result: Result) {
        val textureId = call.argument<Number>("textureId")?.toLong()

        if (textureId == null) {
            result.error("INVALID_ARGS", "Missing textureId", null)
            return
        }

        surfaces[textureId]?.release()
        surfaces.remove(textureId)
        Log.i(TAG, "Destroyed surface: textureId=$textureId")
        result.success(null)
    }

    private fun handleResizeSurface(call: MethodCall, result: Result) {
        val textureId = call.argument<Number>("textureId")?.toLong()
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")

        if (textureId == null || width == null || height == null) {
            result.error("INVALID_ARGS", "Missing arguments", null)
            return
        }

        try {
            surfaces[textureId]?.let { holder ->
                holder.resize(width, height)
                Log.i(TAG, "Resized surface: textureId=$textureId, ${width}x${height}, windowPtr=0x${holder.windowPtr.toString(16)}")
                result.success(mapOf("windowPtr" to holder.windowPtr))
                return
            }
        } catch (e: LinkageError) {
            Log.e(TAG, "Failed to link native surface bridge", e)
            result.error(
                "NATIVE_LINK_ERROR",
                "Failed to link native surface bridge: ${e.javaClass.simpleName}: ${e.message}",
                null
            )
            return
        } catch (e: Exception) {
            Log.e(TAG, "Failed to resize surface", e)
            result.error(
                "SURFACE_RESIZE_FAILED",
                "Failed to resize surface: ${e.javaClass.simpleName}: ${e.message}",
                null
            )
            return
        }

        result.success(null)
    }
}

/**
 * Holds SurfaceProducer and manages Surface lifecycle.
 */
@RequiresApi(Build.VERSION_CODES.O)
class WgpuSurfaceHolder(
    private val producer: TextureRegistry.SurfaceProducer,
    private var width: Int,
    private var height: Int
) {
    private var surface: Surface? = null
    var windowPtr: Long = 0L
        private set

    fun updateSurface() {
        // Get fresh surface from producer
        releaseWindow()
        surface = producer.surface
        surface?.let { s ->
            windowPtr = FlutterWgpuPlugin.nativeGetWindow(s)
            Log.i("flutter_wgpu", "Updated surface: windowPtr=0x${windowPtr.toString(16)}")
        }
    }

    fun clearSurface() {
        releaseWindow()
        surface = null
    }

    fun resize(newWidth: Int, newHeight: Int) {
        width = newWidth
        height = newHeight
        producer.setSize(width, height)
        updateSurface()
    }

    fun release() {
        clearSurface()
        producer.release()
    }

    private fun releaseWindow() {
        if (windowPtr != 0L) {
            FlutterWgpuPlugin.nativeReleaseWindow(windowPtr)
            windowPtr = 0L
        }
    }
}
