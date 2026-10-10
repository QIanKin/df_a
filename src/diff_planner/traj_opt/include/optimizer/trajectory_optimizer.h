#pragma once

#include "optimizer/mocha3d_optimizer.h"
#include <stdexcept>
#include <string>

namespace diff_planner
{
// Select once at node startup. All operations belong to that same optimizer,
// including constraint generation and rebound state. There is no fallback.
class TrajectoryOptimizer
{
public:
  using Ptr = std::unique_ptr<TrajectoryOptimizer>;
  using CHK_RET = PolyTrajOptimizer::CHK_RET;

  explicit TrajectoryOptimizer(const std::string &name) : name_(name)
  {
    if (name == "minco")
      minco_.reset(new PolyTrajOptimizer);
    else if (name == "mocha")
      mocha_.reset(new Mocha3DOptimizer);
    else
      throw std::invalid_argument("Unknown manager/trajectory_optimizer '" + name +
                                  "'; expected 'minco' or 'mocha'.");
  }

  const std::string &name() const { return name_; }
  void setParam(ros::NodeHandle &nh)
  { if (mocha_) mocha_->setParam(nh); else minco_->setParam(nh); }
  void setEnvironment(const GridMap::Ptr &map)
  { if (mocha_) mocha_->setEnvironment(map); else minco_->setEnvironment(map); }
  void setSwarmTrajs(SwarmTrajData *trajs)
  { if (mocha_) mocha_->setSwarmTrajs(trajs); else minco_->setSwarmTrajs(trajs); }
  void setDroneId(int id)
  { if (mocha_) mocha_->setDroneId(id); else minco_->setDroneId(id); }
  void setIfTouchGoal(bool touch_goal)
  { if (mocha_) mocha_->setIfTouchGoal(touch_goal); else minco_->setIfTouchGoal(touch_goal); }
  void setConstraintPoints(const ConstraintPoints &points)
  { if (mocha_) mocha_->setConstraintPoints(points); else minco_->setConstraintPoints(points); }
  void setUseMultitopologyTrajs(bool enabled)
  { if (mocha_) mocha_->setUseMultitopologyTrajs(enabled); else minco_->setUseMultitopologyTrajs(enabled); }

  int get_cps_num_prePiece_()
  { return mocha_ ? mocha_->get_cps_num_prePiece_() : minco_->get_cps_num_prePiece_(); }
  double get_swarm_clearance_()
  { return mocha_ ? mocha_->get_swarm_clearance_() : minco_->get_swarm_clearance_(); }
  const ConstraintPoints &getControlPoints()
  { return mocha_ ? mocha_->getControlPoints() : minco_->getControlPoints(); }
  const poly_traj::MinJerkOpt &getMinJerkOpt()
  { return mocha_ ? mocha_->getMinJerkOpt() : minco_->getMinJerkOpt(); }

  CHK_RET finelyCheckAndSetConstraintPoints(std::vector<std::pair<int, int>> &segments,
                                            const poly_traj::MinJerkOpt &initial, bool first)
  {
    return mocha_ ? mocha_->finelyCheckAndSetConstraintPoints(segments, initial, first)
                  : minco_->finelyCheckAndSetConstraintPoints(segments, initial, first);
  }
  std::vector<ConstraintPoints> distinctiveTrajs(std::vector<std::pair<int, int>> segments)
  { return mocha_ ? mocha_->distinctiveTrajs(segments) : minco_->distinctiveTrajs(segments); }
  bool optimizeTrajectory(const Eigen::MatrixXd &start, const Eigen::MatrixXd &end,
                          const Eigen::MatrixXd &points, const Eigen::VectorXd &times,
                          double &cost)
  {
    return mocha_ ? mocha_->optimizeTrajectory(start, end, points, times, cost)
                  : minco_->optimizeTrajectory(start, end, points, times, cost);
  }
  bool computePointsToCheck(poly_traj::Trajectory &traj, int end, PtsChk_t &points)
  { return mocha_ ? mocha_->computePointsToCheck(traj, end, points)
                  : minco_->computePointsToCheck(traj, end, points); }

private:
  const std::string name_;
  PolyTrajOptimizer::Ptr minco_;
  Mocha3DOptimizer::Ptr mocha_;
};
} // namespace diff_planner
