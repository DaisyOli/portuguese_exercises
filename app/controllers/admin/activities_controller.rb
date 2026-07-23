module Admin
  class ActivitiesController < BaseController
    MIN_RATINGS   = 3
    RESULTS_LIMIT = 10

    def index
      scope = Activity.joins(:activity_ratings)
                       .group("activities.id")
                       .having("COUNT(activity_ratings.id) >= ?", MIN_RATINGS)
                       .select("activities.*, AVG(activity_ratings.stars) AS stars_avg, COUNT(activity_ratings.id) AS stars_count")
                       .includes(:teacher)

      @best  = scope.order("stars_avg DESC, stars_count DESC").limit(RESULTS_LIMIT)
      @worst = scope.order("stars_avg ASC, stars_count DESC").limit(RESULTS_LIMIT)
    end
  end
end
