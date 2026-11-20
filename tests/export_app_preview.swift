import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
import CoreMedia

// 仅转码真实录屏：拒绝覆盖，不删除任何文件；明确写入H.264并校验输出。
func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("错误：" + message + "\n").utf8))
    exit(1)
}
func ensureNew(_ url: URL) {
    if FileManager.default.fileExists(atPath: url.path) || (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
        fail("拒绝覆盖已有路径：\(url.path)")
    }
}
func fourCC(_ value: FourCharCode) -> String {
    String(bytes: [UInt8((value >> 24) & 255), UInt8((value >> 16) & 255), UInt8((value >> 8) & 255), UInt8(value & 255)], encoding: .ascii) ?? "unknown"
}

let args = CommandLine.arguments
if args.count != 7 {
    fail("用法：xcrun swift tests/export_app_preview.swift 输入.mov 新输出.mp4 起点秒 时长秒 新关键帧目录 新校验.json")
}
let input = URL(fileURLWithPath: args[1]).standardizedFileURL.resolvingSymlinksInPath()
let output = URL(fileURLWithPath: args[2]).standardizedFileURL
let frames = URL(fileURLWithPath: args[5]).standardizedFileURL
let report = URL(fileURLWithPath: args[6]).standardizedFileURL
ensureNew(output)
ensureNew(frames)
ensureNew(report)
guard input != output.resolvingSymlinksInPath(), FileManager.default.fileExists(atPath: input.path),
      let start = Double(args[3]), start.isFinite, start >= 0,
      let duration = Double(args[4]), duration.isFinite, duration >= 15, duration <= 30 else {
    fail("输入必须存在且不同于输出；起点非负，时长必须15–30秒")
}
let asset = AVURLAsset(url: input)
guard let track = asset.tracks(withMediaType: .video).first else { fail("输入缺少视频轨") }
let inputDuration = CMTimeGetSeconds(asset.duration)
guard start + duration <= inputDuration + 0.001 else { fail("裁切范围超过原始录屏时长\(inputDuration)") }
let natural = track.naturalSize
let originalRect = CGRect(origin: .zero, size: natural).applying(track.preferredTransform)
let displaySize = CGSize(width: abs(originalRect.width), height: abs(originalRect.height))
guard displaySize.width > displaySize.height else { fail("要求横屏真实录屏，不自动旋转伪装方向") }

let composition = AVMutableComposition()
guard let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
    fail("无法创建视频合成轨")
}
let range = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600),
                        duration: CMTime(seconds: duration, preferredTimescale: 600))
do { try compTrack.insertTimeRange(range, of: track, at: .zero) } catch { fail("读取裁切范围：\(error)") }
let renderSize = CGSize(width: 1920, height: 886)
let videoComposition = AVMutableVideoComposition()
videoComposition.renderSize = renderSize
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
instruction.backgroundColor = CGColor(gray: 0, alpha: 1)
let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
let scale = min(renderSize.width / displaySize.width, renderSize.height / displaySize.height)
var transform = track.preferredTransform
transform = transform.concatenating(CGAffineTransform(translationX: -originalRect.minX, y: -originalRect.minY))
transform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
transform = transform.concatenating(CGAffineTransform(translationX: (renderSize.width - displaySize.width * scale) / 2,
                                                     y: (renderSize.height - displaySize.height * scale) / 2))
layer.setTransform(transform, at: .zero)
instruction.layerInstructions = [layer]
videoComposition.instructions = [instruction]

let reader: AVAssetReader
let writer: AVAssetWriter
do {
    reader = try AVAssetReader(asset: composition)
    writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
} catch { fail("创建转码管线：\(error)") }
let readerOutput = AVAssetReaderVideoCompositionOutput(videoTracks: [compTrack],
    videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
readerOutput.videoComposition = videoComposition
readerOutput.alwaysCopiesSampleData = false
guard reader.canAdd(readerOutput) else { fail("无法加入视频读取轨") }
reader.add(readerOutput)
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: 1920,
    AVVideoHeightKey: 886,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 11_000_000,
        AVVideoExpectedSourceFrameRateKey: 30,
        AVVideoMaxKeyFrameIntervalKey: 30,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
        AVVideoAllowFrameReorderingKey: false
    ],
    AVVideoColorPropertiesKey: [
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
    ]
]
guard writer.canApply(outputSettings: settings, forMediaType: .video) else { fail("编码器不支持要求的H.264参数") }
let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
writerInput.expectsMediaDataInRealTime = false
guard writer.canAdd(writerInput) else { fail("无法加入视频写入轨") }
writer.add(writerInput)
writer.shouldOptimizeForNetworkUse = true
guard writer.startWriting(), reader.startReading() else { fail("无法开始转码：\(String(describing: writer.error)) / \(String(describing: reader.error))") }
writer.startSession(atSourceTime: .zero)
let finished = DispatchSemaphore(value: 0)
let queue = DispatchQueue(label: "appstore.preview.encode")
var frameCount = 0
var pipelineError: String?
var didFinish = false
writerInput.requestMediaDataWhenReady(on: queue) {
    guard !didFinish else { return }
    while writerInput.isReadyForMoreMediaData {
        if let sample = readerOutput.copyNextSampleBuffer() {
            guard writerInput.append(sample) else {
                pipelineError = "写入帧失败：\(String(describing: writer.error))"
                reader.cancelReading()
                writer.cancelWriting()
                didFinish = true
                finished.signal()
                return
            }
            frameCount += 1
        } else {
            didFinish = true
            writerInput.markAsFinished()
            if reader.status != .completed {
                pipelineError = "读取未完成：\(String(describing: reader.error))"
                writer.cancelWriting()
                finished.signal()
            } else {
                writer.endSession(atSourceTime: composition.duration)
                writer.finishWriting { finished.signal() }
            }
            return
        }
    }
}
guard finished.wait(timeout: .now() + 600) == .success else {
    reader.cancelReading()
    writer.cancelWriting()
    fail("转码超时，保留已有证据，不删除输出")
}
if let error = pipelineError { fail(error) }
guard writer.status == .completed else { fail("转码失败：\(String(describing: writer.error))") }

let exported = AVURLAsset(url: output)
guard let exportedTrack = exported.tracks(withMediaType: .video).first,
      let rawFormat = exportedTrack.formatDescriptions.first else { fail("输出缺少可验证视频格式") }
guard CFGetTypeID(rawFormat as CFTypeRef) == CMFormatDescriptionGetTypeID() else { fail("视频格式描述类型无效") }
let format = rawFormat as! CMFormatDescription
let codec = CMFormatDescriptionGetMediaSubType(format)
let dimensions = CMVideoFormatDescriptionGetDimensions(format)
let actualDuration = CMTimeGetSeconds(exported.duration)
let audioCount = exported.tracks(withMediaType: .audio).count
let size = (try? FileManager.default.attributesOfItem(atPath: output.path)[.size] as? NSNumber)?.int64Value ?? 0
guard let extensionValues = CMFormatDescriptionGetExtensions(format) else { fail("输出缺少编码扩展描述") }
let extensions = extensionValues as NSDictionary
let atoms = extensions.object(forKey: kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms) as? NSDictionary
let avcC = atoms?.object(forKey: "avcC") as? Data
let profile = avcC.flatMap { $0.count > 3 ? Int($0[1]) : nil } ?? -1
let level = avcC.flatMap { $0.count > 3 ? Int($0[3]) : nil } ?? -1
guard codec == kCMVideoCodecType_H264, dimensions.width == 1920, dimensions.height == 886,
      actualDuration >= 15, actualDuration <= 30.001, abs(actualDuration - duration) < 0.1,
      exportedTrack.nominalFrameRate > 0, exportedTrack.nominalFrameRate <= 30.01,
      profile == 100, level > 0, level <= 40, audioCount == 0, size > 0, size < 500_000_000 else {
    fail("输出规格验证不通过：codec=\(fourCC(codec)), size=\(dimensions), fps=\(exportedTrack.nominalFrameRate), duration=\(actualDuration), profile=\(profile), level=\(level), audio=\(audioCount)")
}

do { try FileManager.default.createDirectory(at: frames, withIntermediateDirectories: false) }
catch { fail("创建关键帧目录：\(error)") }
let generator = AVAssetImageGenerator(asset: exported)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
var frameReports: [[String: Any]] = []
for second in [0.0, 3.0, 8.0, 13.0, 18.0, 23.0, duration - 0.1].filter({ $0 < duration }) {
    let url = frames.appendingPathComponent(String(format: "frame-%05.1fs.png", second))
    ensureNew(url)
    do {
        var actual = CMTime.zero
        let image = try generator.copyCGImage(at: CMTime(seconds: second, preferredTimescale: 600), actualTime: &actual)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { fail("无法创建PNG") }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { fail("写入关键帧失败") }
        frameReports.append(["path": url.path, "requestedSecond": second, "actualSecond": CMTimeGetSeconds(actual), "manualReview": "pending"])
    } catch { fail("提取关键帧：\(error)") }
}
let metadata: [String: Any] = [
    "input": input.path, "output": output.path, "sourceDuration": inputDuration,
    "sourcePixels": [displaySize.width, displaySize.height], "trimStart": start, "trimDuration": duration,
    "duration": actualDuration, "pixels": [dimensions.width, dimensions.height], "codec": fourCC(codec),
    "profile": profile, "level": level, "fps": exportedTrack.nominalFrameRate, "framesEncoded": frameCount,
    "targetBitRate": 11_000_000, "estimatedDataRate": exportedTrack.estimatedDataRate,
    "audioTrackCount": audioCount, "fileBytes": size, "writerStatus": writer.status.rawValue,
    "resizing": "等比完整保留画面，居中适配1920×886；不裁切、不叠字、不合成假画面",
    "keyframes": frameReports, "automatedPassed": true, "manualReview": "pending"
]
do {
    let data = try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: report, options: .withoutOverwriting)
    print(String(decoding: data, as: UTF8.self))
} catch { fail("保存校验报告：\(error)") }
exit(0)
