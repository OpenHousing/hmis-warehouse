module GrdaWarehouse::HMIS
  class Assessment < Base
    dub 'assessments'

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name, foreign_key: :data_source_id, primary_key: GrdaWarehouse::DataSource.primary_key
    
    def self.update_touch_points
      touch_points = fetch_touch_points()
      assessments = fetch_assessments()
      add_missing(touch_points: touch_points, assessments: assessments)
      deactivate_inactive(touch_points: touch_points, assessments: assessments)
    end

    def self.add_missing touch_points:, assessments:
      touch_points.each do |key, tp|
        next if assessments[key] == tp
        assessment = self.where(
          data_source_id: key[:data_source_id],
          site_id: key[:site_id],
          assessment_id: key[:assessment_id]
        ).first_or_create do |assessment|
          assessment.name = tp[:name]
          assessment.active = tp[:active]
        end
        assessment.name = tp[:name]
        assessment.active = tp[:active]
        assessment.site_name = tp[:site_name]
        assessment.last_fetched_at = Time.now
        assessment.save
      end
    end

    def self.deactivate_inactive touch_points:, assessments:
      missing = assessments.keys - touch_points.keys
      missing.each do |key|
        all.where(key).update_all(active: false)
      end
    end

    def self.fetch_assessments
      all.pluck(:data_source_id, :site_id, :assessment_id, :name, :active).
        map do |data_source_id, site_id, assessment_id, name, active|
          [
            {
              data_source_id: data_source_id, 
              site_id: site_id, 
              assessment_id: assessment_id
            }, 
            {
              name: name,
              active: active,
            }
          ]
        end.to_h
    end

    def self.fetch_touch_points
      api_config = YAML.load_file('config/eto_api.yml')
      touch_points = {}
      api_config.each do |connection_key, config|
        data_source_id = config['data_source_id']
        api = EtoApi::Base.new(api_connection: connection_key)
        api.connect
        api.sites.each do |site_id, name|
          api.touch_points(site_id: site_id).each do |touch_point|
            touch_point = touch_point.with_indifferent_access
            touch_points[
              {
                data_source_id: data_source_id, 
                site_id: site_id, 
                assessment_id: touch_point[:TouchPointID]
              }
            ] = {
              name: touch_point[:TouchPointName],
              site_name: name,
              active: ! touch_point[:IsDisabled],
            }
          end
        end
      end
      return touch_points
    end
  end
end