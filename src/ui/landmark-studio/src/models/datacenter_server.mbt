///|
// Generic two-socket 2U study, informed by service manuals, not a vendor replica.
fn dc_server(board_only : Bool) -> ComputeView {
  let p : Array[Part] = []
  if !board_only {
    dc_box(p, "chassis", "silver", 0, 0.008, 0, 0.445, 0.016, 0.76)
    for x in [-0.22, 0.22] {
      dc_box(p, "chassis", "silver", x, 0.048, 0, 0.006, 0.082, 0.76)
    }
    dc_box(p, "lid", "silver", 0, 0.09, 0, 0.445, 0.006, 0.76)
    for x in [-0.239, 0.239] {
      dc_box(p, "chassis", "metal", x, 0.044, 0.36, 0.027, 0.085, 0.04)
      dc_box(p, "chassis", "rubber", x, 0.043, 0.399, 0.012, 0.046, 0.034)
    }
    for i in 0..<8 {
      let x = -0.189 + i.to_double() * 0.054
      dc_box(p, "storage", "navy", x, 0.046, 0.29, 0.05, 0.052, 0.15)
      dc_box(p, "storage", "silver", x, 0.046, 0.374, 0.048, 0.06, 0.018)
      dc_box(p, "storage", "rubber", x, 0.046, 0.385, 0.035, 0.043, 0.009)
      dc_box(
        p,
        "storage",
        "screen",
        x + 0.014,
        0.064,
        0.391,
        0.005,
        0.006,
        0.002,
      )
    }
    dc_box(p, "backplane", "pine", 0, 0.047, 0.203, 0.42, 0.058, 0.006)
    for i in 0..<6 {
      let x = -0.172 + i.to_double() * 0.069
      dc_box(p, "fans", "rubber", x, 0.05, 0.151, 0.062, 0.064, 0.054)
      // Fan hub and radial blades sit in X/Y, facing the front-to-back airflow.
      primitive(
        p,
        "sphere",
        "silver",
        x,
        0.05,
        0.183,
        0.018,
        0.018,
        0.008,
        layer="fans",
      )
      for j in 0..<8 {
        let a = j.to_double() * @math.PI / 4
        beam(
          p,
          "metal",
          [x, 0.05, 0.184],
          [x + @math.cos(a) * 0.025, 0.05 + @math.sin(a) * 0.025, 0.184],
          0.003,
          layer="fans",
        )
      }
      dc_box(p, "fans", "amber", x, 0.084, 0.151, 0.028, 0.006, 0.012)
    }
    for x in [-0.16, -0.075] {
      dc_box(p, "psu", "metal", x, 0.047, -0.28, 0.074, 0.06, 0.192)
      dc_box(p, "psu", "rubber", x, 0.047, -0.38, 0.043, 0.03, 0.009)
      dc_box(p, "psu", "lime", x, 0.047, -0.388, 0.036, 0.019, 0.007)
      for i in 0..<10 {
        dc_box(
          p,
          "psu",
          "rubber",
          x,
          0.079,
          -0.35 + i.to_double() * 0.014,
          0.059,
          0.002,
          0.004,
        )
      }
    }
  }
  // PCB, two CPU packages, sixteen DIMMs, VRM, NIC, accelerator and M.2.
  dc_box(p, "board", "pine", 0.012, 0.028, -0.072, 0.384, 0.006, 0.356)
  for x in [-0.08, 0.095] {
    dc_box(p, "cpu", "rubber", x, 0.036, -0.015, 0.069, 0.01, 0.075)
    dc_box(p, "cpu", "silver", x, 0.044, -0.015, 0.053, 0.008, 0.059)
    dc_box(p, "heatsink", "copper", x, 0.052, -0.015, 0.077, 0.008, 0.087)
    for i in 0..<16 {
      dc_box(
        p,
        "heatsink",
        "silver",
        x - 0.035 + i.to_double() * 0.0047,
        0.07,
        -0.015,
        0.0012,
        0.032,
        0.083,
      )
    }
    for side in [-1.0, 1.0] {
      for dimm in 0..<4 {
        let dx = x + side * (0.043 + dimm.to_double() * 0.008)
        dc_box(p, "memory", "rubber", dx, 0.037, -0.015, 0.005, 0.009, 0.105)
        dc_box(p, "memory", "pine", dx, 0.052, -0.015, 0.0025, 0.027, 0.1)
        for j in 0..<8 {
          dc_box(
            p,
            "memory",
            "rubber",
            dx + 0.002,
            0.053,
            -0.057 + j.to_double() * 0.012,
            0.003,
            0.015,
            0.008,
          )
        }
        for z in [-0.067, 0.037] {
          dc_box(p, "memory", "ivory", dx, 0.044, z, 0.006, 0.013, 0.007)
        }
      }
    }
    for i in 0..<9 {
      dc_box(
        p,
        "vrm",
        "metal",
        x - 0.034 + i.to_double() * 0.008,
        0.04,
        0.069,
        0.006,
        0.012,
        0.008,
      )
      primitive(
        p,
        "cylinder",
        "silver",
        x - 0.034 + i.to_double() * 0.008,
        0.04,
        0.083,
        0.005,
        0.013,
        0.005,
        layer="vrm",
      )
    }
  }
  dc_box(p, "nic", "pine", 0.155, 0.044, -0.207, 0.075, 0.009, 0.07)
  dc_box(p, "nic", "silver", 0.155, 0.055, -0.21, 0.042, 0.012, 0.042)
  for x in [0.135, 0.173] {
    dc_box(p, "nic", "silver", x, 0.055, -0.25, 0.028, 0.026, 0.016)
    dc_box(p, "nic", "rubber", x, 0.055, -0.26, 0.021, 0.017, 0.006)
  }
  dc_box(p, "gpu", "pine", -0.005, 0.056, -0.154, 0.07, 0.007, 0.17)
  dc_box(p, "gpu", "rubber", -0.005, 0.066, -0.154, 0.054, 0.017, 0.14)
  for i in 0..<13 {
    dc_box(
      p,
      "gpu",
      "silver",
      -0.031 + i.to_double() * 0.0043,
      0.078,
      -0.154,
      0.0015,
      0.016,
      0.133,
    )
  }
  dc_box(p, "m2", "pine", -0.118, 0.035, -0.133, 0.024, 0.005, 0.08)
  for i in 0..<3 {
    dc_box(
      p,
      "m2",
      "rubber",
      -0.118,
      0.04,
      -0.16 + i.to_double() * 0.024,
      0.02,
      0.006,
      0.018,
    )
  }
  for i in 0..<24 {
    let x = -0.166 + i.to_double() * 0.015
    dc_box(p, "board", "amber", x, 0.0315, -0.09, 0.0008, 0.0004, 0.056)
    dc_box(
      p,
      "board",
      "amber",
      x + 0.009,
      0.0315,
      -0.061,
      0.018,
      0.0004,
      0.0008,
    )
  }
  for x in [-0.17, 0.19] {
    for z in [-0.239, 0.092] {
      primitive(
        p,
        "cylinder",
        "silver",
        x,
        0.033,
        z,
        0.008,
        0.007,
        0.008,
        layer="board",
      )
    }
  }
  let entities = [
    dc_entity(
      "board",
      "主板 / System board",
      "PCB",
      [0.01, 0.04, -0.072],
      "多层 PCB 连接处理器、内存与扩展设备。表面铜线仅作视觉说明，不是布线网表或可制造电路。",
      visit=if board_only { "" } else { "board" },
    ),
    dc_entity(
      "cpu",
      "双路 CPU",
      "COMPUTE",
      [-0.08, 0.05, -0.015],
      "CPU 执行指令，访问本地内存，并通过 PCIe 与设备交换数据。选择拆解可抬起散热器，查看封装。未指定型号或核心数。",
    ),
    dc_entity(
      "memory",
      "16 × DIMM",
      "VOLATILE MEMORY",
      [0.16, 0.065, -0.015],
      "DRAM 保存运行中的工作集，CPU 经内存控制器访问。不是永久存储；容量与带宽未假设为真实机器规格。",
    ),
    dc_entity(
      "gpu",
      "PCIe 加速卡",
      "ACCELERATOR",
      [-0.005, 0.085, -0.154],
      "通用扩展卡示意。真实 GPU 型号、数量与显存来自 LunaNexa，不能从外观推断。",
    ),
    dc_entity(
      "nic",
      "双口网卡 / NIC",
      "NETWORK",
      [0.155, 0.07, -0.21],
      "网卡收发帧，通过 PCIe / DMA 与主机内存交换缓冲区；CPU 处理协议与应用。路径为教学抽象，不是串行电路仿真。",
    ),
    dc_entity(
      "m2",
      "M.2 启动存储",
      "NONVOLATILE",
      [-0.118, 0.048, -0.133],
      "板载 NVMe 启动盘，断电后保留数据。持久化语义取决于控制器、缓存与写入确认。",
    ),
    dc_entity(
      "vrm",
      "电压调节 / VRM",
      "DC POWER",
      [0.095, 0.05, 0.08],
      "PSU 将交流转换为直流，VRM 再提供处理器所需低压电源。发热同时需要通过散热结构排走。",
    ),
    dc_entity(
      "heatsink",
      "散热器与鳍片",
      "HEAT TRANSFER",
      [0.095, 0.09, -0.015],
      "芯片热量经封装、导热界面到散热底座与鳍片，随后传给空气。热传递方向与电信号不是同一件事。",
    ),
  ]
  if !board_only {
    entities.push(
      dc_entity(
        "storage",
        "8 × 前置存储托架",
        "DRIVE BAY",
        [0, 0.08, 0.31],
        "前置 NVMe 盘通过背板连接主机 PCIe。8 是设计盘位数，不能当作已安装数量或总容量。",
      ),
    )
    entities.push(
      dc_entity(
        "backplane",
        "存储背板",
        "INTERCONNECT",
        [0, 0.08, 0.203],
        "为前置托架提供电源和数据连接。该提案展示 NVMe 路径，不把所有存储都画成经独立 RAID 芯片。",
      ),
    )
    entities.push(
      dc_entity(
        "fans",
        "6 × 热插拔风扇",
        "AIRFLOW",
        [0, 0.09, 0.151],
        "风扇从前部吸入冷空气，穿过散热器后排向机箱后方。动画不模拟 CFD、风量或噪声。",
      ),
    )
    entities.push(
      dc_entity(
        "psu",
        "PSU A / B",
        "AC → DC",
        [-0.12, 0.09, -0.29],
        "两块电源分别连接机柜 A/B PDU。没有额定铭牌、负载曲线与电表，因此实际 W、A、V 均未知。",
      ),
    )
  }
  let flows = [
    dc_flow(
      "server-net",
      "data",
      "NIC ⇄ PCIe / DMA ⇄ 内存 ⇄ CPU",
      "示意一次接收：网络帧进入 NIC，数据通过 DMA 写入内存，CPU 使用缓冲区。发送反向进行；不表示所有数据依次经过 CPU 引脚。",
      [
        [0.155, 0.1, -0.27],
        [0.155, 0.1, -0.21],
        [0.155, 0.105, -0.09],
        [0.16, 0.105, -0.015],
        [0.095, 0.105, -0.015],
      ],
    ),
    dc_flow(
      "server-storage",
      "data",
      "CPU / PCIe → NVMe 启动盘",
      "存储命令与完成队列通过 PCIe 传递；DMA 搬运数据。此线不是实际 PCB 铜线位置。",
      [
        [-0.08, 0.1, -0.015],
        [-0.08, 0.1, -0.1],
        [-0.118, 0.1, -0.1],
        [-0.118, 0.1, -0.133],
      ],
    ),
    dc_flow(
      "board-power",
      "power",
      "直流母线 → VRM → CPU",
      "电源调节与能量输送路径。并非电子运动速度或电压波形。",
      [
        [-0.16, 0.115, -0.18],
        [-0.17, 0.115, 0.08],
        [-0.08, 0.115, 0.08],
        [-0.08, 0.115, -0.015],
      ],
    ),
    dc_flow(
      "cpu-heat",
      "heat",
      "CPU → 导热底座 → 鳍片 → 空气",
      "热传导进入散热器，然后对流传给经过的空气。",
      [
        [0.095, 0.045, -0.015],
        [0.095, 0.085, -0.015],
        [0.095, 0.13, -0.07],
        [0.095, 0.13, -0.26],
      ],
    ),
  ]
  if !board_only {
    flows.push(
      dc_flow(
        "server-front",
        "data",
        "PCIe → 背板 → 前置 NVMe",
        "前置持久存储路径，与 M.2 启动盘独立展示。",
        [
          [-0.08, 0.11, -0.015],
          [-0.19, 0.11, -0.015],
          [-0.19, 0.11, 0.203],
          [0, 0.11, 0.203],
          [0, 0.11, 0.3],
        ],
      ),
    )
    flows.push(
      dc_flow(
        "server-psu",
        "power",
        "PDU → PSU → 直流母线",
        "双 PSU 电路以 A 路作教学示意。",
        [[-0.16, 0.1, -0.42], [-0.16, 0.1, -0.28], [-0.16, 0.115, -0.18]],
      ),
    )
    flows.push(
      dc_flow(
        "server-air",
        "cooling",
        "前进风 → 风扇墙 → CPU 散热器",
        "机箱后方是排风侧。冷风会吸热；这里用分色表达热过程，不做流体模拟。",
        [[0.095, 0.115, 0.42], [0.095, 0.115, 0.151], [0.095, 0.115, 0.03]],
      ),
    )
  }
  return dc_view(
    if board_only {
      "board"
    } else {
      "server"
    },
    if board_only {
      "主板上的三种流动"
    } else {
      "打开一台服务器"
    },
    if board_only {
      "BOARD / 信号 · 电能 · 热"
    } else {
      "SERVER / 通用双路 2U 架构"
    },
    if board_only {
      0.58
    } else {
      1.0
    },
    [0, 0.04, if board_only { -0.07 } else { 0 }],
    if board_only {
      [0.37, 0.53, 0.52]
    } else {
      [0.67, 0.85, 1.05]
    },
    p,
    entities,
    flows,
  )
}
