# Standalone build: no pre-existing local image or robot SDK is required.
FROM osrf/ros:noetic-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git ca-certificates zsh \
    libeigen3-dev libarmadillo-dev libyaml-cpp-dev qtdeclarative5-dev \
    ros-noetic-pcl-ros ros-noetic-cv-bridge ros-noetic-cmake-modules \
    ros-noetic-mavros-msgs ros-noetic-eigen-conversions \
    libgl1-mesa-dri libgl1-mesa-glx mesa-utils x11-utils xauth \
    && rm -rf /var/lib/apt/lists/*

# Match the host developer, so edits made in the container retain host ownership.
ARG DEV_UID=1000
ARG DEV_GID=1000
RUN groupadd --gid ${DEV_GID} developer \
    && useradd --uid ${DEV_UID} --gid ${DEV_GID} --create-home --shell /bin/zsh developer \
    && mkdir -p /Diff-Planner/build /Diff-Planner/devel /Diff-Planner/install \
    && chown -R developer:developer /Diff-Planner
COPY catkin_make /opt/df-a/bin/catkin_make
COPY shell-init.sh /opt/df-a/shell-init.sh
RUN chmod 755 /opt/df-a/bin/catkin_make \
    && printf '\nsource /opt/df-a/shell-init.sh\n' >> /home/developer/.bashrc \
    && printf 'source /opt/df-a/shell-init.sh\n' >> /home/developer/.zshrc \
    && chown developer:developer /home/developer/.bashrc /home/developer/.zshrc

ENV QT_X11_NO_MITSHM=1 LIBGL_ALWAYS_SOFTWARE=1 ROS_MASTER_URI=http://localhost:11311
USER developer
# The documented first command, `cd Diff-Planner`, works from here.
WORKDIR /
CMD ["sleep", "infinity"]
