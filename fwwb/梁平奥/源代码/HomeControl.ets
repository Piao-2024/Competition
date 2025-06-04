// pages/HomeControl.ets
import router from '@ohos.router';

// 定义设备信息类型
class DeviceInfo {
  id: string;
  name: string;
  iconName: string;
  status: boolean;
  power: number;

  constructor(id: string, name: string, iconName: string, status: boolean, power: number) {
    this.id = id;
    this.name = name;
    this.iconName = iconName;
    this.status = status;
    this.power = power;
  }
}

// 定义路由参数接口
interface HomeControlParams {
  devices: DeviceInfo[];
}

@Entry
@Component
struct HomeControl {
  // 定义一个初始空数组，不要直接从router.getParams()获取
  @State devices: DeviceInfo[] = [];
  // 查找加湿器的方法
  private findHumidifier(): DeviceInfo | undefined {
    return this.devices.find(device => device.iconName === 'humidifier');
  }
  // 切换加湿器状态的方法
  private toggleHumidifier() {
    const index = this.devices.findIndex(device => device.iconName === 'humidifier');
    if (index !== -1) {
      this.devices[index].status = !this.devices[index].status;
      // 创建新数组以触发UI更新
      this.devices = [...this.devices];
    }
  }
  // 查找卧室灯的方法
  private findBedroomLight(): DeviceInfo | undefined {
    return this.devices.find(device => device.name === '卧室灯' && device.iconName === 'light');
  }

  // 查找客厅灯的方法
  private findLivingRoomLight(): DeviceInfo | undefined {
    return this.devices.find(device => device.name === '客厅灯' && device.iconName === 'light');
  }

  // 查找空调的方法
  private findAC(): DeviceInfo | undefined {
    return this.devices.find(device => device.iconName === 'ac');
  }

  // 切换卧室灯状态的方法
  private toggleBedroomLight() {
    const index = this.devices.findIndex(device => device.name === '卧室灯' && device.iconName === 'light');
    if (index !== -1) {
      this.devices[index].status = !this.devices[index].status;
      // 创建新数组以触发UI更新
      this.devices = [...this.devices];
    }
  }

  // 切换客厅灯状态的方法
  private toggleLivingRoomLight() {
    const index = this.devices.findIndex(device => device.name === '客厅灯' && device.iconName === 'light');
    if (index !== -1) {
      this.devices[index].status = !this.devices[index].status;
      // 创建新数组以触发UI更新
      this.devices = [...this.devices];
    }
  }

  // 切换空调状态的方法
  private toggleAC() {
    const index = this.devices.findIndex(device => device.iconName === 'ac');
    if (index !== -1) {
      this.devices[index].status = !this.devices[index].status;
      // 创建新数组以触发UI更新
      this.devices = [...this.devices];
    }
  }

  // 使用aboutToAppear生命周期方法获取参数
  aboutToAppear() {
    // 使用类型断言将参数转换为定义好的接口类型
    const params = router.getParams() as HomeControlParams;
    if (params && params.devices) {
      this.devices = params.devices;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('家庭控制中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 家的俯视图
      Column() {
        Text('家庭平面图')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 12 })

        // 使用Stack组件来叠加图像
        Stack({ alignContent: Alignment.TopStart }) {
          // 底层显示家的俯视图
          Image($r('app.media.top_view_of_home'))
            .width('100%')
            .objectFit(ImageFit.Contain)
            .borderRadius(12)

          // 在指定位置叠加卧室灯图标
          // 获取卧室灯状态
          if (this.findBedroomLight()) {
            Image(this.findBedroomLight()?.status ? $r('app.media.electric_on') : $r('app.media.electric_off'))
              .width(30)
              .height(30)
              .position({ x: 45, y: 100 })
              .onClick(() => {
                this.toggleBedroomLight();
              })
          }

          // 在指定位置叠加客厅灯图标
          // 获取客厅灯状态
          if (this.findLivingRoomLight()) {
            Image(this.findLivingRoomLight()?.status ? $r('app.media.electric_on') : $r('app.media.electric_off'))
              .width(30)
              .height(30)
              .position({ x: 190, y: 30 })
              .onClick(() => {
                this.toggleLivingRoomLight();
              })
          }

          // 在指定位置叠加空调图标
          // 获取空调状态
          if (this.findAC()) {
            Image(this.findAC()?.status ? $r('app.media.ac_on') : $r('app.media.ac_off'))
              .width(28)
              .height(28)
              .position({ x: 10, y: 193 })
              .onClick(() => {
                this.toggleAC();
              })
          }
          // 在指定位置叠加加湿器图标
          // 获取加湿器状态
          if (this.findHumidifier()) {
            Image(this.findHumidifier()?.status ? $r('app.media.humidifier_on') : $r('app.media.humidifier_off'))
              .width(28)
              .height(28)
              .position({ x: 120, y: 90 })
              .onClick(() => {
                this.toggleHumidifier();
              })
          }
        }
      }
      .padding(16)
      .width('100%')
      .backgroundColor('#f5f5f5')
      .borderRadius(12)
      .margin({ top: 16, bottom: 20 })

      // 设备控制区域
      Text('设备控制')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })


      // 列出所有设备的开关状态
      // 修复List组件的宽高设置
      List({ space: 8 }) {
        ForEach(this.devices, (device: DeviceInfo, index: number) => {
          ListItem() {
            Row() {
              // 设备图标
              if (device.iconName === 'light') {
                Image($r('app.media.light'))
                  .width(36)
                  .height(36)
                  .margin({ right: 16 })
                  .fillColor(device.status ? '#4e87ee' : '#999999')
              } else if (device.iconName === 'ac') {
                Image($r('app.media.ac'))
                  .width(36)
                  .height(36)
                  .margin({ right: 16 })
                  .fillColor(device.status ? '#4e87ee' : '#999999')
              } else if (device.iconName === 'humidifier') {
              Image(device.status ? $r('app.media.humidifier_on') : $r('app.media.humidifier_off'))
                .width(36)
                .height(36)
                .margin({ right: 16 })
              }

              // 设备名称和状态信息
              Column() {
                Text(device.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)

                Text(`状态: ${device.status ? '开启' : '关闭'}`)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              // 开关按钮
              Toggle({ type: ToggleType.Switch, isOn: device.status })
                .onChange((isOn: boolean) => {
                  // 更新设备状态并触发UI刷新
                  this.devices[index].status = isOn;
                  // 确保状态更新后UI得到刷新
                  this.devices = [...this.devices];
                })
            }
            .width('100%')
            .height(72)
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('sys.color.white'))
            .borderRadius(8)
            .alignItems(VerticalAlign.Center)
          }
        }, (item: DeviceInfo) => item.id)
      }
      .width('100%')    // 设置列表宽度
      .height('60%')    // 设置列表高度
      .borderRadius(12)
      .backgroundColor('#f5f5f5')
      .padding({ top: 8, bottom: 8 })
      .divider({ strokeWidth: 1, color: '#eeeeee', startMargin: 56, endMargin: 16 })
      .borderRadius(12)
      .backgroundColor('#f5f5f5')
      .padding({ top: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.white'))
    .padding(16)
  }

  @Builder
  DeviceControlItem(device: DeviceInfo, index: number) {
    Row() {
      // 设备图标
      if (device.iconName === 'light') {
        Image($r('app.media.light'))
          .width(36)
          .height(36)
          .margin({ right: 16 })
          .fillColor(device.status ? '#4e87ee' : '#999999')
      } else if (device.iconName === 'ac') {
        Image($r('app.media.ac'))
          .width(36)
          .height(36)
          .margin({ right: 16 })
          .fillColor(device.status ? '#4e87ee' : '#999999')
      }
     else if (device.iconName === 'humidifier') {
      Image(device.status ? $r('app.media.humidifier_on') : $r('app.media.humidifier_off'))
        .width(36)
        .height(36)
        .margin({ right: 16 })
      }
      // 设备名称和功率信息
      Column() {
        Text(device.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        Text(`功率: ${device.power}W`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      // 开关按钮
      Toggle({ type: ToggleType.Switch, isOn: device.status })
        .onChange((isOn: boolean) => {
          // 更新设备状态
          this.devices[index].status = isOn;
        })
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }
}