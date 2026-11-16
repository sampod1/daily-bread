// Re-encodes the 4K interview master to a web-sized 1080p H.264/AAC MP4
// at a fixed bitrate, with the moov atom up front so it streams on load.
// Usage: swift tools/encode.swift <source> <output.mp4> [videoMbps]
import AVFoundation
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else { print("usage: encode <src> <out> [mbps]"); exit(2) }
let src = URL(fileURLWithPath: args[1])
let out = URL(fileURLWithPath: args[2])
let mbps = args.count > 3 ? Double(args[3])! : 4.5
try? FileManager.default.removeItem(at: out)

let asset = AVURLAsset(url: src)

Task {
    do {
        let vTrack = try await asset.loadTracks(withMediaType: .video).first!
        let aTrack = try await asset.loadTracks(withMediaType: .audio).first

        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: out, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true

        let vOut = AVAssetReaderVideoCompositionOutput(
            videoTracks: [vTrack],
            videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
        let comp = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: asset)
        comp.renderSize = CGSize(width: 1920, height: 1080)
        let natural = try await vTrack.load(.naturalSize)
        let instr = AVMutableVideoCompositionInstruction()
        instr.timeRange = CMTimeRange(start: .zero, duration: try await asset.load(.duration))
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack)
        layer.setTransform(CGAffineTransform(scaleX: 1920 / natural.width, y: 1080 / natural.height), at: .zero)
        instr.layerInstructions = [layer]
        comp.instructions = [instr]
        vOut.videoComposition = comp
        reader.add(vOut)

        let vIn = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: Int(mbps * 1_000_000),
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoMaxKeyFrameIntervalDurationKey: 2,
            ],
        ])
        vIn.expectsMediaDataInRealTime = false
        writer.add(vIn)

        var aOut: AVAssetReaderTrackOutput?
        var aIn: AVAssetWriterInput?
        if let aTrack {
            let o = AVAssetReaderTrackOutput(track: aTrack, outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ])
            reader.add(o)
            let i = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 48_000,
                AVEncoderBitRateKey: 160_000,
            ])
            i.expectsMediaDataInRealTime = false
            writer.add(i)
            aOut = o; aIn = i
        }

        guard reader.startReading() else { throw reader.error! }
        guard writer.startWriting() else { throw writer.error! }
        writer.startSession(atSourceTime: .zero)

        let group = DispatchGroup()
        func pump(_ input: AVAssetWriterInput, _ output: AVAssetReaderOutput, _ label: String) {
            group.enter()
            input.requestMediaDataWhenReady(on: DispatchQueue(label: label)) {
                while input.isReadyForMoreMediaData {
                    if let buf = output.copyNextSampleBuffer() {
                        if !input.append(buf) { input.markAsFinished(); group.leave(); return }
                    } else {
                        input.markAsFinished(); group.leave(); return
                    }
                }
            }
        }
        pump(vIn, vOut, "video")
        if let aIn, let aOut { pump(aIn, aOut, "audio") }

        group.notify(queue: .main) {
            writer.finishWriting {
                if reader.status == .failed { print("reader failed: \(String(describing: reader.error))"); exit(1) }
                if writer.status != .completed { print("writer failed: \(String(describing: writer.error))"); exit(1) }
                print("done")
                exit(0)
            }
        }
    } catch {
        print("error: \(error)")
        exit(1)
    }
}

dispatchMain()
