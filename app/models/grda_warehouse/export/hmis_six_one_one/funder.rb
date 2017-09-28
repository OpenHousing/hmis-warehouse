module GrdaWarehouse::Export::HMISSixOneOne
  class Funder < GrdaWarehouse::Hud::Funder
    include ::Export::HMISSixOneOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :FunderID,
        :ProjectID,
        :Funder,
        :GrantID,
        :StartDate,
        :EndDate,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :FunderID

    def self.file_name
      'Funder.csv'
    end
    
  end
end