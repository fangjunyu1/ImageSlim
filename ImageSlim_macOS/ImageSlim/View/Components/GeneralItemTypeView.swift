//
//  SettingsItemTypeView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/31.
//

import SwiftUI

private enum SettingsCleanStatus {
    case clean
    case loading
    case success
    case error
}

struct GeneralItemTypeView: View {
    @Environment(\.openURL) var openURL
    @State var saveName: String = AppStorage.shared.saveName
    @State private var cleanStatus = SettingsCleanStatus.clean
    let type: GeneralItemType
    // 临时文件大小
    @State private var tempStorageUsed = FileUtils.calculateTempFolderSize()
    
    var body: some View {
        switch type {
        case .PickerIcon(let binding):
            Picker("显示图标", selection: binding) {
                Text("Always show").tag(true)
                Text("Off").tag(false)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize() // 不随容器拉伸
            
        case .CompressionSlider(let binding):
            CompressionSliderView(value: binding)
            
        case .PickerPreview(let binding):
            Picker("预览方式", selection: binding) {
                Text("Window preview").tag(PreviewMode.window)
                Text("Use Quick Look to preview").tag(PreviewMode.quickLook)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize() // 不随容器拉伸
            
        case .SaveLocationButton:
            Button(action: {
                FileUtils.createSaveLocation(saveName:$saveName)    // 选择保存目录 - 安全书签
            }, label: {
                Text(LocalizedStringKey(saveName))
            })
            .buttonStyle(.plain)
            .modifier(HoverModifier())
            .onAppear {
                FileUtils.refreshSaveName(saveName: $saveName)  // 显示视图时，修改目录名称
            }
            
        case .ToggleThirdParty(let pngquant, let gifsicle, let cwebp):
            Text("Pngquant")
                .foregroundColor(.gray)
            Toggle("Pngquant",isOn: pngquant)
                .labelsHidden()
            
            Text("Gifsicle")
                .foregroundColor(.gray)
            Toggle("Gifsicle",isOn: gifsicle)
                .labelsHidden()
            
            Text("Cwebp")
                .foregroundColor(.gray)
            Toggle("Cwebp",isOn: cwebp)
                .labelsHidden()
            
        case .Toggle(let string, let binding):
            Toggle(string,isOn: binding)
                .labelsHidden()
            
        case .Link(let string, let url):
            Text(LocalizedStringKey(string))
                .foregroundColor(.gray)
                .onTapGesture {
                    if let url = URL(string: url) {
                        openURL(url)
                    }
                }
                .modifier(HoverModifier())
            
        case .SendEmail(let string):
            Text(LocalizedStringKey(string))
                .foregroundColor(.gray)
                .onTapGesture {
                    FileUtils.sendEmail()
                }
                .modifier(HoverModifier())
            
        case .Thanks(let tuple):
            HStack(spacing:0) {
                ForEach(tuple.indices, id:\.self) { index in
                    Text(tuple[index].0)
                        .onTapGesture {
                            if let url = URL(string: tuple[index].1) {
                                openURL(url)
                            }
                        }
                        .modifier(HoverModifier())
                    if index != tuple.count - 1 {
                        Text(",")
                    }
                }
                .foregroundColor(.gray)
            }
            
        case .TempStorageUsed:
            Button(action: {
                let url = FileManager.default.temporaryDirectory
                NSWorkspace.shared.open(url)    // 打开临时文件夹链接
            }, label: {
                Text("\(FileUtils.TranslateSize(fileSize: tempStorageUsed))")
            })
            .buttonStyle(.plain)
            .modifier(HoverModifier())
            
            Button(action: {
                handleCleanAction()
            }, label: {
                switch cleanStatus {
                case .clean:
                    Image(systemName: "trash")
                case .loading:
                    ProgressView()
                        .controlSize(.mini)
                case .success:
                    Image(systemName: "checkmark")
                case .error:
                    Image(systemName: "xmark")
                }
            })
            .disabled(cleanStatus == .loading)
            
        case .Int(let int):
            Text("\(int)")
                .foregroundColor(.gray)
            
        case .Int64(let int):
            Text("\(int)")
                .foregroundColor(.gray)
            
        case .IntSize(let int):
            Text("\(FileUtils.TranslateSize(fileSize: Int(int)))")
                .foregroundColor(.gray)
            
        case .Double(let double):
            Text(double.formatted(.percent))
                .foregroundColor(.gray)
            
        case .Date(let date):
            if let date = date {
                Text("\(date)")
                    .foregroundColor(.gray)
            } else {
                Text("--")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func handleCleanAction() {
        
        guard cleanStatus == .clean else { return }
        // 修改清理按钮的状态
        cleanStatus = .loading
        
        Task {
            // 清空当前压缩/转换的图片列表，防止清理临时文件后，图片下载/转换文件失效
            ImageArrayViewModel.shared.cancelAllTasks()
            
            do {
                // 执行清理
                let result = try await FileUtils.cleanTempFolder()
                
                print("清理完成：删除 \(result.deletedFiles) 个文件，释放 \(FileUtils.TranslateSize(fileSize: result.deletedSize))")
                
                if result.failedFiles > 0 {
                    print("警告: \(result.failedFiles) 个文件删除失败")
                }
                
                // 显示成功状态
                cleanStatus = .success
            } catch {
                print("清理失败: \(error.localizedDescription)")
                cleanStatus = .error
            }
            
            // 延迟后重置状态
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // 重新计算临时文件大小
            tempStorageUsed = FileUtils.calculateTempFolderSize()
            
            // 重置状态
            cleanStatus = .clean
        }
    }
}

// MARK: - 独立的压缩率滑块组件
struct CompressionSliderView: View {
    @Binding var value: Double
    
    private var qualityLabel: String {
        switch quantize(value) {
        case 1.0: return "Lossless"
        case 0.75: return "High Quality"
        case 0.5: return "Balanced"
        case 0.25: return "Low Quality"
        case 0.0: return "Lowest"
        default: return "\(Int(value * 100))%"
        }
    }
    
    func quantize(_ value: Double) -> Double {
        round(value * 4) / 4
    }
    
    var body: some View {
        Text(LocalizedStringKey(qualityLabel))
        Slider(
            value: Binding(
                get: { quantize(value) },
                set: { newValue in
                    value = round(newValue * 4) / 4
                }
            ),
            in: 0...1,
            step: 0.25
        )
        .frame(width: 100)
    }
}
