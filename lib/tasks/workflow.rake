namespace :eozkill do
  namespace :workflow do
    desc "fetch loss today"
    task :fetch_today => :environment do |task, args|
      s = Time.zone.now.strftime("%Y%m%d")
      ElasticZkill.new.fetch_by_day_main(s)
    end
    desc "fetch loss yesterday"
    task :fetch_yesterday => :environment do |task, args|
      s = (Time.zone.now.to_date -1).strftime("%Y%m%d")
      ElasticZkill.new.fetch_by_day_main(s)
    end

    desc "fetch loss span"
    task :fetch_span, ['start_d', 'end_d'] => :environment do |task, args|
      s = args[:start_d]
      e = args[:end_d]
      date_from = DateTime.parse(s)
      date_to = DateTime.parse(e)

      (date_from..date_to).each do |target_date|
        puts 'date:' + target_date.to_s
        ElasticZkill.new.fetch_by_day_main(s)
      end
    end

    desc "create_today_indexer"
    task :create_today_index => :environment do |task, args|
      s = Time.zone.now.to_date.strftime("%Y%m%d")
      begin
        ElasticZkill.new.delete_index(s)
      rescue Exception
        puts "delete index error" + s.to_s
      end
      ElasticZkill.new.create_index(s)
      ElasticZkill.new.put_mapping(s)
    end

  end
end
