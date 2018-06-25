module ReportGenerators::SystemPerformance::Fy2016
  class MeasureSeven < Base
    LOOKBACK_STOP_DATE = '2012-10-01'

    # PH = [3,9,10,13]
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)
    # TH = [2]
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    # ES = [1]
    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    # SH = [8]
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)
    # SO = [4]
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)

    RRH = [13]
    PH_PSH = [3,9,10] # All PH except 13, Measure 7 doesn't count RRH

    def run!
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end

   private
    def calculate
      if start_report(Reports::SystemPerformance::Fy2016::MeasureSeven.first)
        set_report_start_and_end()
        Rails.logger.info "Starting report #{@report.report.name}"
        # Overview: 
        # 7a.1 Success of placement from Street Outreach (SO) at finding permanent housing
        # 7b.1 Success of placement from ES, SH, TH and PH-Rapid-Re-Housing at finding permanent housing
        # 7b.2 Success of PH (except Rapid Re-Housing) at finding permanent housing
        @answers = setup_questions()
        @support = @answers.deep_dup

        # Relevant Project Types/Program Types
        # 1: Emergency Shelter (ES)
        # 2: Transitional Housing (TH)
        # 3: Permanent Supportive Housing (disability required for entry) (PH)
        # 4: Street Outreach (SO)
        # 6: Services Only
        # 7: Other
        # 8: Safe Haven (SH)
        # 9: Permanent Housing (Housing Only) (PH)
        # 10: Permanent Housing (Housing with Services - no disability required for entry) (PH)
        # 11: Day Shelter
        # 12: Homeless Prevention
        # 13: Rapid Re-Housing (PH)
        # 14: Coordinated Assessment
        
        calculate_7a_1()
        update_report_progress(percent: 33)
        calculate_7b_1()
        update_report_progress(percent: 66)
        calculate_7b_2()
        Rails.logger.info @answers
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
      
    end

    def calculate_7a_1
      # Select clients who have a recorded stay in an SO during the report period
      # who also don't have an ongoing enrollment at an SO on the final day of the report 
      # eg. Those who were counted by SO, but exited to somewhere else
      
      client_id_scope = GrdaWarehouse::ServiceHistory.entry.
          ongoing(on_date: @report.options['report_end']).
          hud_project_type(SO)

      client_id_scope = add_filters(scope: client_id_scope)

      universe_scope = GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: @report.options['report_start'], 
          end_date: @report.options['report_end'].to_date + 1.day).
        hud_project_type(SO).
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )
      
      universe_scope = add_filters(scope: universe_scope)

      universe = universe_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)

      destinations = {}
      universe.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistory.exit.
          ended_between(start_date: @report.options['report_start'], 
          end_date: @report.options['report_end'].to_date + 1.day).
          hud_project_type(SO).
          where(client_id: id)
        
        destination_scope = add_filters(scope: destination_scope)

        destinations[id] = destination_scope.
          order(date: :desc).
          limit(1).
          pluck(:destination).first
      end
      remaining_leavers = destinations.reject{ |id, destination| [6, 29, 24].include?(destination.to_i)}
      @answers[:sevena1_c2][:value] = remaining_leavers.size
      @support[:sevena1_c2][:support] = {
        headers: ['Client ID', 'Destination'],
        counts: remaining_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      temporary_leavers = destinations.select{ |id, destination| [1, 15, 14, 27, 4, 12, 13, 5, 2, 25].include?(destination.to_i)}
      @answers[:sevena1_c3][:value] = temporary_leavers.size
      @support[:sevena1_c3][:support] = {
        headers: ['Client ID', 'Destination'],
        counts: temporary_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      permanent_leavers = destinations.select{ |id, destination| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(destination.to_i)}
      @answers[:sevena1_c4][:value] = permanent_leavers.size
      @support[:sevena1_c4][:support] = {
        headers: ['Client ID', 'Destination'],
        counts: permanent_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      @answers[:sevena1_c5][:value] = (((@answers[:sevena1_c3][:value].to_f + @answers[:sevena1_c4][:value].to_f) / @answers[:sevena1_c2][:value]) * 100).round(2)
  
      return @answers
    end

    def calculate_7b_1
      # Select clients who have a recorded stay in ES, SH, TH and PH-RRH during the report period
      # who also don't have a "bed-night" at an ES, SH, TH and PH-RRH on the final day of the report 
      # eg. Those who were counted by ES, SH, TH and PH-RRH, but exited to somewhere else
      
      client_id_scope = GrdaWarehouse::ServiceHistory.entry.
          ongoing(on_date: @report.options['report_end']).
          hud_project_type(SH + TH + RRH)

      client_id_scope = add_filters(scope: client_id_scope)

      universe_scope = GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: @report.options['report_start'], 
          end_date: @report.options['report_end'].to_date + 1.day).
        hud_project_type(SH + TH + RRH).
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )

      universe_scope = add_filters(scope: universe_scope)

      universe = universe_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)
      
      destinations = {}
      universe.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistory.exit.
          ended_between(start_date: @report.options['report_start'], 
          end_date: @report.options['report_end'].to_date + 1.day).
          hud_project_type(SH + TH + RRH).
          where(client_id: id)

        destination_scope = add_filters(scope: destination_scope)

        destinations[id] = destination_scope.
          order(date: :desc).
          limit(1).
          pluck(:destination).first
      end
      remaining_leavers = destinations.reject{ |id, destination| [15, 6,25,24].include?(destination.to_i)}
      @answers[:sevenb1_c2][:value] = remaining_leavers.size
      @support[:sevenb1_c2][:support] = {
        headers: ['Client ID', 'Destination'],
        counts: remaining_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      permanent_leavers = destinations.select{ |id, destination| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(destination.to_i)}
      @answers[:sevenb1_c3][:value] = permanent_leavers.size
      @support[:sevenb1_c3][:support] = {
        headers: ['Client ID', 'Destination'],
        counts: permanent_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      @answers[:sevenb1_c4][:value] = ((@answers[:sevenb1_c3][:value].to_f / @answers[:sevenb1_c2][:value]) * 100).round(2)
      return @answers
    end

    def calculate_7b_2
      # Select clients who have a recorded stay in PH but not PH-RRH during the report period
      # who also don't have an ongoing enrollment at a PH but not PH-RRH on the final day of the report 
      # eg. Those who were counted by PH but not PH-RRH, but exited to somewhere else
      
      client_id_scope = GrdaWarehouse::ServiceHistory.entry.
          ongoing(on_date: @report.options['report_end']).
          hud_project_type(PH_PSH)

      client_id_scope = add_filters(scope: client_id_scope)

      leavers_scope = GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: @report.options['report_start'], 
        end_date: @report.options['report_end'].to_date + 1.day).
        hud_project_type(PH_PSH).
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )

      leavers_scope = add_filters(scope: leavers_scope)

      leavers = leavers_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)
      
      stayers_scope = GrdaWarehouse::ServiceHistory.entry.
        ongoing(on_date: @report.options['report_end']).
        hud_project_type(PH_PSH)

      stayers_scope = add_filters(scope: stayers_scope)

      stayers = stayers_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)
      
      destinations = {}
      leavers.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistory.exit.
          ended_between(start_date: @report.options['report_start'], 
          end_date: @report.options['report_end'].to_date + 1.day).
          hud_project_type(PH).
          where(client_id: id)

        destination_scope = add_filters(scope: destination_scope)

        destinations[id] = destination_scope.
          order(date: :desc).
          limit(1).
          pluck(:destination).first
      end
      remaining_leavers = destinations.reject{ |id, destination| [15, 6, 25, 24].include?(destination.to_i)}
      @answers[:sevenb2_c2][:value] = remaining_leavers.size + stayers.size
      @support[:sevenb2_c2][:support] = {
        headers: ['Client ID', 'Destination'],
        counts: remaining_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      permanent_leavers = destinations.select{ |id, destination| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(destination.to_i)}
      @answers[:sevenb2_c3][:value] = permanent_leavers.size + stayers.size
      @support[:sevenb2_c3][:support] = {
        headers: ['Client ID', 'Destination'],
        counts: permanent_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      @answers[:sevenb2_c4][:value] = ((@answers[:sevenb2_c3][:value].to_f / @answers[:sevenb2_c2][:value]) * 100).round(2)
      return @answers
    end

    def setup_questions
      {
        sevena1_a2: {
          title: nil,
          value: 'Universe: Persons who exit Street Outreach',
        },
        sevena1_a3: {
          title: nil,
          value: 'Of persons above, those who exited to temporary & some institutional destinations',
        },
        sevena1_a4: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent housing destinations',
        },
        sevena1_a5: {
          title: nil,
          value: '% Successful exits',
        },
        sevena1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevena1_b2: {
          title: 'Universe: Persons who exit Street Outreach (previous FY)',
          value: nil,
        },
        sevena1_b3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (previous FY)',
          value: nil,
        },
        sevena1_b4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevena1_b5: {
          title: '% Successful exits (previous FY)',
          value: nil,
        },
        sevena1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevena1_c2: {
          title: 'Universe: Persons who exit Street Outreach (current FY)',
          value: 0,
        },
        sevena1_c3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (current FY)',
          value: 0,
        },
        sevena1_c4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevena1_c5: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
        sevena1_d1: {
          title: nil,
          value: '% Difference',
        },
        sevena1_d2: {
          title: 'Universe: Persons who exit Street Outreach (% difference)',
          value: nil,
        },
        sevena1_d3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (% difference)',
          value: nil,
        },
        sevena1_d4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevena1_d5: {
          title: '% Successful exits (% difference)',
          value: nil,
        },
        sevenb1_a2: {
          title: nil,
          value: 'Universe: Persons in ES, SH, TH and PH-RRH who exited',
        },
        sevenb1_a3: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent housing destinations',
        },
        sevenb1_a4: {
          title: nil,
          value: '% Successful exits',
        },
        sevenb1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevenb1_b2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (previous FY)',
          value: nil,
        },
        sevenb1_b3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevenb1_b4: {
          title: '% Successful exits (previous FY)',
          value: nil,
        },
        sevenb1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevenb1_c2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (current FY)',
          value: 0,
        },
        sevenb1_c3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb1_c4: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
        sevenb1_d1: {
          title: nil,
          value: '% Difference',
        },
        sevenb1_d2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (% difference)',
          value: nil,
        },
        sevenb1_d3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevenb1_d4: {
          title: '% Successful exits (% difference)',
          value: nil,
        },
        sevenb2_a2: {
          title: nil,
          value: 'Universe: Persons in all PH projects except PH-RRH',
        },
        sevenb2_a3: {
          title: nil,
          value: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations',
        },
        sevenb2_a4: {
          title: nil,
          value: '% Successful exits/retentions',
        },
        sevenb2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevenb2_b2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (previous FY)',
          value: nil,
        },
        sevenb2_b3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevenb2_b4: {
          title: '% Successful exits/retentions (previous FY)',
          value: nil,
        },
        sevenb2_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevenb2_c2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (current FY)',
          value: 0,
        },
        sevenb2_c3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb2_c4: {
          title: '% Successful exits/retentions (current FY)',
          value: 0,
        },
        sevenb2_d1: {
          title: nil,
          value: '% Difference',
        },
        sevenb2_d2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (% difference)',
          value: nil,
        },
        sevenb2_d3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevenb2_d4: {
          title: '% Successful exits/retentions (% difference)',
          value: nil,
        },
      }
    end
  end
end
