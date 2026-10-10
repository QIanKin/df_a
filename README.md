# 非凸 A 机器真机代码仓库

本仓库用于非凸 A 机器的真机飞行、定位、建图、规划和控制，也包含不连接硬件的 ROS 仿真环境。

## 目录说明

- `src/diff_planner`：Diff-Planner 规划、MOCHA 优化器、轨迹服务器和仿真节点。
- `src/realflight_modules`：真机使用的 LIO、VIO、MAVROS、PX4 控制和传感器驱动。
- `src/user_command/multipoint`：多点任务、停留时间、yaw 控制和返航点接口。
- `sh_files`：真机和仿真启动脚本。
- `docker`：通用 ROS Noetic 仿真开发环境，使用说明见 [docker/README.md](docker/README.md)。

## 规划器选择

仿真和真机共用规划器配置文件：[planner.yaml](src/diff_planner/plan_manage/config/planner.yaml)。

```yaml
manager:
  trajectory_optimizer: mocha
```

目前支持两种值：

- `mocha`：MOCHA 3D NMC 规划器(法向运动伪装降维)，当前默认值。
- `minco`：原始 MINCO 规划器，用于对比或兼容测试。

修改后重新启动对应的 `roslaunch` 即可生效，不需要重新编译。启动日志会打印实际选择的规划器，例如：

```text
Trajectory optimizer: mocha
```

仿真和真机启动文件分别加载 `advanced_param_sim.xml` 与 `advanced_param_exp.xml`，两者都会读取上述 `planner.yaml`。切换规划器时只修改这个配置文件，不要在不同 launch 文件中维护多份选择。

## 算法改动

- **修复**局部规划时 A* 终点位于障碍物内，沿 A* 起始方向推出障碍物时的错误。
- **修复**优化过程中频繁打印局部目标点碰撞并导致规划器卡死的问题。
- **修复**状态机调用 `planNextWaypoint()` 导致状态机卡死的问题。
- **新增**规划优化异常检测，避免动力学不可行的轨迹发出；动力学容忍值在 [advanced_param_sim.xml](src/diff_planner/plan_manage/launch/include/advanced_param_sim.xml) / [advanced_param_exp.xml](src/diff_planner/plan_manage/launch/include/advanced_param_exp.xml) 中设置：

  ```xml
  <param name="optimization/vel_tolerance" value="1.0" type="double"/>
  <param name="optimization/acc_tolerance" value="1.0" type="double"/>
  ```

- **修复**遇到大障碍物后在障碍物前反复徘徊卡死的问题，并增加大障碍物检测开关：

  ```xml
  <param name="fsm/enable_stuck_detect" value="true"/>
  ```

- **新增**优化失败次数过多时的处理逻辑。
- **新增**激光雷达建图 raycast 版本。
- **新增** `user_command` 多点任务接口，可设置途经点、返航点、停留时间和 yaw 角。
- **新增** `traj_server` yaw 角控制接口。

## Docker 仿真环境

Docker 环境用于没有真机硬件时的编译和仿真开发，不连接飞控串口，也不替代真机运行环境。它从公开的 `osrf/ros:noetic-desktop-full` 镜像构建，不依赖某一台电脑已有的本地镜像。

宿主机要求：Linux x86_64 图形桌面、Docker、`xauth` 和可用网络。第一次构建需要下载 Docker 基础镜像和 ROS 依赖。宿主机不需要安装 ROS、CUDA 或 NVIDIA Container Toolkit。

在仓库根目录执行：

```bash
bash docker/enter.sh
```

脚本的行为如下：

1. 第一次运行时构建镜像并创建 `df-a-sim` 容器。
2. 容器已停止时自动启动原容器。
3. 容器正在运行时打开一个新的终端。
4. 源码目录挂载到容器的 `/Diff-Planner`，`build`、`devel`、`install` 使用独立 Docker 卷。

进入容器后，操作步骤保持原来的方式：

```zsh
cd Diff-Planner
catkin_make
source devel/setup.zsh
roslaunch diff_planner run_sim_single.launch
```

如果使用 bash：

```bash
bash docker/enter.sh bash
cd Diff-Planner
catkin_make
source devel/setup.bash
roslaunch diff_planner run_sim_single.launch
```

仿真中的单机 RViz 可使用 `3D Nav Goal` 发送目标点。多点任务和返航点配置在 [points.yaml](src/user_command/multipoint/config/points.yaml)：

```bash
# 在容器内的另一个终端执行
./sh_files/pub_trigger.sh   # 开始多点任务
./sh_files/back.sh          # 发送返航触发
```

多点模式由 [multipointplan_sim.launch](src/user_command/multipoint/launch/multipointplan_sim.launch) 的 `fligt_type` 选择，支持：

1. 多点规划；
2. 多点规划并控制每个点的停留时间；
3. 多点规划并控制每个点的 yaw 角；
4. 多点规划、停留时间和 yaw 角同时控制。

`points.yaml` 中每个模式的数组长度必须分别为 3、4、4、5，返航点数组长度为 3。启动 multipoint 节点后，在 RViz 中发送一次 `2D Nav Goal` 即可开始任务。

### Docker 仿真编译范围

容器中的 `catkin_make` 会完整编译当前仿真启动所需的 16 个包：

```text
quadrotor_msgs uav_utils pose_utils plan_env path_searching traj_utils traj_opt
diff_planner poscmd_2_odom map_generator local_sensing_node odom_visualization
rviz_plugins selected_points_publisher manual_take_over multipoint
```

这 16 个包包含 MOCHA、地图/点云模拟、轨迹服务器、RViz 插件和 multipoint。仓库中依赖真机 SDK、串口、传感器硬件、ARM 专用库或固定 `/home/nv` 路径的 VINS/LIO/RealSense 等包，不属于通用仿真镜像的构建范围；真机仍需在自己的 ROS、设备 SDK 和 ARM 环境中编译。

修改 Dockerfile 或 Docker 脚本后，重建镜像并重建容器：

```bash
docker build --build-arg DEV_UID="$(id -u)" --build-arg DEV_GID="$(id -g)" \
  -t "df-a-noetic-sim:uid$(id -u)-gid$(id -g)" docker
docker stop df-a-sim
docker rm df-a-sim
bash docker/enter.sh
```

停止仿真容器：

```bash
docker stop df-a-sim
```

更多 Docker 细节、GUI 要求和故障排查见 [docker/README.md](docker/README.md)。

## 仿真运行步骤（非 Docker ROS 环境）

如果电脑已经安装并配置 ROS Noetic，也可以直接编译：

```bash
git clone <仓库地址>
cd Diff-Planner
catkin_make
source devel/setup.zsh       # bash 使用 source devel/setup.bash
roslaunch diff_planner run_sim_single.launch
```

使用 RViz 的 `3D Nav Goal` 发送目标点。预设多点任务时编辑 [points.yaml](src/user_command/multipoint/config/points.yaml) 的 `test1`，返航点编辑 `test_back`，然后运行：

```bash
./sh_files/pub_trigger.sh
./sh_files/back.sh
```

集群仿真使用 [run_sim_swarm.launch](src/diff_planner/plan_manage/launch/sim/run_sim_swarm.launch)，先在 launch 文件中设置各架无人机的目标点，再执行：

```bash
source devel/setup.zsh
roslaunch diff_planner run_sim_swarm.launch
./sh_files/pub_swarm_trigger.sh
```

## 真机运行

### 视觉定位内参

使用视觉定位规划前，在 [run_exp_single_vio.launch](src/diff_planner/plan_manage/launch/exp/run_exp_single_vio.launch) 中填写深度相机内参 `cx/cy/fx/fy`。可以运行：

```bash
./sh_files/run_vins.sh
rostopic echo /camera/depth/camera_info
```

消息中的 K 矩阵提供相机内参，使用时注意矩阵元素顺序。

### LIO 真机流程

```bash
./sh_files/run_single_lio.sh
```

### VIO 真机流程

```bash
./sh_files/run_single_vio.sh
```

真机起飞、规划、返航和降落动作按配套产品手册执行。真机启动前确认传感器、飞控连接、坐标系、目标点和返航点已经配置正确。

## 许可证

本仓库遵循根目录 [LICENSE](LICENSE) 中的许可条款。仓库中的部分规划和 ROS 组件基于开源项目修改，使用和再发布时请同时遵守对应子目录的许可证与声明。
