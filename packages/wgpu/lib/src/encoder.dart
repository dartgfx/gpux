import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';
import '../wgpu_ffi.dart' show wgpuLastError;
import 'ffi/bindings_generated.dart' as ffi;
import 'ffi/enum_ffi.dart';
import 'resource.dart';
import 'bind_group.dart';
import 'buffer.dart';
import 'pipeline.dart';
import 'query_set.dart';
import 'texture.dart';

/// A command encoder for recording GPU commands.
class WgpuCommandEncoder implements GpuCommandEncoder {
  @override
  String label;
  int _handle;
  bool _finished = false;
  bool _inRenderPass = false;
  bool _inComputePass = false;

  WgpuCommandEncoder.internal(this._handle, {this.label = ''});

  /// Native handle. Use with care.
  int get handle => _handle;

  /// Begins a render pass.
  /// The encoder cannot be used until the render pass ends.
  @override
  WgpuRenderPassEncoder beginRenderPass({
    required List<GpuColorAttachment> colorAttachments,
    GpuDepthStencilAttachment? depthStencilAttachment,
    GpuQuerySet? occlusionQuerySet,
    GpuRenderPassTimestampWrites? timestampWrites,
    int maxDrawCount = 50000000,
    String label = '',
  }) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass) {
      throw StateError('Already in a render pass');
    }

    final passHandle = using((arena) {
      // Allocate color attachments
      final colorAttachmentsPtr = arena<ffi.WGPURenderPassColorAttachment>(
        colorAttachments.length,
      );
      for (var i = 0; i < colorAttachments.length; i++) {
        final a = colorAttachments[i];
        colorAttachmentsPtr[i].view = (a.view as WgpuTextureView).handle;
        colorAttachmentsPtr[i].resolve_target =
            (a.resolveTarget as WgpuTextureView?)?.handle ?? 0;
        colorAttachmentsPtr[i].load_op = a.loadOp.ffiValue;
        colorAttachmentsPtr[i].store_op = a.storeOp.ffiValue;
        colorAttachmentsPtr[i].clear_r = a.clearValue?.r ?? 0.0;
        colorAttachmentsPtr[i].clear_g = a.clearValue?.g ?? 0.0;
        colorAttachmentsPtr[i].clear_b = a.clearValue?.b ?? 0.0;
        colorAttachmentsPtr[i].clear_a = a.clearValue?.a ?? 0.0;
        // u32::MAX = None (no depth slice)
        colorAttachmentsPtr[i].depth_slice = a.depthSlice ?? 0xFFFFFFFF;
      }

      // Allocate depth stencil attachment if provided
      Pointer<ffi.WGPURenderPassDepthStencilAttachment> depthStencilPtr =
          nullptr;
      if (depthStencilAttachment != null) {
        depthStencilPtr = arena<ffi.WGPURenderPassDepthStencilAttachment>();
        final ds = depthStencilAttachment;
        depthStencilPtr.ref.view = (ds.view as WgpuTextureView).handle;
        depthStencilPtr.ref.depth_load_op =
            ds.depthLoadOp?.ffiValue ?? GpuLoadOp.clear.ffiValue;
        depthStencilPtr.ref.depth_store_op =
            ds.depthStoreOp?.ffiValue ?? GpuStoreOp.store.ffiValue;
        depthStencilPtr.ref.depth_clear_value = ds.depthClearValue ?? 0.0;
        depthStencilPtr.ref.depth_read_only = ds.depthReadOnly ? 1 : 0;
        depthStencilPtr.ref.stencil_load_op =
            ds.stencilLoadOp?.ffiValue ?? GpuLoadOp.clear.ffiValue;
        depthStencilPtr.ref.stencil_store_op =
            ds.stencilStoreOp?.ffiValue ?? GpuStoreOp.store.ffiValue;
        depthStencilPtr.ref.stencil_clear_value = ds.stencilClearValue;
        depthStencilPtr.ref.stencil_read_only = ds.stencilReadOnly ? 1 : 0;
      }

      // Allocate descriptor
      final desc = arena<ffi.WGPURenderPassDescriptor>();
      desc.ref.color_attachments = colorAttachmentsPtr;
      desc.ref.color_attachment_count = colorAttachments.length;
      desc.ref.depth_stencil_attachment = depthStencilPtr;
      desc.ref.occlusion_query_set =
          (occlusionQuerySet as WgpuQuerySet?)?.handle ?? 0;
      desc.ref.max_draw_count = maxDrawCount;
      if (timestampWrites != null) {
        desc.ref.timestamp_writes_query_set =
            (timestampWrites.querySet as WgpuQuerySet).handle;
        desc.ref.timestamp_writes_beginning =
            timestampWrites.beginningOfPassWriteIndex ?? 0xFFFFFFFF;
        desc.ref.timestamp_writes_end =
            timestampWrites.endOfPassWriteIndex ?? 0xFFFFFFFF;
      }
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      return ffi.wgpun_CommandEncoderBeginRenderPass(_handle, desc);
    });

    if (passHandle == 0) {
      throw StateError('Failed to begin render pass: ${wgpuLastError()}');
    }

    _inRenderPass = true;
    return WgpuRenderPassEncoder._(passHandle, this, label: label);
  }

  /// Called by WgpuRenderPassEncoder when render pass ends.
  void _onRenderPassEnd(int newEncoderHandle) {
    _handle = newEncoderHandle;
    _inRenderPass = false;
  }

  /// Begins a compute pass.
  /// The encoder cannot be used until the compute pass ends.
  @override
  WgpuComputePassEncoder beginComputePass({
    GpuComputePassTimestampWrites? timestampWrites,
    String label = '',
  }) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass) {
      throw StateError('Already in a render pass');
    }
    if (_inComputePass) {
      throw StateError('Already in a compute pass');
    }

    final passHandle = using((arena) {
      final desc = arena<ffi.WGPUComputePassDescriptor>();
      if (timestampWrites != null) {
        desc.ref.timestamp_writes_query_set =
            (timestampWrites.querySet as WgpuQuerySet).handle;
        desc.ref.timestamp_writes_beginning =
            timestampWrites.beginningOfPassWriteIndex ?? 0xFFFFFFFF;
        desc.ref.timestamp_writes_end =
            timestampWrites.endOfPassWriteIndex ?? 0xFFFFFFFF;
      }
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }
      return ffi.wgpun_CommandEncoderBeginComputePass(_handle, desc);
    });

    if (passHandle == 0) {
      throw StateError('Failed to begin compute pass: ${wgpuLastError()}');
    }

    _inComputePass = true;
    return WgpuComputePassEncoder._(passHandle, this, label: label);
  }

  /// Called by GpuComputePassEncoder when compute pass ends.
  void _onComputePassEnd(int newEncoderHandle) {
    _handle = newEncoderHandle;
    _inComputePass = false;
  }

  /// Copies data from one buffer to another.
  ///
  /// Both buffers must have been created with appropriate usage flags:
  /// - [source] must have [GpuBufferUsage.copySrc]
  /// - [destination] must have [GpuBufferUsage.copyDst]
  @override
  void copyBufferToBuffer({
    required GpuBuffer source,
    int sourceOffset = 0,
    required GpuBuffer destination,
    int destinationOffset = 0,
    required int size,
  }) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot copy buffers while in a pass');
    }
    final src = source as WgpuBuffer;
    final dst = destination as WgpuBuffer;
    if (src.handle == 0) {
      throw ArgumentError('source buffer handle is invalid (0)');
    }
    if (dst.handle == 0) {
      throw ArgumentError('destination buffer handle is invalid (0)');
    }
    if (size <= 0) {
      throw ArgumentError('size must be positive');
    }

    final result = ffi.wgpun_CommandEncoderCopyBufferToBuffer(
      _handle,
      src.handle,
      sourceOffset,
      dst.handle,
      destinationOffset,
      size,
    );

    if (result == 0) {
      throw StateError(
        'Failed to copy buffer: srcOffset=$sourceOffset, dstOffset=$destinationOffset, size=$size - ${wgpuLastError()}',
      );
    }
  }

  /// Clears a buffer to zeros.
  ///
  /// The buffer must have been created with [GpuBufferUsage.copyDst].
  ///
  /// If [size] is null, clears from [offset] to the end of the buffer.
  /// Both [offset] and [size] must be multiples of 4.
  @override
  void clearBuffer(GpuBuffer buffer, {int offset = 0, int? size}) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot clear buffer while in a pass');
    }
    final buf = buffer as WgpuBuffer;
    if (buf.handle == 0) {
      throw ArgumentError('buffer handle is invalid (0)');
    }

    final result = ffi.wgpun_CommandEncoderClearBuffer(
      _handle,
      buf.handle,
      offset,
      size ?? 0,
    );

    if (result == 0) {
      throw StateError(
        'Failed to clear buffer: offset=$offset, size=$size - ${wgpuLastError()}',
      );
    }
  }

  /// Copies data from a texture to a buffer.
  ///
  /// The texture must have been created with [GpuTextureUsage.copySrc].
  /// The buffer must have been created with [GpuBufferUsage.copyDst].
  ///
  /// [bytesPerRow] must be a multiple of 256 (COPY_BYTES_PER_ROW_ALIGNMENT).
  @override
  void copyTextureToBuffer({
    required GpuTexture source,
    required GpuBuffer destination,
    required int bytesPerRow,
    required int width,
    required int height,
    int? rowsPerImage,
    int depth = 1,
    int mipLevel = 0,
    int originX = 0,
    int originY = 0,
    int originZ = 0,
  }) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot copy texture to buffer while in a pass');
    }
    if (bytesPerRow % 256 != 0) {
      throw ArgumentError(
        'bytesPerRow must be a multiple of 256 (COPY_BYTES_PER_ROW_ALIGNMENT), got $bytesPerRow',
      );
    }
    final src = source as WgpuTexture;
    final dstBuf = destination as WgpuBuffer;
    if (src.handle == 0) {
      throw ArgumentError('source texture handle is invalid (0)');
    }
    if (dstBuf.handle == 0) {
      throw ArgumentError('destination buffer handle is invalid (0)');
    }

    final result = ffi.wgpun_CommandEncoderCopyTextureToBuffer(
      _handle,
      src.handle,
      dstBuf.handle,
      bytesPerRow,
      rowsPerImage ?? 0,
      width,
      height,
      depth,
      mipLevel,
      originX,
      originY,
      originZ,
    );

    if (result == 0) {
      throw StateError(
        'Failed to copy texture to buffer: ${width}x${height}x$depth, bytesPerRow=$bytesPerRow - ${wgpuLastError()}',
      );
    }
  }

  /// Copies data from a buffer to a texture.
  ///
  /// The buffer must have been created with [GpuBufferUsage.copySrc].
  /// The texture must have been created with [GpuTextureUsage.copyDst].
  ///
  /// [bytesPerRow] must be a multiple of 256 (COPY_BYTES_PER_ROW_ALIGNMENT).
  @override
  void copyBufferToTexture({
    required GpuBuffer source,
    required GpuTexture destination,
    required int bytesPerRow,
    required int width,
    required int height,
    int? rowsPerImage,
    int depth = 1,
    int mipLevel = 0,
    int originX = 0,
    int originY = 0,
    int originZ = 0,
  }) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot copy buffer to texture while in a pass');
    }
    if (bytesPerRow % 256 != 0) {
      throw ArgumentError(
        'bytesPerRow must be a multiple of 256 (COPY_BYTES_PER_ROW_ALIGNMENT), got $bytesPerRow',
      );
    }
    final srcBuf = source as WgpuBuffer;
    final dst = destination as WgpuTexture;
    if (srcBuf.handle == 0) {
      throw ArgumentError('source buffer handle is invalid (0)');
    }
    if (dst.handle == 0) {
      throw ArgumentError('destination texture handle is invalid (0)');
    }

    final result = ffi.wgpun_CommandEncoderCopyBufferToTexture(
      _handle,
      srcBuf.handle,
      dst.handle,
      bytesPerRow,
      rowsPerImage ?? 0,
      width,
      height,
      depth,
      mipLevel,
      originX,
      originY,
      originZ,
    );

    if (result == 0) {
      throw StateError(
        'Failed to copy buffer to texture: ${width}x${height}x$depth, bytesPerRow=$bytesPerRow - ${wgpuLastError()}',
      );
    }
  }

  /// Copies data from one texture to another.
  ///
  /// Both textures must have compatible formats.
  /// The source must have been created with [GpuTextureUsage.copySrc].
  /// The destination must have been created with [GpuTextureUsage.copyDst].
  @override
  void copyTextureToTexture({
    required GpuTexture source,
    required GpuTexture destination,
    required int width,
    required int height,
    int depth = 1,
    int srcMipLevel = 0,
    int srcOriginX = 0,
    int srcOriginY = 0,
    int srcOriginZ = 0,
    int dstMipLevel = 0,
    int dstOriginX = 0,
    int dstOriginY = 0,
    int dstOriginZ = 0,
  }) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot copy texture to texture while in a pass');
    }
    final src = source as WgpuTexture;
    final dst = destination as WgpuTexture;
    if (src.handle == 0) {
      throw ArgumentError('source texture handle is invalid (0)');
    }
    if (dst.handle == 0) {
      throw ArgumentError('destination texture handle is invalid (0)');
    }

    final result = ffi.wgpun_CommandEncoderCopyTextureToTexture(
      _handle,
      src.handle,
      dst.handle,
      width,
      height,
      depth,
      srcMipLevel,
      srcOriginX,
      srcOriginY,
      srcOriginZ,
      dstMipLevel,
      dstOriginX,
      dstOriginY,
      dstOriginZ,
    );

    if (result == 0) {
      throw StateError(
        'Failed to copy texture to texture: ${width}x${height}x$depth - ${wgpuLastError()}',
      );
    }
  }

  /// Resolves query set results to a buffer.
  ///
  /// Each timestamp is 8 bytes (u64). Multiply by [Gpu.queue.getTimestampPeriod()]
  /// to convert to nanoseconds.
  ///
  /// The destination buffer must have [GpuBufferUsage.queryResolve] usage.
  @override
  void resolveQuerySet(
    GpuQuerySet querySet, {
    required int firstQuery,
    required int queryCount,
    required GpuBuffer destination,
    int destinationOffset = 0,
  }) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot resolve query set while in a pass');
    }
    if (firstQuery < 0) {
      throw ArgumentError('firstQuery must be non-negative');
    }
    if (queryCount <= 0) {
      throw ArgumentError('queryCount must be positive');
    }
    if (firstQuery + queryCount > querySet.count) {
      throw ArgumentError(
        'firstQuery ($firstQuery) + queryCount ($queryCount) exceeds querySet.count (${querySet.count})',
      );
    }
    if (destinationOffset < 0) {
      throw ArgumentError('destinationOffset must be non-negative');
    }
    final dstBuf = destination as WgpuBuffer;
    if (dstBuf.handle == 0) {
      throw ArgumentError('destination buffer handle is invalid (0)');
    }

    final result = ffi.wgpun_CommandEncoderResolveQuerySet(
      _handle,
      (querySet as WgpuQuerySet).handle,
      firstQuery,
      queryCount,
      dstBuf.handle,
      destinationOffset,
    );

    if (result == 0) {
      throw StateError('Failed to resolve query set: ${wgpuLastError()}');
    }
  }

  @override
  void insertDebugMarker(String label) {
    if (_finished) throw StateError('Command encoder already finished');
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot insert debug marker while in a pass');
    }

    using((arena) {
      final labelPtr = label.toNativeUtf8(allocator: arena);
      ffi.wgpun_CommandEncoderInsertDebugMarker(_handle, labelPtr.cast());
    });
  }

  @override
  void pushDebugGroup(String label) {
    if (_finished) throw StateError('Command encoder already finished');
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot push debug group while in a pass');
    }

    using((arena) {
      final labelPtr = label.toNativeUtf8(allocator: arena);
      ffi.wgpun_CommandEncoderPushDebugGroup(_handle, labelPtr.cast());
    });
  }

  @override
  void popDebugGroup() {
    if (_finished) throw StateError('Command encoder already finished');
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot pop debug group while in a pass');
    }

    ffi.wgpun_CommandEncoderPopDebugGroup(_handle);
  }

  /// Finishes recording and returns a command buffer.
  /// The encoder cannot be used after this.
  ///
  /// Note: [label] is accepted per the WebGPU spec but wgpu's
  /// `CommandEncoder::finish()` takes no parameters.
  @override
  WgpuCommandBuffer finish({String label = ''}) {
    if (_finished) {
      throw StateError('Command encoder already finished');
    }
    if (_inRenderPass || _inComputePass) {
      throw StateError('Cannot finish while in a pass');
    }

    final bufferHandle = ffi.wgpun_CommandEncoderFinish(_handle);
    _finished = true;

    if (bufferHandle == 0) {
      throw StateError('Failed to finish command encoder: ${wgpuLastError()}');
    }

    return WgpuCommandBuffer.internal(bufferHandle);
  }
}

/// A render pass encoder for recording draw commands.
class WgpuRenderPassEncoder implements GpuRenderPassEncoder {
  @override
  String label;
  final int _handle;
  final WgpuCommandEncoder _encoder;
  bool _ended = false;

  WgpuRenderPassEncoder._(this._handle, this._encoder, {this.label = ''});

  /// Native handle. Use with care.
  int get handle => _handle;

  /// Sets the render pipeline.
  @override
  void setPipeline(GpuRenderPipeline pipeline) {
    if (_ended) throw StateError('Render pass already ended');
    ffi.wgpun_RenderPassEncoderSetPipeline(
      _handle,
      (pipeline as WgpuRenderPipeline).handle,
    );
  }

  /// Sets a bind group with optional dynamic offsets.
  @override
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    final bg = (bindGroup as WgpuBindGroup).handle;
    if (dynamicOffsets != null && dynamicOffsets.isNotEmpty) {
      using((arena) {
        final offsetsPtr = arena<Uint32>(dynamicOffsets.length);
        for (var i = 0; i < dynamicOffsets.length; i++) {
          offsetsPtr[i] = dynamicOffsets[i];
        }
        ffi.wgpun_RenderPassEncoderSetBindGroup(
          _handle,
          index,
          bg,
          offsetsPtr,
          dynamicOffsets.length,
        );
      });
    } else {
      ffi.wgpun_RenderPassEncoderSetBindGroup(
        _handle,
        index,
        bg,
        nullptr,
        0,
      );
    }
  }

  /// Sets a vertex buffer, or null to unbind.
  @override
  void setVertexBuffer(
    int slot,
    GpuBuffer? buffer, {
    int offset = 0,
    int? size,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    if (slot < 0) throw ArgumentError('slot must be non-negative');
    if (buffer == null) {
      ffi.wgpun_RenderPassEncoderSetVertexBuffer(
        _handle,
        slot,
        0, // null handle unbinds the slot
        0,
        0,
      );
      return;
    }
    if (offset < 0) throw ArgumentError('offset must be non-negative');
    if (size != null && size <= 0) throw ArgumentError('size must be positive');
    final buf = buffer as WgpuBuffer;
    ffi.wgpun_RenderPassEncoderSetVertexBuffer(
      _handle,
      slot,
      buf.handle,
      offset,
      size ?? 0, // 0 means use entire buffer from offset
    );
  }

  /// Sets the index buffer.
  @override
  void setIndexBuffer(
    GpuBuffer buffer,
    GpuIndexFormat format, {
    int offset = 0,
    int? size,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    if (offset < 0) throw ArgumentError('offset must be non-negative');
    if (size != null && size <= 0) throw ArgumentError('size must be positive');
    final buf = buffer as WgpuBuffer;
    ffi.wgpun_RenderPassEncoderSetIndexBuffer(
      _handle,
      buf.handle,
      format.ffiValue,
      offset,
      size ?? 0,
    );
  }

  /// Draws primitives.
  @override
  void draw({
    required int vertexCount,
    int instanceCount = 1,
    int firstVertex = 0,
    int firstInstance = 0,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    if (vertexCount <= 0) throw ArgumentError('vertexCount must be positive');
    if (instanceCount <= 0) {
      throw ArgumentError('instanceCount must be positive');
    }
    if (firstVertex < 0) {
      throw ArgumentError('firstVertex must be non-negative');
    }
    if (firstInstance < 0) {
      throw ArgumentError('firstInstance must be non-negative');
    }
    ffi.wgpun_RenderPassEncoderDraw(
      _handle,
      vertexCount,
      instanceCount,
      firstVertex,
      firstInstance,
    );
  }

  /// Draws indexed primitives.
  @override
  void drawIndexed({
    required int indexCount,
    int instanceCount = 1,
    int firstIndex = 0,
    int baseVertex = 0,
    int firstInstance = 0,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    if (indexCount <= 0) throw ArgumentError('indexCount must be positive');
    if (instanceCount <= 0) {
      throw ArgumentError('instanceCount must be positive');
    }
    if (firstIndex < 0) throw ArgumentError('firstIndex must be non-negative');
    if (firstInstance < 0) {
      throw ArgumentError('firstInstance must be non-negative');
    }
    ffi.wgpun_RenderPassEncoderDrawIndexed(
      _handle,
      indexCount,
      instanceCount,
      firstIndex,
      baseVertex,
      firstInstance,
    );
  }

  @override
  void drawIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    if (indirectOffset < 0) {
      throw ArgumentError('indirectOffset must be non-negative');
    }
    final buf = indirectBuffer as WgpuBuffer;
    if (buf.handle == 0) {
      throw ArgumentError('indirectBuffer handle is invalid (0)');
    }
    ffi.wgpun_RenderPassEncoderDrawIndirect(
      _handle,
      buf.handle,
      indirectOffset,
    );
  }

  @override
  void drawIndexedIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    if (indirectOffset < 0) {
      throw ArgumentError('indirectOffset must be non-negative');
    }
    final buf = indirectBuffer as WgpuBuffer;
    if (buf.handle == 0) {
      throw ArgumentError('indirectBuffer handle is invalid (0)');
    }
    ffi.wgpun_RenderPassEncoderDrawIndexedIndirect(
      _handle,
      buf.handle,
      indirectOffset,
    );
  }

  @override
  void beginOcclusionQuery(int queryIndex) {
    if (_ended) throw StateError('Render pass already ended');
    if (queryIndex < 0) throw ArgumentError('queryIndex must be non-negative');
    ffi.wgpun_RenderPassEncoderBeginOcclusionQuery(_handle, queryIndex);
  }

  @override
  void endOcclusionQuery() {
    if (_ended) throw StateError('Render pass already ended');
    ffi.wgpun_RenderPassEncoderEndOcclusionQuery(_handle);
  }

  @override
  void setViewport(
    double x,
    double y,
    double width,
    double height, {
    double minDepth = 0.0,
    double maxDepth = 1.0,
  }) {
    if (_ended) throw StateError('Render pass already ended');
    if (width <= 0) throw ArgumentError('viewport width must be positive');
    if (height <= 0) throw ArgumentError('viewport height must be positive');
    if (minDepth < 0 || minDepth > 1) {
      throw ArgumentError('minDepth must be in [0, 1]');
    }
    if (maxDepth < 0 || maxDepth > 1) {
      throw ArgumentError('maxDepth must be in [0, 1]');
    }
    ffi.wgpun_RenderPassEncoderSetViewport(
      _handle,
      x,
      y,
      width,
      height,
      minDepth,
      maxDepth,
    );
  }

  @override
  void setScissorRect(int x, int y, int width, int height) {
    if (_ended) throw StateError('Render pass already ended');
    if (x < 0) throw ArgumentError('scissor x must be non-negative');
    if (y < 0) throw ArgumentError('scissor y must be non-negative');
    if (width <= 0) throw ArgumentError('scissor width must be positive');
    if (height <= 0) throw ArgumentError('scissor height must be positive');
    ffi.wgpun_RenderPassEncoderSetScissorRect(
      _handle,
      x,
      y,
      width,
      height,
    );
  }

  @override
  void setBlendConstant(GpuColor color) {
    if (_ended) throw StateError('Render pass already ended');
    ffi.wgpun_RenderPassEncoderSetBlendConstant(
      _handle,
      color.r,
      color.g,
      color.b,
      color.a,
    );
  }

  @override
  void setStencilReference(int reference) {
    if (_ended) throw StateError('Render pass already ended');
    ffi.wgpun_RenderPassEncoderSetStencilReference(
      _handle,
      reference,
    );
  }

  @override
  void insertDebugMarker(String label) {
    if (_ended) throw StateError('Render pass already ended');

    using((arena) {
      final labelPtr = label.toNativeUtf8(allocator: arena);
      ffi.wgpun_RenderPassEncoderInsertDebugMarker(
        _handle,
        labelPtr.cast(),
      );
    });
  }

  @override
  void pushDebugGroup(String label) {
    if (_ended) throw StateError('Render pass already ended');

    using((arena) {
      final labelPtr = label.toNativeUtf8(allocator: arena);
      ffi.wgpun_RenderPassEncoderPushDebugGroup(
        _handle,
        labelPtr.cast(),
      );
    });
  }

  @override
  void popDebugGroup() {
    if (_ended) throw StateError('Render pass already ended');
    ffi.wgpun_RenderPassEncoderPopDebugGroup(_handle);
  }

  @override
  void executeBundles(List<GpuRenderBundle> bundles) {
    if (_ended) throw StateError('Render pass already ended');
    if (bundles.isEmpty) return;
    using((arena) {
      final handlesPtr = arena<Uint64>(bundles.length);
      for (var i = 0; i < bundles.length; i++) {
        handlesPtr[i] = (bundles[i] as WgpuRenderBundle).handle;
      }
      ffi.wgpun_RenderPassExecuteBundles(
        _handle,
        handlesPtr,
        bundles.length,
      );
    });
  }

  @override
  void end() {
    if (_ended) throw StateError('Render pass already ended');

    final newEncoderHandle = ffi.wgpun_RenderPassEncoderEnd(_handle);
    _ended = true;

    if (newEncoderHandle == 0) {
      throw StateError('Failed to end render pass: ${wgpuLastError()}');
    }

    _encoder._onRenderPassEnd(newEncoderHandle);
  }
}

/// A recorded command buffer ready for submission.
class WgpuCommandBuffer implements GpuCommandBuffer {
  @override
  String label;
  final int _handle;

  WgpuCommandBuffer.internal(this._handle, {this.label = ''});

  /// Native handle. Use with care.
  int get handle => _handle;
}

/// A compute pass encoder for recording compute dispatch commands.
class WgpuComputePassEncoder implements GpuComputePassEncoder {
  @override
  String label;
  final int _handle;
  final WgpuCommandEncoder _encoder;
  bool _ended = false;

  WgpuComputePassEncoder._(this._handle, this._encoder, {this.label = ''});

  /// Native handle. Use with care.
  int get handle => _handle;

  @override
  void setPipeline(GpuComputePipeline pipeline) {
    if (_ended) throw StateError('Compute pass already ended');
    ffi.wgpun_ComputePassEncoderSetPipeline(
      _handle,
      (pipeline as WgpuComputePipeline).handle,
    );
  }

  @override
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  }) {
    if (_ended) throw StateError('Compute pass already ended');
    final bg = (bindGroup as WgpuBindGroup).handle;
    if (dynamicOffsets != null && dynamicOffsets.isNotEmpty) {
      using((arena) {
        final offsetsPtr = arena<Uint32>(dynamicOffsets.length);
        for (var i = 0; i < dynamicOffsets.length; i++) {
          offsetsPtr[i] = dynamicOffsets[i];
        }
        ffi.wgpun_ComputePassEncoderSetBindGroup(
          _handle,
          index,
          bg,
          offsetsPtr,
          dynamicOffsets.length,
        );
      });
    } else {
      ffi.wgpun_ComputePassEncoderSetBindGroup(
        _handle,
        index,
        bg,
        nullptr,
        0,
      );
    }
  }

  @override
  void dispatchWorkgroups(int x, [int y = 1, int z = 1]) {
    if (_ended) throw StateError('Compute pass already ended');
    if (x <= 0) throw ArgumentError('x must be positive');
    if (y <= 0) throw ArgumentError('y must be positive');
    if (z <= 0) throw ArgumentError('z must be positive');
    ffi.wgpun_ComputePassEncoderDispatchWorkgroups(_handle, x, y, z);
  }

  @override
  void dispatchWorkgroupsIndirect(GpuBuffer buffer, {int offset = 0}) {
    if (_ended) throw StateError('Compute pass already ended');
    if (offset < 0) throw ArgumentError('offset must be non-negative');
    final buf = buffer as WgpuBuffer;
    if (buf.handle == 0) throw ArgumentError('buffer handle is invalid (0)');
    ffi.wgpun_ComputePassEncoderDispatchWorkgroupsIndirect(
      _handle,
      buf.handle,
      offset,
    );
  }

  @override
  void insertDebugMarker(String label) {
    if (_ended) throw StateError('Compute pass already ended');

    using((arena) {
      final labelPtr = label.toNativeUtf8(allocator: arena);
      ffi.wgpun_ComputePassEncoderInsertDebugMarker(
        _handle,
        labelPtr.cast(),
      );
    });
  }

  @override
  void pushDebugGroup(String label) {
    if (_ended) throw StateError('Compute pass already ended');

    using((arena) {
      final labelPtr = label.toNativeUtf8(allocator: arena);
      ffi.wgpun_ComputePassEncoderPushDebugGroup(
        _handle,
        labelPtr.cast(),
      );
    });
  }

  @override
  void popDebugGroup() {
    if (_ended) throw StateError('Compute pass already ended');
    ffi.wgpun_ComputePassEncoderPopDebugGroup(_handle);
  }

  @override
  void end() {
    if (_ended) throw StateError('Compute pass already ended');

    final newEncoderHandle = ffi.wgpun_ComputePassEncoderEnd(_handle);
    _ended = true;

    if (newEncoderHandle == 0) {
      throw StateError('Failed to end compute pass: ${wgpuLastError()}');
    }

    _encoder._onComputePassEnd(newEncoderHandle);
  }
}

// =============================================================================
// RENDER BUNDLES
// =============================================================================

/// A pre-recorded bundle of render commands.
class WgpuRenderBundle extends WgpuNativeResource implements GpuRenderBundle {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_RenderBundleRelease_p,
    ),
  );

  @override
  String label;

  WgpuRenderBundle.internal(int handle, {this.label = ''})
    : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_RenderBundleRelease(handle);
}

/// Encoder for recording render bundle commands.
class WgpuRenderBundleEncoder implements GpuRenderBundleEncoder {
  @override
  String label;
  final int _handle;
  bool _ended = false;

  WgpuRenderBundleEncoder.internal(this._handle, {this.label = ''});

  /// Native handle. Use with care.
  int get handle => _handle;

  @override
  void setPipeline(GpuRenderPipeline pipeline) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    ffi.wgpun_RenderBundleEncoderSetPipeline(
      _handle,
      (pipeline as WgpuRenderPipeline).handle,
    );
  }

  @override
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  }) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    final bg = (bindGroup as WgpuBindGroup).handle;
    if (dynamicOffsets != null && dynamicOffsets.isNotEmpty) {
      using((arena) {
        final offsetsPtr = arena<Uint32>(dynamicOffsets.length);
        for (var i = 0; i < dynamicOffsets.length; i++) {
          offsetsPtr[i] = dynamicOffsets[i];
        }
        ffi.wgpun_RenderBundleEncoderSetBindGroup(
          _handle,
          index,
          bg,
          offsetsPtr,
          dynamicOffsets.length,
        );
      });
    } else {
      ffi.wgpun_RenderBundleEncoderSetBindGroup(
        _handle,
        index,
        bg,
        nullptr,
        0,
      );
    }
  }

  @override
  void setVertexBuffer(
    int slot,
    GpuBuffer? buffer, {
    int offset = 0,
    int? size,
  }) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    if (slot < 0) throw ArgumentError('slot must be non-negative');
    if (buffer == null) {
      ffi.wgpun_RenderBundleEncoderSetVertexBuffer(
        _handle,
        slot,
        0,
        0,
        0,
      );
      return;
    }
    if (offset < 0) throw ArgumentError('offset must be non-negative');
    if (size != null && size <= 0) throw ArgumentError('size must be positive');
    final buf = buffer as WgpuBuffer;
    ffi.wgpun_RenderBundleEncoderSetVertexBuffer(
      _handle,
      slot,
      buf.handle,
      offset,
      size ?? 0,
    );
  }

  @override
  void setIndexBuffer(
    GpuBuffer buffer,
    GpuIndexFormat format, {
    int offset = 0,
    int? size,
  }) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    if (offset < 0) throw ArgumentError('offset must be non-negative');
    if (size != null && size <= 0) throw ArgumentError('size must be positive');
    final buf = buffer as WgpuBuffer;
    ffi.wgpun_RenderBundleEncoderSetIndexBuffer(
      _handle,
      buf.handle,
      format.ffiValue,
      offset,
      size ?? 0,
    );
  }

  @override
  void draw({
    required int vertexCount,
    int instanceCount = 1,
    int firstVertex = 0,
    int firstInstance = 0,
  }) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    if (vertexCount <= 0) throw ArgumentError('vertexCount must be positive');
    if (instanceCount <= 0) {
      throw ArgumentError('instanceCount must be positive');
    }
    ffi.wgpun_RenderBundleEncoderDraw(
      _handle,
      vertexCount,
      instanceCount,
      firstVertex,
      firstInstance,
    );
  }

  @override
  void drawIndexed({
    required int indexCount,
    int instanceCount = 1,
    int firstIndex = 0,
    int baseVertex = 0,
    int firstInstance = 0,
  }) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    if (indexCount <= 0) throw ArgumentError('indexCount must be positive');
    if (instanceCount <= 0) {
      throw ArgumentError('instanceCount must be positive');
    }
    ffi.wgpun_RenderBundleEncoderDrawIndexed(
      _handle,
      indexCount,
      instanceCount,
      firstIndex,
      baseVertex,
      firstInstance,
    );
  }

  @override
  void drawIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
  }) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    final buf = indirectBuffer as WgpuBuffer;
    if (buf.handle == 0) {
      throw ArgumentError('indirectBuffer handle is invalid (0)');
    }
    ffi.wgpun_RenderBundleEncoderDrawIndirect(
      _handle,
      buf.handle,
      indirectOffset,
    );
  }

  @override
  void drawIndexedIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
  }) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    final buf = indirectBuffer as WgpuBuffer;
    if (buf.handle == 0) {
      throw ArgumentError('indirectBuffer handle is invalid (0)');
    }
    ffi.wgpun_RenderBundleEncoderDrawIndexedIndirect(
      _handle,
      buf.handle,
      indirectOffset,
    );
  }

  @override
  void insertDebugMarker(String label) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    // RenderBundleEncoder doesn't support debug markers in wgpu.
    // Silently ignore to match the interface contract.
  }

  @override
  void pushDebugGroup(String label) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    // RenderBundleEncoder doesn't support debug groups in wgpu.
  }

  @override
  void popDebugGroup() {
    if (_ended) throw StateError('Render bundle encoder already finished');
    // RenderBundleEncoder doesn't support debug groups in wgpu.
  }

  @override
  WgpuRenderBundle finish({String label = ''}) {
    if (_ended) throw StateError('Render bundle encoder already finished');
    _ended = true;

    final bundleHandle = using((arena) {
      final labelPtr = label.isEmpty
          ? nullptr
          : label.toNativeUtf8(allocator: arena).cast<Char>();
      return ffi.wgpun_RenderBundleEncoderFinish(_handle, labelPtr);
    });

    if (bundleHandle == 0) {
      throw StateError(
        'Failed to finish render bundle encoder: ${wgpuLastError()}',
      );
    }

    return WgpuRenderBundle.internal(bundleHandle, label: label);
  }
}

// =============================================================================
// WGPU-NATIVE EXTENSIONS (not in WebGPU spec)
// =============================================================================

/// wgpu extension: writeTimestamp on command encoder.
extension WgpuCommandEncoderTimestamp on GpuCommandEncoder {
  /// Writes a GPU timestamp to a query set (wgpu only).
  ///
  /// Can only be called between passes (not inside a render/compute pass).
  void writeTimestamp(GpuQuerySet querySet, int queryIndex) {
    final self = this as WgpuCommandEncoder;
    if (self._finished) {
      throw StateError('Command encoder already finished');
    }
    if (self._inRenderPass || self._inComputePass) {
      throw StateError('Cannot write timestamp while in a pass');
    }
    ffi.wgpun_CommandEncoderWriteTimestamp(
      self._handle,
      (querySet as WgpuQuerySet).handle,
      queryIndex,
    );
  }
}

/// wgpu extension: multi-draw on render pass encoder.
extension WgpuRenderPassMultiDraw on GpuRenderPassEncoder {
  /// Multi-draw indexed indirect (wgpu only).
  void multiDrawIndexedIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
    required int count,
  }) {
    final self = this as WgpuRenderPassEncoder;
    if (self._ended) throw StateError('Render pass already ended');
    final buf = indirectBuffer as WgpuBuffer;
    ffi.wgpun_RenderPassEncoderMultiDrawIndexedIndirect(
      self._handle,
      buf.handle,
      indirectOffset,
      count,
    );
  }
}

/// wgpu extension: immediates (push constants) on render pass.
extension WgpuRenderPassImmediates on GpuRenderPassEncoder {
  /// Sets immediate (push constant) data on the render pass.
  ///
  /// [offset] is the byte offset into the immediate data block.
  /// [data] is the raw bytes to write (e.g., a Float32List or Uint8List).
  void setImmediates(int offset, TypedData data) {
    final self = this as WgpuRenderPassEncoder;
    if (self._ended) throw StateError('Render pass already ended');
    final byteData = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    using((arena) {
      final ptr = arena<Uint8>(byteData.length);
      ptr.asTypedList(byteData.length).setAll(0, byteData);
      ffi.wgpun_RenderPassEncoderSetImmediates(
        self._handle,
        offset,
        ptr,
        byteData.length,
      );
    });
  }
}

/// wgpu extension: immediates (push constants) on compute pass.
extension WgpuComputePassImmediates on GpuComputePassEncoder {
  /// Sets immediate (push constant) data on the compute pass.
  ///
  /// [offset] is the byte offset into the immediate data block.
  /// [data] is the raw bytes to write (e.g., a Float32List or Uint8List).
  void setImmediates(int offset, TypedData data) {
    final self = this as WgpuComputePassEncoder;
    if (self._ended) throw StateError('Compute pass already ended');
    final byteData = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    using((arena) {
      final ptr = arena<Uint8>(byteData.length);
      ptr.asTypedList(byteData.length).setAll(0, byteData);
      ffi.wgpun_ComputePassEncoderSetImmediates(
        self._handle,
        offset,
        ptr,
        byteData.length,
      );
    });
  }
}

/// wgpu extension: immediates (push constants) on render bundle encoder.
extension WgpuRenderBundleEncoderImmediates on GpuRenderBundleEncoder {
  /// Sets immediate (push constant) data on the render bundle encoder.
  ///
  /// [offset] is the byte offset into the immediate data block.
  /// [data] is the raw bytes to write (e.g., a Float32List or Uint8List).
  void setImmediates(int offset, TypedData data) {
    final self = this as WgpuRenderBundleEncoder;
    if (self._ended) {
      throw StateError('Render bundle encoder already finished');
    }
    final byteData = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    using((arena) {
      final ptr = arena<Uint8>(byteData.length);
      ptr.asTypedList(byteData.length).setAll(0, byteData);
      ffi.wgpun_RenderBundleEncoderSetImmediates(
        self._handle,
        offset,
        ptr,
        byteData.length,
      );
    });
  }
}
