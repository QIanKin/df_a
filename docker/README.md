# Diff-Planner 仿真开发环境

## 首次使用

支持 Linux x86_64 桌面，X11 或带 XWayland 的 Wayland 会话。
宿主只需 Docker Engine、可用的 Docker 用户权限、`xauth` 和网络；无需安装 ROS、CUDA 或 NVIDIA Container Toolkit。
Ubuntu 宿主可用 `sudo apt-get install xauth` 安装显示认证工具。确认普通用户运行 `docker info` 成功。
当前配置未验证 macOS、Windows 或 ARM 主机的 GUI，不宣称覆盖这些环境。

在克隆的仓库根目录，用宿主的图形桌面终端执行（不要 sudo）：

```bash
bash docker/enter.sh
```

首次自动构建镜像并创建 `df-a-sim`；容器停止时启动它；容器正在运行时直接打开新终端。
默认进入 zsh，已经加载 ROS Noetic。按原来的步骤手动操作：

```zsh
cd Diff-Planner
catkin_make
source devel/setup.zsh
roslaunch diff_planner run_sim_single.launch
```

偏好 bash：

```bash
bash docker/enter.sh bash
# 以下在容器里
cd Diff-Planner
catkin_make
source devel/setup.bash
roslaunch diff_planner run_sim_single.launch
```

脚本只准备环境并进入 shell，不自动编译、启动 ROS 或发送目标。
在宿主再次执行入口即可打开同一容器的另一个终端，新终端仍需 `source` 项目的 devel。
退出 shell 用 `exit`，停止容器用 `docker stop df-a-sim`。

## 构建范围与文件同步

完整仓库挂载到 `/Diff-Planner`，编辑源码即时反映到宿主，可以照常 Git commit / push。
容器采用宿主 UID/GID，避免容器编辑产生 root 所有的源码。
`build`、`devel`、`install` 使用独立 Docker 卷，和真机、旧本地工程的编译产物分开。
不要提交或拷贝这些编译产物到真机；真机拉取源码后在自己的 ROS 环境编译。

容器里的 `/opt/df-a/bin/catkin_make` 为 ROS 原命令添加仿真包列表和默认 `-j2 -l2`。
包含规划器、MOCHA、消息、地图/点云模拟、里程计、RViz 插件、手动控制和 multipoint，共 16 个包：

```text
quadrotor_msgs uav_utils pose_utils plan_env path_searching traj_utils traj_opt
diff_planner poscmd_2_odom map_generator local_sensing_node odom_visualization
rviz_plugins selected_points_publisher manual_take_over multipoint
```

这 16 个包已经在公开 `osrf/ros:noetic-desktop-full` 基础镜像中按下面的原命令完成过干净编译，退出码为 0；其中包含 MOCHA 规划器和 RViz 插件：

```bash
cd Diff-Planner
catkin_make
source devel/setup.bash   # zsh 使用 setup.zsh
```

这里的“完整编译”指仿真启动所需的 16 个包全部编译完成。仓库中需要真机 SDK、串口/传感器驱动、ARM 专用库或固定 `/home/nv` 路径的 VINS/LIO/RealSense 等包，不属于这套通用仿真构建范围；因此不能把整个仓库的所有硬件包都承诺在任何电脑的 Docker 中编译。真机仍按它自己的 ROS、设备 SDK 和 ARM 环境编译。仿真包列表只在容器内生效，不添加 `CATKIN_IGNORE`，也不修改真机 package.xml/CMake 配置。

`src/CMakeLists.txt` 指向 Noetic 的软链接会在容器中正常解析；宿主没有 ROS 时显示失效不影响此流程。

## 可视化和资源

通过 Xauthority cookie 访问当前桌面，不使用 `xhost +`。默认 Mesa CPU 渲染，兼容 Intel/AMD/NVIDIA 宿主，速度取决于电脑配置。
请从实际图形桌面运行；SSH 无 DISPLAY 的终端不适用。

默认只用 2 个编译进程，避免笔记本内存不足。可根据内存调整：

```bash
DF_BUILD_JOBS=4 bash docker/enter.sh
```

同一电脑多个克隆可分别指定容器名，构建卷也会独立：

```bash
DF_CONTAINER=df-a-sim-other bash docker/enter.sh
```

入口会检查已有容器绑定的仓库，拒绝误进入另一个克隆的容器。
默认使用 Docker bridge 网络，没有挂载飞控串口或启用 host 网络，仿真 ROS master 留在容器内。

## 更新

普通源码改动：容器内重新 `catkin_make`，然后重新 source / 启动仿真。
Dockerfile 或容器内脚本改动：重新构建镜像，然后删除并重建容器；保留原构建卷：

```bash
docker build --build-arg DEV_UID="$(id -u)" --build-arg DEV_GID="$(id -g)" \
  -t "df-a-noetic-sim:uid$(id -u)-gid$(id -g)" docker
docker stop df-a-sim
docker rm df-a-sim
bash docker/enter.sh
```

镜像按 UID/GID 命名，适用于多人使用各自电脑。第一次需要能访问 Docker Hub 和 Ubuntu/ROS 软件源。
ROS Noetic 的基础镜像与上游软件源仍属于外部依赖；网络不可用时首次构建无法完成。
