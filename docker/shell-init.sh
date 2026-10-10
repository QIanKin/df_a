# Sourced by both interactive shells; ROS only, project overlay is manual.
if [ -n "${ZSH_VERSION:-}" ]; then
    source /opt/ros/noetic/setup.zsh
else
    source /opt/ros/noetic/setup.bash
fi
export PATH="/opt/df-a/bin:$PATH"
# catkin's setup scripts reorder PATH. Keep these defaults after sourcing devel.
catkin_make() {
    /opt/df-a/bin/catkin_make "$@"
}
