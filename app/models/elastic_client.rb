class ElasticClient
  include ActiveModel::Model

  @client = nil

  def initialize
    @client = Elasticsearch::Client.new({log: false, hosts: {host: Settings.applications.es_server}})
  end

  def health_check
    @client.cluster.health
  end

  def all_index
    @client.cat.indices
  end

  def create_index(name)
    @client.indices.create(index: name)
  end

  def create_index2(name, shard)
    @client.indices.create(index: name, body: {settings: { index: { number_of_shards: 2}}})
  end

  def create_document(index_name, id, body)
    @client.create({ index: index_name, type: 'info', id: id, body: body })
  end

  def search(index_name, query: '*')
    @client.search(index: index_name, q: query)
  end

  def put_mapping(index_name, type, body)
    @client.indices.put_mapping index: index_name, type: type, body: body
  end

  def delete(index_name)
    @client.indices.delete index: index_name
  end
end
