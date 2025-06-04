// pages/deviceDetail.ets
import router from '@ohos.router';
import common from '@ohos.app.ability.common';

// 定义参数接口，明确类型
interface RouteParams {
  deviceId?: string;
  deviceName?: string;
  deviceStatus?: boolean;
  devicePower?: number;
  isNightMode?: boolean; // 添加夜间模式字段
  isCoolMode?: boolean;
}

// 定义设备状态变更的接口
interface DeviceStatusChange {
  deviceId: string;
  newStatus: boolean;
}

interface EnhancedDeviceStatusChange {
  deviceId: string;
  newStatus: boolean;
  timestamp: number; // 添加时间戳字段
}

@Entry
@Component

struct DeviceDetailPage {
  // 初始化状态变量
  @State deviceId: string = '';
  @State deviceName: string = '';
  @State deviceStatus: boolean = false;
  @State devicePower: number = 0;
  @State brandName: string = '智能星辰'; // 自编的品牌名称
  @State deviceModel: string = 'SC-2025'; // 自编的型号
  @State isNightMode: boolean = false;
  @State isCoolMode: boolean = false;
  private originalStatus: boolean = false; // 记录初始状态，用于检测变化



  aboutToAppear() {
    // 在组件出现前获取路由参数
    const params = router.getParams() as RouteParams;
    if (params) {
      // 使用可选链并提供默认值
      this.deviceId = params.deviceId ?? '';
      this.deviceName = params.deviceName ?? '';
      this.deviceStatus = params.deviceStatus ?? false;
      this.devicePower = params.devicePower ?? 0;
      this.isNightMode = params.isNightMode ?? false; // 获取夜间模式状态
      this.originalStatus = this.deviceStatus; // 保存初始状态
      this.isCoolMode = params.isCoolMode ?? false;
    }
  }

  // 添加返回按钮响应方法
  onBackPress() {
    // 不管状态是否有变化，都通过AppStorage传递当前状态
    // 这样可以确保主页面总是获取到最新状态
    this.updateDeviceStatus();
    return false; // 允许默认的返回行为继续执行
  }


  // 修改 updateDeviceStatus 方法，移除状态变化检查
  updateDeviceStatus() {
    try {
      // 使用定义好的接口创建状态变更对象
      const statusChange: EnhancedDeviceStatusChange = {
        deviceId: this.deviceId,
        newStatus: this.deviceStatus,
        timestamp: Date.now() // 添加时间戳确保每次更新都是唯一的
      };

      // 使用不同的键来避免可能的冲突
      AppStorage.SetOrCreate('device_' + this.deviceId + '_status', statusChange);
      console.info(`设备状态已更新: 设备=${this.deviceId}, 新状态=${this.deviceStatus}, 时间=${statusChange.timestamp}`);
    } catch (error) {
      console.error(`无法更新设备状态: ${JSON.stringify(error)}`);
    }
  }

 build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => {
            // 使用一个延时来确保状态更新在路由返回前完成
            this.updateDeviceStatus();

            // 添加一个短暂延时确保 AppStorage 更新完成
            setTimeout(() => {
              router.back();
            }, 50);  // 短暂延时，确保状态先更新
          })

        Text(this.deviceName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 设备信息
      Column() {
        // 根据设备类型选择不同的图标
        if (this.deviceId.includes('light')) {
          Image($r('app.media.light_big'))
            .width(120)
            .height(120)
            .margin({ top: 40, bottom: 40 })
            .opacity(this.deviceStatus ? 1.0 : 0.5) // 根据状态调整透明度
        } else {
          Image($r('app.media.ac_big'))
            .width(120)
            .height(120)
            .margin({ top: 40, bottom: 40 })
            .opacity(this.deviceStatus ? 1.0 : 0.5) // 根据状态调整透明度
        }

        this.InfoItem('设备名称', this.deviceName)
        this.InfoItem('设备品牌', this.brandName)
        this.InfoItem('设备型号', this.deviceModel)
        this.InfoItem('设备状态', this.deviceStatus ? '开启' : '关闭')
        this.InfoItem('实时功率', `${this.deviceStatus ? this.devicePower : 0} W`)
        this.InfoItem('今日用电', `${(this.devicePower * (Math.random() * 3 + 2) / 1000).toFixed(2)} kWh`)

        // 如果是灯设备，可能需要添加特别提示
        if (this.deviceId.includes('light') && this.isNightMode) {
          Text('注意: 当前处于夜间模式，返回主页后灯将保持关闭状态')
            .fontSize(14)
            .fontColor('#ff4c4c')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 16 })
        }

        if (this.deviceId.includes('light')) {
          Text('提示: 夜间模式下灯的状态会被自动关闭')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 16 })
        }

        if (this.deviceId.includes('air-conditioner') && this.isCoolMode) {
          Text('提示: 当前处于凉爽模式，空调将保持开启状态')
            .fontSize(14)
            .fontColor('#0077cc')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 16 })
        }

        Blank()

        Row() {
          Button('关闭')
            .width('48%')
            .height(50)
            .backgroundColor(this.deviceStatus ? '#ff4c4c' : '#cccccc')
            .borderRadius(25)
            .fontSize(18)
            .fontColor($r('sys.color.white'))
            .margin({ right: 8 })
              // 如果是空调且处于凉爽模式，禁用关闭按钮
            .enabled(this.deviceStatus && !(this.deviceId.includes('air-conditioner') && this.isCoolMode))
            .onClick(() => {
              this.deviceStatus = false;
              // 状态更改后立即预更新到AppStorage
              this.updateDeviceStatus();
            })

          Button('开启')
            .width('48%')
            .height(50)
            .backgroundColor(!this.deviceStatus ? '#4c88ff' : '#cccccc')
            .borderRadius(25)
            .fontSize(18)
            .fontColor($r('sys.color.white'))
            .margin({ left: 8 })
              // 如果设备已开启或是空调且处于凉爽模式，禁用开启按钮
            .enabled(!this.deviceStatus && !(this.deviceId.includes('air-conditioner') && this.isCoolMode && this.deviceStatus))
            .onClick(() => {
              this.deviceStatus = true;
              // 状态更改后立即预更新到AppStorage
              this.updateDeviceStatus();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.white'))
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.white'))
  }

  @Builder
  InfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#666666')

      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#eeeeee' })
  }
}