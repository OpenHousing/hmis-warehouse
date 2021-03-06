# a view into destination clients
module GrdaWarehouse::Report
  class Client < Base
    self.table_name = :report_clients

    many :demographics   # these are source clients
    many :enrollments
    many :exits
    many :services
    many :health_and_dvs
    many :disabilities
    many :income_benefits
    many :employment_educations
  end
end