#!/bin/bash

# PX4参数设置脚本
# 用于设置光流相关参数

echo "开始设置PX4参数..."

# 设置 EKF2_BARO_CTRL (Disabled)
echo "设置 EKF2_BARO_CTRL = Disabled..."
rosservice call /mavros/param/set "{param_id: 'EKF2_BARO_CTRL', value: {integer: 0, real: 0.0}}"
if [ $? -eq 0 ]; then
    echo "  ✓ EKF2_BARO_CTRL 设置成功"
else
    echo "  ✗ EKF2_BARO_CTRL 设置失败"
fi

# 设置 EKF2_HGT_REF (Range sensor)
echo "设置 EKF2_HGT_REF = Range sensor..."
rosservice call /mavros/param/set "{param_id: 'EKF2_HGT_REF', value: {integer: 2, real: 0.0}}"
if [ $? -eq 0 ]; then
    echo "  ✓ EKF2_HGT_REF 设置成功"
else
    echo "  ✗ EKF2_HGT_REF 设置失败"
fi

# 设置 SYS_HAS_BARO (Disabled)
echo "设置 SYS_HAS_BARO = Disabled..."
rosservice call /mavros/param/set "{param_id: 'SYS_HAS_BARO', value: {integer: 0, real: 0.0}}"
if [ $? -eq 0 ]; then
    echo "  ✓ SYS_HAS_BARO 设置成功"
else
    echo "  ✗ SYS_HAS_BARO 设置失败"
fi

# 设置 EKF2_RNG_CTRL (Enabled)
echo "设置 EKF2_RNG_CTRL = Enabled..."
rosservice call /mavros/param/set "{param_id: 'EKF2_RNG_CTRL', value: {integer: 2, real: 0.0}}"
if [ $? -eq 0 ]; then
    echo "  ✓ EKF2_RNG_CTRL 设置成功"
else
    echo "  ✗ EKF2_RNG_CTRL 设置失败"
fi

# 设置 EKF2_OF_CTRL (Enabled)
echo "设置 EKF2_OF_CTRL = Enabled..."
rosservice call /mavros/param/set "{param_id: 'EKF2_OF_CTRL', value: {integer: 1, real: 0.0}}"
if [ $? -eq 0 ]; then
    echo "  ✓ EKF2_OF_CTRL 设置成功"
else
    echo "  ✗ EKF2_OF_CTRL 设置失败"
fi

# 重启飞控
echo "重启飞控..."
rosservice call /mavros/cmd/command "{command: 246, confirmation: 0, param1: 1.0, param2: 0.0, param3: 0.0, param4: 0.0, param5: 0.0, param6: 0.0, param7: 0.0}"
if [ $? -eq 0 ]; then
    echo "  ✓ 飞控重启成功"
else
    echo "  ✗ 飞控重启失败"
fi

echo "参数设置完成！"
