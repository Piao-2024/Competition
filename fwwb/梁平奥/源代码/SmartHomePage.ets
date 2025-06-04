// pages/SmartHomepage.ets
import router from '@ohos.router';


// 定义设备状态变更的接口
interface DeviceStatusChange {
  deviceId: string;
  newStatus: boolean;
}

// 定义设备信息类型
class DeviceInfo {
  id: string;
  name: string;
  iconName: string;
  status: boolean;
  power: number;
  lastStatus: boolean; // 记忆上次状态

  constructor(id: string, name: string, iconName: string, status: boolean, power: number) {
    this.id = id;
    this.name = name;
    this.iconName = iconName;
    this.status = status;
    this.power = power;
    this.lastStatus = status; // 初始化上次状态
  }
}

// 定义路由参数类型
interface RouteParams {
  deviceId: string;
  deviceName: string;
  deviceStatus: boolean;
  devicePower: number;
  isNightMode?: boolean;
  isCoolMode?: boolean; // 添加夜间模式字段
}

interface EnhancedDeviceStatusChange {
  deviceId: string;
  newStatus: boolean;
  timestamp: number; // 添加时间戳字段
}

@Entry
@Component
struct SmartHomePage {
  @State temperature: number = 24;
  @State humidity: number = 65;
  @State isNightMode: boolean = false;
  @State isCoolMode: boolean = false;
  @State showModeDialog: boolean = false;
  @State dialogOpacity: number = 0;
  @State refreshCounter: number = 0; // 用于强制刷新UI
  @State currentTab: string = 'home'; // 新增：当前选中的标签页

  // 使用明确的类型定义，增加加湿器设备
  @State devices: DeviceInfo[] = [
    new DeviceInfo('bedroom-light', '卧室灯', 'light', true, 15),
    new DeviceInfo('air-conditioner', '空调', 'ac', false, 900),
    new DeviceInfo('living-room-light', '客厅灯', 'light', true, 20),
    new DeviceInfo('humidifier', '加湿器', 'humidifier', false, 30)
  ];

  private timerID: number = 0;

  private checkDeviceStatusUpdates() {
    try {
      console.info("检查设备状态更新...");
      const deviceStatusChanged = AppStorage.Get<DeviceStatusChange>('deviceStatusChanged');

      if (deviceStatusChanged) {
        console.info(`发现设备状态更新: 设备ID=${deviceStatusChanged.deviceId}, 新状态=${deviceStatusChanged.newStatus}`);

        // 查找并更新设备状态
        const device = this.devices.find(d => d.id === deviceStatusChanged.deviceId);
        if (device) {
          console.info(`找到设备: ${device.name}, 当前状态=${device.status}, 夜间模式=${this.isNightMode}`);

          // 修复：更新设备状态逻辑
          if (device.iconName === 'light' && this.isNightMode) {
            // 夜间模式下的灯，只更新lastStatus，UI上显示依然是关闭的
            device.lastStatus = deviceStatusChanged.newStatus;
            console.info(`夜间模式灯设备: 更新记忆状态为 ${device.lastStatus}`);
          } else {
            // 非夜间模式，或非灯设备，直接更新显示状态
            device.status = deviceStatusChanged.newStatus;
            // 同时更新lastStatus，保持同步
            device.lastStatus = deviceStatusChanged.newStatus;
            console.info(`更新设备状态为 ${device.status}`);
          }

          // 强制刷新UI
          this.refreshCounter++;
        } else {
          console.error(`未找到设备: ${deviceStatusChanged.deviceId}`);
        }

        // 清除状态，避免重复处理
        AppStorage.Delete('deviceStatusChanged');
      }
    } catch (error) {
      console.error(`检查设备状态更新错误: ${JSON.stringify(error)}`);
    }
  }

  onPageShow() {
    // 当页面显示时（包括初始加载和从其他页面返回）检查所有设备状态
    console.info("SmartHomePage 显示，检查所有设备状态");
    this.checkAllDevicesStatus();
  }

  aboutToAppear() {
    this.startAutoRefresh();
    // 检查所有设备状态
    this.checkAllDevicesStatus();
  }

  aboutToDisappear() {
    this.clearAutoRefresh();
  }

  private checkAllDevicesStatus() {
    // 遍历所有设备，检查是否有状态更新
    this.devices.forEach(device => {
      try {
        // 使用与设备详情页相同的键模式，并指定类型
        const statusChange = AppStorage.Get<EnhancedDeviceStatusChange>('device_' + device.id + '_status');
        if (statusChange && statusChange.timestamp) {
          console.info(`检测到设备 ${device.id} 的状态更新: 新状态=${statusChange.newStatus}`);

          // 根据模式应用状态更新
          if (device.iconName === 'light' && this.isNightMode) {
            // 夜间模式下的灯，只更新 lastStatus
            device.lastStatus = statusChange.newStatus;
          } else {
            // 非夜间模式或非灯设备，更新显示状态
            device.status = statusChange.newStatus;
            device.lastStatus = statusChange.newStatus;
          }

          // 清除此状态更新记录
          AppStorage.Delete('device_' + device.id + '_status');

          // 标记需要刷新UI
          this.refreshCounter++;
        }
      } catch (error) {
        console.error(`检查设备 ${device.id} 状态更新时出错: ${JSON.stringify(error)}`);
      }
    })
  }

  // 自动刷新逻辑
  private startAutoRefresh() {
    this.timerID = setInterval(() => {
      this.updateSensorData();
    }, 5000);
  }

  private clearAutoRefresh() {
    if (this.timerID) {
      clearInterval(this.timerID);
      this.timerID = 0;
    }
  }

  // 更新传感器数据
  private updateSensorData() {
    // 生成15-25之间的随机温度
    this.temperature = Math.floor(Math.random() * (20 - 18 + 1)) + 15;
    // 生成50-70之间的随机湿度
    this.humidity = Math.floor(Math.random() * (65 - 60 + 1)) + 50;
  }

  // 切换模式
  private switchToMode(isNight: boolean, isCool: boolean = false) {
    // 处理夜晚模式
    if (isNight !== this.isNightMode) {
      if (isNight) {
        // 切换到夜晚模式，保存当前灯的状态
        this.devices.forEach(device => {
          if (device.iconName === 'light') {
            device.lastStatus = device.status;
            device.status = false;
          }
        });
      } else {
        // 切换到默认模式，恢复灯的状态
        this.devices.forEach(device => {
          if (device.iconName === 'light') {
            device.status = device.lastStatus;
          }
        });
      }

      this.isNightMode = isNight;
      this.refreshCounter++; // 强制刷新UI
    }

    // 处理凉爽模式
    if (isCool !== this.isCoolMode) {
      console.info(`切换凉爽模式: ${isCool}`);

      // 更新空调状态，增加详细日志
      let acCount = 0;
      this.devices.forEach(device => {
        if (device.iconName === 'ac') {
          console.info(`找到空调设备: ${device.id}, 当前状态: ${device.status}, 将设置为: ${isCool}`);
          device.status = isCool; // 凉爽模式下打开空调，否则关闭
          device.lastStatus = isCool; // 同时更新记忆状态，确保一致性
          acCount++;
        }
      });

      console.info(`共找到 ${acCount} 台空调设备`);

      this.isCoolMode = isCool;
      // 如果进入凉爽模式，确保夜晚模式被关闭
      if (isCool && this.isNightMode) {
        console.info('凉爽模式开启，关闭夜晚模式');
        this.isNightMode = false;

        // 恢复灯的状态
        this.devices.forEach(device => {
          if (device.iconName === 'light') {
            device.status = device.lastStatus;
          }
        });
      }
      this.refreshCounter++;

    }

    // 关闭对话框
    this.closeModeDialog();
  }

  // 显示模式对话框
  private showModeSelectionDialog() {
    this.showModeDialog = true;
    // 添加动画效果
    animateTo({ duration: 250 }, () => {
      this.dialogOpacity = 0.5;
    });
  }

  // 关闭对话框
  private closeModeDialog() {
    // 添加动画效果
    animateTo({ duration: 250 }, () => {
      this.dialogOpacity = 0;
    });

    // 等待动画完成后隐藏对话框
    setTimeout(() => {
      this.showModeDialog = false;
    }, 250);
  }

  build() {
    Column() {
      // 主要内容区域
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          // 标题栏
          Row() {
            Text('我的家')
              .fontSize(35)
              .fontWeight(FontWeight.Bold)

            Row() {
              // 添加家庭控制中心按钮
              Button({ type: ButtonType.Normal }) {
                Row() {
                  Image($r('app.media.home_control'))
                    .width(20)
                    .height(24)
                    .margin({ right: 3 })
                  Text('家庭控制中心')
                    .fontSize(14)
                }
              }
              .height(40)
              .backgroundColor('#4e87ee')
              .borderRadius(20)
              .onClick(() => {
                try {
                  // 将所有设备信息传递给HomeControl页面
                  router.pushUrl({
                    url: 'pages/HomeControl',
                    params: {
                      devices: this.devices
                    }
                  });
                } catch (error) {
                  console.error(`导航错误: ${JSON.stringify(error)}`);
                }
              })

              // 添加模式切换按钮
              Button({ type: ButtonType.Normal }) {
                Image($r('app.media.mode_switch'))
                  .width(24)
                  .height(24)
              }
              .height(40)
              .width(40)
              .backgroundColor('#4e87ee')
              .borderRadius(20)
              .margin({ left: 8 })
              .onClick(() => {
                this.showModeSelectionDialog();
              })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 20, bottom: 20 })

          // 温湿度展示
          Row() {
            Column() {
              // 添加标题行，包含图标和文本
              Row() {
                Image($r('app.media.temperature'))  // 添加温度图标
                  .width(20)
                  .height(20)
                  .margin({ right: 6 })
                Text('室内温度')
                  .fontSize(16)
                  .fontColor('#666666')
              }

              Row() {
                Text(`${this.temperature}`)
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                Text('°C')
                  .fontSize(20)
                  .margin({ left: 4 })
              }
            }
            .backgroundColor('#f5f5f5')
            .borderRadius(16)
            .padding(20)
            .width('48%')
            .height(120)
            .justifyContent(FlexAlign.Center)

            Column() {
              // 添加标题行，包含图标和文本
              Row() {
                Image($r('app.media.humidity'))  // 添加湿度图标
                  .width(20)
                  .height(20)
                  .margin({ right: 6 })
                Text('室内湿度')
                  .fontSize(16)
                  .fontColor('#666666')
              }

              Row() {
                Text(`${this.humidity}`)
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                Text('%')
                  .fontSize(20)
                  .margin({ left: 4 })
              }
            }
            .backgroundColor('#f5f5f5')
            .borderRadius(16)
            .padding(20)
            .width('48%')
            .height(120)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 20 })
          Row() {
            Text('当前模式:')
              .fontSize(16)
              .fontColor('#666666')
            Text(this.isCoolMode ? '凉爽模式' : (this.isNightMode ? '夜晚模式' : '默认模式'))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isCoolMode ? '#0077cc' : (this.isNightMode ? '#0c53b7' : '#2c8a00'))
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 设备列表
          Text('设备列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })

          // 设备卡片循环 - 使用refreshCounter来强制刷新
          ForEach(this.devices, (device: DeviceInfo) => {
            this.DeviceCard(device, this.refreshCounter)
          }, (item: DeviceInfo) => item.id)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('sys.color.white'))
        .padding({ left: 16, right: 16, bottom: 70 }) // 为底部导航栏留出空间
        .opacity(this.showModeDialog ? 0.7 : 1) // 当对话框显示时降低主界面透明度

        if (this.showModeDialog) {
          Column() {
            // 对话框标题
            Text('选择模式')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16, bottom: 24 })

            // 默认模式选项
            Row() {
              Text('默认模式')
                .fontSize(16)

              if (!this.isNightMode && !this.isCoolMode) {
                Image($r('app.media.tick'))
                  .width(20)
                  .height(20)
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(16)
            .backgroundColor(!this.isNightMode && !this.isCoolMode ? '#f0f7ff' : '#ffffff')
            .borderRadius(8)
            .onClick(() => {
              this.switchToMode(false, false);
            })

            // 夜晚模式选项
            Row() {
              Text('夜晚模式')
                .fontSize(16)

              if (this.isNightMode) {
                Image($r('app.media.tick'))
                  .width(20)
                  .height(20)
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(16)
            .backgroundColor(this.isNightMode ? '#f0f7ff' : '#ffffff')
            .borderRadius(8)
            .margin({ top: 12 })
            .onClick(() => {
              this.switchToMode(true, false);
            })


            Row() {
              Text('凉爽模式')
                .fontSize(16)

              if (this.isCoolMode) {
                Image($r('app.media.tick'))
                  .width(20)
                  .height(20)
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(16)
            .backgroundColor(this.isCoolMode ? '#f0f7ff' : '#ffffff')
            .borderRadius(8)
            .margin({ top: 12 })
            .onClick(() => {
              this.switchToMode(false, true);
            })

            // 取消按钮
            Button('取消')
              .width('100%')
              .height(40)
              .backgroundColor('#f5f5f5')
              .fontColor('#333333')
              .borderRadius(20)
              .margin({ top: 24 })
              .onClick(() => {
                this.closeModeDialog();
              })
          }
          .width('80%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({ radius: 8, color: '#33000000', offsetX: 2, offsetY: 2 })
        }
      }
      .layoutWeight(1) // 填充除底部导航栏外的所有空间

      // 新增：底部导航栏
      Row() {
        // 主页选项
        Column() {
          Image($r('app.media.home'))
            .width(24)
            .height(24)
            .fillColor(this.currentTab === 'home' ? '#4e87ee' : '#666666')
          Text('主页')
            .fontSize(12)
            .margin({ top: 4 })
            .fontColor(this.currentTab === 'home' ? '#4e87ee' : '#666666')
        }
        .width('50%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.currentTab = 'home';
        })

        // 我的选项
        Column() {
          Image($r('app.media.me'))
            .width(24)
            .height(24)
            .fillColor(this.currentTab === 'me' ? '#4e87ee' : '#666666')
          Text('我的')
            .fontSize(12)
            .margin({ top: 4 })
            .fontColor(this.currentTab === 'me' ? '#4e87ee' : '#666666')
        }
        .width('50%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.currentTab = 'me';
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor(Color.White)
      .shadow({ radius: 8, color: '#33000000', offsetY: -2 })
      .zIndex(1) // 确保菜单栏始终在最上层
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,  // 从上到下方向
      colors: [['#4e87ee', 0.0], ['#ffffff', 1.0]]  // 从蓝色渐变到白色
    })
    .padding(16)
  }

  @Builder
  DeviceCard(device: DeviceInfo, refreshTrigger: number) {
    Row() {
      Row() {
        // 根据设备类型显示不同图标
        if (device.iconName === 'light') {
          Image($r('app.media.light'))
            .width(40)
            .height(40)
            .margin({ right: 16 })
              // 修改这里：夜间模式下灯设备图标变黑白并降低透明度
            .opacity((device.iconName === 'light' && this.isNightMode) ? 0.5 : (device.status ? 1.0 : 0.5))
              // 添加这行：夜间模式下应用灰度滤镜使图标变为黑白
            .colorFilter(this.isNightMode && device.iconName === 'light' ?
              {
                saturate: 0,    // 设置饱和度为0，移除所有颜色
                brightness: 1   // 保持原始亮度
              } : {})
        } else if (device.iconName === 'ac') {
          Image($r('app.media.ac'))
            .width(40)
            .height(40)
            .margin({ right: 16 })
              // 修改这里: 添加填充颜色以突出状态变化
            .fillColor(device.status ? '#4e87ee' : '#666666') // 开启时蓝色，关闭时灰色
            .opacity(1.0) // 保持完全不透明，通过颜色区分状态
        } else if (device.iconName === 'humidifier') {
          // 加湿器图标：根据状态显示不同的图标
          if (device.status) {
            Image($r('app.media.humidifier_on'))
              .width(40)
              .height(40)
              .margin({ right: 16 })
          } else {
            Image($r('app.media.humidifier_off'))
              .width(40)
              .height(40)
              .margin({ right: 16 })
              .opacity(0.5) // 关闭状态下降低透明度
          }
        }

        Column() {
          Text(device.name)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Row() {
            // 修改这里：夜间模式下灯设备始终显示为关闭状态
            if (device.iconName === 'light' && this.isNightMode) {
              // 夜间模式下灯设备显示为关闭
              Text('状态: 关闭')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 4 })
            } else if (device.iconName === 'ac' && this.isCoolMode) {
              // 凉爽模式下空调显示为开启，蓝色高亮
              Text('状态: 开启')
                .fontSize(14)
                .fontColor('#0077cc') // 使用蓝色标识凉爽模式
                .fontWeight(FontWeight.Medium)
                .margin({ top: 4 })
            } else {
              // 常规状态显示
              Text(`状态: ${device.status ? '开启' : '关闭'}`)
                .fontSize(14)
                .fontColor(device.status ? '#2c8a00' : '#666666')
                .margin({ top: 4 })
            }
            // 添加凉爽模式标识
            if (device.iconName === 'ac' && this.isCoolMode && device.status) {
              Text('(凉爽模式)')
                .fontSize(12)
                .fontColor('#0077cc')
                .margin({ top: 4, left: 8 })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      Image($r('app.media.arrow_right'))
        .width(24)
        .height(24)
        .onClick(() => {
          // 创建路由参数对象，添加夜间模式信息
          const params: RouteParams = {
            deviceId: device.id,
            deviceName: device.name,
            deviceStatus: device.status,
            devicePower: device.power,
            isNightMode: this.isNightMode,// 添加夜间模式信息
            isCoolMode: this.isCoolMode // 添加凉爽模式信息
          };

          // 跳转到设备详情页
          try {
            console.info(`导航到设备详情: ${device.name}, 当前状态=${device.status}`);
            router.pushUrl({
              url: 'pages/deviceDetail',
              params: params
            });
          } catch (error) {
            console.error(`导航错误: ${JSON.stringify(error)}`);
          }
        })
    }
    .width('100%')
    .height(80)
    .backgroundColor('#f5f5f5')
    .borderRadius(12)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 12 })
  }
}